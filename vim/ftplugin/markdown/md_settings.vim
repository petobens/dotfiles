" Initialization {{{

if exists('b:loaded_md_settings_file')
    finish
endif
let b:loaded_md_settings_file = 1

" }}}
" Helpers {{{

" Define OS variable
let s:is_win = has('win32') || has('win64')
let s:is_mac = !s:is_win && (has('mac') || has('macunix') || has('gui_macvim')
            \ || system('uname') =~? '^darwin')
let s:is_linux = !s:is_win && !s:is_mac

" }}}
" Options {{{

" Spell checking
" setlocal spell

" }}}
" Compile preview {{{

function! s:PandocConversion(extension)
    " TODO: Add pandoc options? "
    if !executable('pandoc')
        echoerr 'Pandoc is not installed or not in your path.'
        return
    endif

    let l:save_pwd = getcwd()
    lcd %:p:h

    silent update!
    let mdfile = fnameescape(expand('%:p'))
    let new_file = fnamemodify(fnameescape(expand('%:p')), ':r') .
                \ '.' . a:extension
    " We need backslashes (at least in Windows)
    if s:is_win
        let mdfile = substitute(mdfile, '/', '\\', '')
    endif
    echo 'converting markdown to ' . a:extension .  ' with Pandoc...'
    let shell_output = system('pandoc ' . mdfile . ' -o ' . new_file)
    if !empty(shell_output)
        echohl Error
        echo shell_output
        echohl none
    else
        echo 'conversion was succesful.'
        " When using Mac and Skim update the pdf file after compilation
        if s:is_mac && executable('displayline')
            call system('displayline -r -g ' . line('.') . ' ' . new_file)
        endif
    endif
    execute 'lcd ' . save_pwd
endfunction

function! s:DeletePreviewFiles()
    " If the extensions to be deleted are wildignored they won't be recognised
    " by globpath function. Thus we first save and empty the wildignore setting
    let old_wig = &wildignore
    set wildignore=
    let extensions = 'pdf,html'
    let path = fnamemodify(fnameescape(expand('%:p')), ':h')
    let base_name = fnamemodify(fnameescape(expand('%:p')), ':t:r')
    let file_list = globpath(path, base_name . '*.{' . extensions . '}', 0, 1)
    let nr_filetypes = len(file_list)
    if nr_filetypes < 1
        echo 'No preview files are readable.'
        return
    endif
    if confirm('Really delete ' . nr_filetypes . ' preview file(s)?',
                \ "&Yes\n&No") == 1
        for item in file_list
            if exists(':VimProcBang') && s:is_win
                call vimproc#delete_trash(item)
            else
                execute delete(item)
            endif
        endfor
        redraw!
        echo nr_filetypes 'preview file(s) deleted.'
    endif
    let &wildignore = old_wig
endfunction

" }}}
" Viewing {{{

function! s:ViewPreview(extension)
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h

    let preview_file = fnamemodify(fnameescape(expand('%:p')), ':r') . '.'
                \ . a:extension
    " Check the pdf or html file exists
    if !filereadable(preview_file)
        echohl Error
        echo  preview_file . ' not found.'
        echohl none
        return
    endif

    let bang_command = '! '
    if exists(':Dispatch')
        let bang_command = 'Start! '
    endif

    " Try to open it
    if s:is_win
        if a:extension ==# 'pdf'
            if !executable('SumatraPDF')
                echoerr 'SumatraPDF is not installed or not in your path.'
                return
            endif
            let execstr = 'silent! !start SumatraPDF -reuse-instance '.
                        \ preview_file
        else
            let execstr = 'silent! ! start ' . preview_file
        endif
    elseif s:is_mac
        let open_cmd = 'open '
        execute 'silent! !' . open_cmd . '-a Skim ' . preview_file
        " We need to redraw screen here!
        redraw!
    else
        if !executable('zathura')
            echoerr 'zathura is not installed or not in your path.'
            return
        endif
            execute 'silent! ' . bang_command . 'zathura ' . preview_file
    endif

    " Restore previous working directory
    execute 'lcd ' . save_pwd
endfunction

" }}}
" Miscellaneous {{{

" Toggle check item {{{

function! s:ToggleCheckList()
    let save_cursor = getcurpos()
    let curr_line = getline('.')
    let curr_line_nr = line('.')
    let state = matchstr(curr_line, '^\s*\W\s\[\zs.*]\ze')
    echo state
    if state ==# 'x]'
        call setline(curr_line_nr, substitute(curr_line, 'x]', ']', ''))
    elseif state ==# ']'
        call setline(curr_line_nr, substitute(curr_line, ']', 'x]', ''))
    endif
    call setpos('.', save_cursor)
endfunction

" }}}

" }}}
" Mappings {{{

" Anon snippets
if exists(':UltiSnipsEdit') != 0
    inoremap <buffer> <silent> `` ``<C-R>=UltiSnips#Anon('\`${1:${VISUAL}}\`$0',
                \ '``', '', 'i')<cr>
endif

" Compiling
nnoremap <buffer> <silent> <F7> :call <SID>PandocConversion('pdf')<CR>
inoremap <buffer> <silent> <F7> <ESC>:call <SID>PandocConversion('pdf')<CR>
nnoremap <buffer> <silent> <F9> :call <SID>PandocConversion('html')<CR>
inoremap <buffer> <silent> <F9> <ESC>:call <SID>PandocConversion('html')<CR>

" Viewing
nnoremap <buffer> <silent> <Leader>vp :call <SID>ViewPreview('pdf')<CR>
nnoremap <buffer> <silent> <Leader>vh :call <SID>ViewPreview('html')<CR>
nnoremap <buffer> <silent> <Leader>dp :call <SID>DeletePreviewFiles()<CR>

" Miscellaneous
nnoremap <buffer> <silent> <Leader>cl :call <SID>ToggleCheckList()<CR>

" }}}
