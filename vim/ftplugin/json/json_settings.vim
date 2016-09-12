"===============================================================================
"          File: json_settings.vim
"        Author: Pedro Ferrari
"       Created: 27 Aug 2016
" Last Modified: 27 Aug 2016
"   Description: My Json settings
"===============================================================================
" Installation notes {{{

" To use the linter we need to install jsonlint (install it with npm).

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_json_settings_file')
    finish
endif
let b:my_json_settings_file = 1

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
" Linting {{{

function! s:RunJsonLint()
    " Don't run jsonlint if it is not installed
    if !executable('jsonlint')
        echoerr 'jsonlint is not installed or not in your path.'
        return
    endif
    " Don't run jsonlint if there is only one empty line or we are in a Gdiff
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
    let compiler = 'jsonlint --compact '
    let &l:makeprg = compiler . current_file
    " Set error format
    let old_efm = &l:efm
    let &l:efm = '%ELine %l:%c,'.
        \ '%Z\\s%#Reason: %m,'.
        \ '%C%.%#,'.
        \ '%f: line %l\, col %c\, %m,'.
        \ '%-G%.%#'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchall because Dispatch removes it
        let &l:efm = &efm . ',%-G%.%#'
        echon 'running jsonlint with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running jsonlint ...'
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
            echon 'Finished jsonlint successfully.'
        endif
    endif

    " Restore error format and working directory
    let &l:efm = old_efm
    execute 'lcd ' . l:save_pwd
endfunction

function! s:RunJsonFormat(...)
    " Only call this function after a jsonlint run
    if split(&makeprg, '')[0] !=# 'jsonlint'
        return
    endif

    " Get current qflist and exit if there are errors
    let qflist = getqflist()
    if !empty(qflist)
        return
    endif

    " Save working directory and get current file
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Set the format program
    let old_formatprg = &l:formatprg
    let &l:formatprg = 'jsonlint --pretty-print ' . current_file
    if a:0 && a:1 ==# 'visual'
        execute 'normal! gvgq'
    else
        let save_cursor = getcurpos()
        execute 'silent! normal! gggqG'
        call setpos('.', save_cursor)
    endif
    silent noautocmd update
    let &l:formatprg = old_formatprg
    execute 'lcd ' . l:save_pwd
endfunction

" Automatically run jsonformatter and jsonlint on save (note we need to run
" first the linter because if there are errors the jsontool formatter will paste
" those  errors on top of the json file)
augroup json_linting
    au!
    au BufWritePost *.json call s:RunJsonLint()
    au QuickFixCmdPost {make,cgetfile} call s:RunJsonFormat()
augroup END

" }}}
" Mappings {{{

" Linting (and autoformatting)
nnoremap <buffer> <Leader>rl :call <SID>RunJsonLint()<CR>
nnoremap <buffer> <Leader>af :call <SID>RunJsonFormat()<CR>

" }}}
