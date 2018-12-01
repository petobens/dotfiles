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

augroup sql_linting
    au!
    " Only run linter on save
    au BufWritePost *.{sql,pgsql,mysql} silent Neomake
augroup END

" }}}
" Mappings {{{

" Linter and formatting
nnoremap <buffer> <Leader>rl :Neomake<CR>
nnoremap <buffer> <Leader>fq :call <SID>RunSqlFormat()<CR>

" }}}
