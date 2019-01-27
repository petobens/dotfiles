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
" Linting and formatting {{{

function! s:RunJsonFormat(...)
    " Don't run jsolint if it is not installed
    if !executable('jsonlint')
        echoerr 'jsonlint is not installed or not in your path.'
        return
    endif
    " Only run this function for json files
    if &filetype !=# 'json'
        return
    endif

    " Get current location list and exit if there are errors
    let qflist = getloclist(0)
    if !empty(qflist)
        return
    endif

    " Save working directory and get current file
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Set the format program
    let old_formatprg = &l:formatprg
    " Note: there is no config file for this
    let &l:formatprg = 'jsonlint --indent 4 --pretty-print ' . current_file
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

augroup json_linting
    au!
    au BufWritePost *.json call s:RunJsonFormat()
augroup END

" }}}
" Mappings {{{

nnoremap <silent> <buffer> <Leader>fc :call <SID>RunJsonFormat()<CR>

" }}}
