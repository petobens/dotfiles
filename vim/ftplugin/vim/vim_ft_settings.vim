"===============================================================================
"          File: vim_ft_settings.vim
"        Author: Pedro Ferrari
"       Created: 21 Aug 2015
" Last Modified: 03 Oct 2015
"   Description: My vim settings to work with vim filetype files
"===============================================================================
" Installation notes {{{

" To use the linter we need to install (via pip) the vim-vint module

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_vim_ft_settings_file')
    finish
endif
let b:my_vim_ft_settings_file = 1

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

function! s:RunVint()
    " Don't run vint if it is not installed
    if !executable('vint')
        echoerr 'vim-vint python module is not installed or not in your path.'
        return
    endif
    " Don't run vint if there is only one empty line or we are in a Gdiff
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
    let compiler = 'vint '
    let &l:makeprg = compiler . current_file
    " Set error format
    let old_efm = &l:efm
    let &l:efm = '%f:%l:%c: %m'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        echon 'running vint with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running vint ...'
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
            echon 'Finished vint successfully.'
        endif
    endif

    " Restore error format and working directory
    let &l:efm = old_efm
    execute 'lcd ' . l:save_pwd
endfunction

" Automatically run vint on save
augroup vim_linting
    au!
    au BufWritePost *.vim call s:RunVint()
augroup END

" }}}
" Mappings {{{

" Linting
nnoremap <buffer> <Leader>rl :call <SID>RunVint()<CR>

" }}}
