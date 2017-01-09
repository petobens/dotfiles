"===============================================================================
"          File: sql_settings.vim
"        Author: Pedro Ferrari
"       Created: 07 Mar 2016
" Last Modified: 09 Jan 2017
"   Description: My SQL settings
"===============================================================================
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_sql_settings_file')
    finish
endif
let b:my_sql_settings_file = 1

" }}}
" Helpers {{{

" Define OS variable
let s:is_win = has('win32') || has('win64')
let s:is_mac = !s:is_win && (has('mac') || has('macunix') || has('gui_macvim')
            \ || system('uname') =~? '^darwin')
let s:is_linux = !s:is_win && !s:is_mac

" Dispatch won't work with shellslash
function! s:NoShellSlash(command)
    let old_shellslash = &l:shellslash
    setlocal noshellslash
    execute 'silent ' a:command
    let &l:shellslash = old_shellslash
endfunction

" }}}
" Running queries {{{



" }}}
" Linter and formatting {{{

" We use sqllint and install it (on Mac) with `sudo gem install sqlint`
function! s:RunSqlLint()
    " Don't run sqlint if it is not installed
    if !executable('sqlint')
        echoerr 'sqlint is not installed or not in your path.'
        return
    endif
    " Don't run linter if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Update the file but ignore linting autocommand and close qf
    " window
    silent noautocmd update
    cclose

    " Save working directory and get current file
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Set compiler
    let compiler = 'sqlint '
    let &l:makeprg = compiler . current_file
    " Set error format
    let old_efm = &l:efm
    " TODO: remove the parenthesis at the end of the line
    let &l:efm =
        \ '%E%f:%l:%c:ERROR %m,' .
        \ '%W%f:%l:%c:WARNING %m,' .
        \ '%C %m'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        echon 'running sqlint with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running sqlint ...'
        silent make!
        " Open quickfix if there are valid errors or warnings
        if !empty(getqflist())
            copen
            wincmd J
            let height_gqf = len(getqflist())
            if height_gqf > 10
                let height_gqf = 10
            endif
            execute height_gqf . ' wincmd _'
            wincmd p  " Return to previous window
        else
            redraw!
            echon 'Finished sqlint successfully.'
        endif
    endif

    " Restore error format and working directory
    let &l:efm = old_efm
    execute 'lcd ' . l:save_pwd
endfunction

" We use sqlformat and install it (on Mac) with `pip install sqlparse`
function! s:RunSqlFormat(...)
    " Don't run sqlparse if it is not installed
    if !executable('sqlformat')
        echoerr 'sqlformat is not installed or not in your path.'
        return
    endif
    " Don't run sqlformat if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    let old_formatprg = &l:formatprg
    let &l:formatprg = 'sqlformat --reindent --use_space_around_operators ' .
                \ '--keywords upper --identifiers lower --indent_width 2 -'
    if a:0 && a:1 ==# 'visual'
        execute 'normal! gvgq'
    else
        let save_cursor = getcurpos()
        execute 'silent! normal! gggqG'
        call setpos('.', save_cursor)
    endif
    let &l:formatprg = old_formatprg
endfunction

" Automatically run pg_format and linter on save
augroup sql_linting
    au!
    " au BufWritePost *.sql call s:RunSqlFormat() | call s:RunSqlLint()
    " au BufWritePost *.sql call s:RunSqlFormat()
augroup END

" }}}
" Mappings {{{

" Linter and formatting
nnoremap <buffer> <Leader>rl :call <SID>RunSqlLint()<CR>
nnoremap <buffer> <Leader>fq :call <SID>RunSqlFormat()<CR>

" }}}
