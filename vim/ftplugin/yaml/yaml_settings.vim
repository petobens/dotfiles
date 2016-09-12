"===============================================================================
"          File: yaml_settings.vim
"        Author: Pedro Ferrari
"       Created: 27 Aug 2016
" Last Modified: 27 Aug 2016
"   Description: My YAML settings
"===============================================================================
" Installation notes {{{

" To use the linter we need to install yamllint (install it with pip).

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_yaml_settings_file')
    finish
endif
let b:my_yaml_settings_file = 1

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

function! s:RunYamlLint()
    " Don't run yamllint if it is not installed
    if !executable('yamllint')
        echoerr 'yamllint is not installed or not in your path.'
        return
    endif
    " Don't run yamllint if there is only one empty line or we are in a Gdiff
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
    let compiler = 'yamllint -f parsable '
    let &l:makeprg = compiler . current_file
    " Set error format
    let old_efm = &l:efm
    let &l:efm = '%f:%l:%c: [%trror] %m,%f:%l:%c: [%tarning] %m'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchall because Dispatch removes it
        " let &l:efm = &efm . ',%-G%.%#'
        echon 'running yamllint with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running yamllint ...'
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
            echon 'Finished yamllint successfully.'
        endif
    endif

    " Restore error format and working directory
    let &l:efm = old_efm
    execute 'lcd ' . l:save_pwd
endfunction

" Automatically run yamllint on save
augroup yaml_linting
    au!
    au BufWritePost *.yaml call s:RunYamlLint()
augroup END

" }}}
