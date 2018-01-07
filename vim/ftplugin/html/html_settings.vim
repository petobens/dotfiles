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

function! s:RunHtmlBeautify(...)
    " Don't run tidy if it is not installed
    if !executable('html-beautify')
        echoerr 'js-beautify is not installed or not in your path.'
        return
    endif
    " Don't run yapf if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif
    let old_formatprg = &l:formatprg
    let &l:formatprg = 'html-beautify --indent-size 2 --wrap-line-length 80 ' .
                \ '--no-preserve-newlines'
    let save_cursor = getcurpos()
    if a:0 && a:1 ==# 'visual'
        execute 'normal! gvgq'
    else
        execute 'silent! normal! gggqG'
    endif
    call setpos('.', save_cursor)
    let &l:formatprg = old_formatprg
endfunction

" Automatically run html-beautify formatter and htmlhint linter on save
augroup html_linting
    au!
    au BufWritePost *.html call s:RunHtmlBeautify() | silent noautocmd update |
                \ silent Neomake
augroup END

" }}}
