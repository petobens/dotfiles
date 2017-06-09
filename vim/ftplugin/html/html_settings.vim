"===============================================================================
"          File: html_settings.vim
"        Author: Pedro Ferrari
"       Created: 09 Jun 2017
" Last Modified: 09 Jun 2017
"   Description: My html settings
"===============================================================================
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_python_settings_file')
    finish
endif
let b:my_python_settings_file = 1

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
" Formatting {{{

function! s:RunTidy(...)
    " Don't run tidy if it is not installed
    if !executable('tidy')
        echoerr 'tidy is not installed or not in your path.'
        return
    endif
    " Don't run yapf if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Change shellredir to avoid inserting error output into the buffer (i.e
    " don't include stderr in output buffer)
    let shrd = &shellredir
    set shellredir=>%s
    let old_formatprg = &l:formatprg
    let &l:formatprg = "yapf --style='{based_on_style: pep8, " .
                \ "blank_line_before_nested_class_or_def: true}'"
    let save_cursor = getcurpos()
    if a:0 && a:1 ==# 'visual'
        execute 'normal! gvgq'
    else
        execute 'silent! normal! gggqG'
    endif
    if v:shell_error == 1
        silent undo
    endif
    call setpos('.', save_cursor)
    let &shellredir = shrd
    let &l:formatprg = old_formatprg
endfunction

" Automatically run tidy formatter and tidy linter on save
augroup html_linting
    au!
    au BufWritePost *.html call s:RunTidy() | silent noautocmd update |
                \ silent Neomake
augroup END

" }}}
