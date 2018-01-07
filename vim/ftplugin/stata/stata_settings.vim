" Installation notes {{{

" In order to compile we use rundo.exe and add it our path
" C:\prog-tools\rundo41

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_stata_settings_file')
    finish
endif
let b:my_stata_settings_file = 1

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
" Compiling {{{

function! s:RunStata(mode, ...)
    " Update the file but ignore any autocommand
    silent noautocmd update

    " Change directory
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Set compiler and file to run compiler
    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file with visual content
        let current_file = expand('%:t:r') . '_tmpvisual.do'
        let lines = getline(a:1, a:2)
        call writefile(lines, current_file)
    else
        let current_file = expand('%:p:t')
    endif

    " Set makeprg
    let compiler = 'rundo '
    let &l:makeprg = compiler . current_file

    " Set efm (don't catch any output)
    let old_efm = &l:efm
    setlocal efm=%-G%.%#

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchall because Dispatch removes it
        let &l:efm = &efm . ',%-G%.%#'
        echon 'running script with dispatch ...'
        " Make
        " FIXME: Stata steals focus
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
        " Restore error format and working directory and return
        " FIXME: If delete file then stata doesn't run; maybe use rundolines?
        " if a:mode == 'visual'
            " call delete(current_file)
        " endif
        let &l:efm = old_efm
        execute 'lcd ' . l:save_pwd
        return
    endif

    " Use regular make otherwise
    echon 'running script with make...'
    silent make!
    " Open quickfix if there are valid errors or warnings
    cwindow
    " Restore error format and return to previous working directory
    " if a:mode == 'visual'
        " call delete(current_file)
    " endif
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

" Define command to run visual selection
command! -range EvalVisualDo call s:RunStata('visual', <line1>, <line2>)

function! s:DeleteTempDo()
    let l:save_pwd = getcwd()
    lcd %:p:h
    let temp_file = expand('%:t:r') . '_tmpvisual.do'
    if filereadable(temp_file)
        if confirm('Really delete ' . temp_file .  '?', "&Yes\n&No") == 1
            call delete(temp_file)
            redraw!
            echo temp_file 'file was deleted.'
        endif
    else
        echo 'No temporary do file was found.'
    endif
    execute 'lcd ' . save_pwd
endfunction

" }}}
" Mappings {{{

nnoremap <silent> <buffer> <F7> :call <SID>RunStata('normal')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualDo<CR>
nnoremap <silent> <buffer> <Leader>dt :call <SID>DeleteTempDo()<CR>

" }}}
