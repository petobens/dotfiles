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

function! s:RunPrettier(...)
    " Don't run prettier if it is not installed
    if !executable('prettier')
        echoerr 'prettier is not installed or not in your path.'
        return
    endif
    " Don't run prettier if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Save working directory and get current file
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Change shellredir to avoid inserting error output into the buffer (i.e
    " don't include stderr in output buffer)
    let shrd = &shellredir
    set shellredir=>%s
    let old_formatprg = &l:formatprg
    let &l:formatprg = 'prettier '
                \ . '--config ' . expand($HOME . '/.prettierrc.yaml')
                \ . ' --stdin --stdin-filepath ' . current_file
    let save_cursor = getcurpos()
    if a:0 && a:1 ==# 'visual'
        execute 'silent! normal! gvgq'
    else
        execute 'silent! normal! gggqG'
    endif
    if v:shell_error != 0
        silent undo
    endif
    call setpos('.', save_cursor)
    let &shellredir = shrd
    let &l:formatprg = old_formatprg
    execute 'lcd ' . l:save_pwd
endfunction

" Automatically run prettier formatter and htmlhint linter on save
augroup html_linting
    au!
    au BufWritePost *.html call s:RunPrettier() | silent noautocmd update |
                \ silent Neomake
augroup END

" }}}
" Mappings {{{

nnoremap <silent> <buffer> <Leader>fc :call <SID>RunPrettier(()<CR>

" }}}
