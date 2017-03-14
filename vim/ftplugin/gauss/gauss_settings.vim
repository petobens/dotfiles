"===============================================================================
"          File: gauss_settings.vim
"        Author: Pedro Ferrari
"       Created: 04 Nov 2015
" Last Modified: 14 Mar 2017
"   Description: Gauss settings for Vim
"===============================================================================
" Installation notes {{{

" In Windows we create a symbolic link for gauss configuration file (gauss.cfg)
" from our dotfiles to the gauss executable directory.
" We then add our local program, library and dynamic files doing:
    " src_path = $(GAUSSDIR)\src;$(GAUSSDIR)\examples;
    " $(CLOUD)\programming\gauss\libraries\src
    " extra_lib_path = $(CLOUD)\programming\gauss\libraries\lib
    " dlib_path = $(CLOUD)\programming\gauss\libraries\dlib

" Note that most of the important libraries (nlsys, etc) can be copied from the
" Time Series course

" The 32-bit version of the dynamic libraries (PszTgSen, PsdTgSencan, etc) can
" be obtained from: https://sites.sas.upenn.edu/schorf/files/re.zip
" The `dforrt.dll` must be placed inside the root directory

" Note that we don't add a linter or function to query the documentation because
" there is no linter available (however Gauss is compiled to byte code before
" execution and thus many error are catched at that stage) and no command to
" print the docs to the console

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_gauss_settings_file')
  finish
endif
let b:my_gauss_settings_file = 1

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
" Options {{{

" When searching with gf include gauss files
setlocal suffixesadd=.gss,.prg,.g,.e,.src

" For matchit plugin
if exists('loaded_matchit')
    let s:conditional_end = '\([-+{\*\:(\/]\s*\)\@<!\<\(endif\|endo\|endp\|'.
                \ 'endfor\|endwind\)\>\(\s*[-+}\:\*\/)]\)\@!'
    let b:match_words = '\<\%(if\|\|for\|do while\|proc\|begwind' .
                \ '\|do until\)\>:\<\%(elseif\|goto\|break\|continue\|else\|' .
                \ 'nextwind\|catch\)\>:'. s:conditional_end
    unlet s:conditional_end
endif

" }}}
" Compiling {{{

function! s:RunGauss(mode, compilation, ...)
    " Check if gauss is installed
    if !executable('tgauss')
        echoerr 'gauss is not installed or not in your path.'
        return
    endif

    " Place uppercase marks at i) the beginning of visual selection and ii)
    " counting how many lines there are including files in order to compute
    " correct line numbers in the quickfix later
    silent! delmarks V I   " Delete previous marks
    if a:mode ==# 'visual' && a:0 >= 1 && strlen(a:1)
        let included_lines = s:GetIncluded(a:1)
        let nr_included_lines = len(included_lines)
        if nr_included_lines > 0
            " Only set a mark for included files if external files are indeed
            " included
            silent execute nr_included_lines . ' mark I'
        endif
        silent execute a:1 . ' mark V'
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update
    cclose
    " Change directory
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Set compiler and file to run compiler
    let compiler = 'tgauss -o -b '
    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file in the current directory with visual content (and
        " imported modules). Note that since gauss file can have multiple
        " extensions we need to provide the proper extension for the visual file
        let current_file_ext = expand('%:e')
        let current_file = expand('%:t:r') . '_tmpvisual.' . current_file_ext
        let visual_lines = getline(a:1, a:2)
        let lines = included_lines + visual_lines
        call writefile(lines, current_file)
    else
        let current_file = expand('%:p:t')
    endif

    " Use neovim terminal for foreground async compilation
    if a:compilation ==# 'foreground' && exists(':Topen')
        let old_size = g:neoterm_size
        let old_autoinsert = g:neoterm_autoinsert
        let g:neoterm_size = 10
        let g:neoterm_autoinsert = 0
        if a:mode ==# 'visual'
            execute 'T ' . compiler .  current_file . '; rm ' . current_file
        else
            execute 'T ' . compiler .  current_file
        endif
        " Avoid getting into insert mode using `au BufEnter * if &buftype ==
        " 'terminal' | startinsert | endif`
        stopinsert
        let g:neoterm_size = old_size
        let g:neoterm_autoinsert = old_autoinsert
        " Return to previous working directory and exit the function
        execute 'lcd ' . save_pwd
        return
    endif

    " We might want to do a foreground compilation in the regular os console
    if a:compilation ==# 'foreground_os'
        let bang_command = '!'
        let remove_visual_command = ''
        if exists(':Dispatch')
            let bang_command = 'Start -wait=always '
        endif
        if a:mode ==# 'visual'
            let remove_visual_command = '; rm ' . current_file
        endif
        execute bang_command . compiler . current_file . remove_visual_command
        execute 'lcd ' . save_pwd
        return
    endif

    " Set makeprg and error format when running make or Make (background
    " compilation)
    let &l:makeprg = compiler . current_file
    let old_efm = &l:efm
    " If a line does not completely match one of the entries in 'efm', the whole
    " line is put in the error message and the entry is marked 'not valid'.
    " Since Dispatch's `Make` calls `cwindow` and `cwindow` opens the quickfix
    " window only when there are valid errors then setting the efm to an
    " unmatchable line allows us to get all lines but decide ourselves when to
    " open the quickfix window (i.e after parsing the quickfix list content).
    " If we had used the catchall '%+G%.%#' then the quickfix would
    " automatically open once a build finishes since every line would be
    " considered a valid error.
    setlocal errorformat=%E!\ UnMatchaBle\ %trror:\ %m

    " Use Dispatch for background async compilation if available (note that for
    " background visual compilation we delete the visual file from the function
    " that shows output/errors)
    if exists(':Dispatch')
        echon 'running gauss with dispatch ...'
        " Make
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running gauss with make...'
        silent make!
    endif

    " Restore error format and return to previous working directory
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

" Define commands to run visual selections
command! -range EvalVisualGaussVimshell
            \ call s:RunGauss('visual', 'foreground', <line1>, <line2>)
command! -range EvalVisualGaussBackground
            \ call s:RunGauss('visual', 'background', <line1>, <line2>)
command! -range EvalVisualGaussForeground
            \ call s:RunGauss('visual', 'foreground_os', <line1>, <line2>)

" }}}
" Output/Errors {{{

function! s:ShowGaussOutput()
    " Only call this function after a gauss run
    if split(&makeprg, '')[0] !=# 'tgauss'
        return
    endif

    " Close/delete previous output preview window buffer
    silent! pclose
    silent! bdelete gauss_output

    " Get the Gauss file from makeprg
    let current_file = split(&makeprg, '')[-1]
    let base_file = fnamemodify(current_file, ':t:r')

    " If the file was run from a visual selection delete temp file since we
    " don't need it anymore
    if match(current_file, '_tmpvisual') != -1
        call delete(current_file)
    endif

    " Get output from the quickfix list
    let original_qflist = getqflist()
    let output = []
    for entry in original_qflist
        " On Windows with locale latin1 the error messages have the locale
        " encoding so we need to convert them back to utf-8
        if s:is_win
            let entry.text = iconv(entry.text, 'latin1', 'utf-8')
        endif
        let output = add(output, entry.text)
    endfor

    " Remove lines with `Job:` and date message (also the blank lines before and
    " after this)
    for item in output
        if match(item, '^Job:') != -1
            let job_line_ind = index(output, item)
            call remove(output, job_line_ind - 1, job_line_ind + 2)
            break
        endif
    endfor

    " If there is no output exit
    let height = len(output)
    if height == 0
        redraw
        unsilent echo 'No (printable) Gauss output'
        return
    endif

    " Initiate the new quickfix list
    let qflist = []

    " When running a visual selection get the correct file and line number
    let buf_nr_gss_file = bufnr(current_file)
    let correct_lnum = 0
    if match(current_file, '_tmpvisual') != -1
        let correct_file = join(split(current_file, '_tmpvisual'), '')
        let buf_nr_gss_file = bufnr(correct_file)

        " Now get the correct line number: the V mark is placed at the beginning
        " of the visual selection while the I mark measures the number of lines
        " that include external files. Note that if no files included then the I
        " mark is not set and line("'I") correctly (for our needs) returns 0.
        let correct_lnum = (-line("'I") - 1) + line("'V")
        " Finally delete visual marks since they are not needed anymore
        silent! delmarks V I
    endif

    " The next for loop builds the quickfix whenever there are errors: Gauss
    " errors seem to come in the following formats:
        " i) Line line_nr in full_path
            " error_message error_nr : error_line_contents
        " ii) Undefined symbols:
            " undefined_symbol   fullpath(line_nr)
            " another undefined_symbol   fullpath(line_nr)
        " iii) fullpath(line_nr) : error_nr : error message
    " Warnings are essentially similar to the third type of errors:
        " w) fullpath(line_nr) : Warning : warning message
    " Finally we might have a traceback
        " Strack trace:
        " procedure called from fullpath, line line_nr
    " Note that since there can be two errors in the same line, if we use index
    " this will match always the first error and will not allow us to get the
    " error message properly. So instead of using index() we use a counter to
    " get each item index in the output list
    let item_index = 0
    for item in output
        let entry = {}  " Each element of the qflist is a dictionary

        if match(item , '^\<Line\s\d\+\sin\>') != -1
            let entry.bufnr = buf_nr_gss_file
            let entry.lnum = str2nr(matchstr(item, 'Line\s\zs\d\+\ze')) +
                        \ correct_lnum
            " If the error is in a function file we need to get the correct
            " buffer number
            let error_file = matchstr(item, 'in\s\zs\S\+\ze')
            let error_base_file = fnamemodify(error_file, ':t:r')
            if error_base_file !=# base_file
                let entry.bufnr = bufnr(error_file)
                " If the buffer is not loaded this will return -1 even if the
                " file exists. Therefore we need to add it to the buffer list
                " (without loading it) using :badd
                if entry.bufnr == -1 && filereadable(error_file)
                    silent execute 'badd ' . error_file
                    let entry.bufnr = bufnr(error_file)
                endif
                " If the error file is not our base file then there is no need
                " to correct line numbers
                let entry.lnum = str2nr(matchstr(item, 'Line\s\zs\d\+\ze'))
            endif
            let entry.type = 'E'
            " Gauss error numbers have the following form: G0024
            let entry.nr = matchstr(output[item_index + 1],
                        \ 'error\sG\zs\d\+\ze\s')
            let entry.text = substitute(output[item_index + 1],
                        \ '\s\zsG\d\+\s\ze', '', '')
            " Add this entry and don't break the for loop because this error
            " might appear with the next one combined
            call add(qflist, entry)

        elseif match(item, '^Undefined\ssymbols:') != -1
            let distance = 1
            " We might have multiple undefined symbols
            while match(output[item_index + distance],
                        \ '\.\S\+(\zs\d\+\ze)') != -1
                let new_entry = {}
                let new_entry.bufnr = buf_nr_gss_file
                let new_entry.lnum = str2nr(matchstr(output[item_index +
                            \ distance], '\.\S\+(\zs\d\+\ze)')) + correct_lnum
                let error_file = matchstr(output[item + distance],
                            \ '\s\zs\S\+\ze(\d\+')
                let error_base_file = fnamemodify(error_file, ':t:r')
                if error_base_file !=# base_file
                    let new_entry.bufnr = bufnr(error_file)
                    if new_entry.bufnr == -1 && filereadable(error_file)
                        silent execute 'badd ' . error_file
                        let new_entry.bufnr = bufnr(error_file)
                    endif
                    let new_entry.lnum = str2nr(matchstr(output[item_index +
                            \ distance], '\.\S\+(\zs\d\+\ze)'))
                endif
                let new_entry.type = 'E'
                let new_entry.text = item . ' ' . matchstr(output[item_index +
                            \ distance], '\s\+\zs\S\+\ze\s')
                call add(qflist, new_entry)
                " Increase counter but exit if there are no more items
                let distance = distance + 1
                if (item_index + distance) > (len(output) - 1)
                    break
                endif
            endwhile

        elseif match(item, '^\S\+\ze(\d\+)\s:\s\(error\|Warning\)') != -1
            let entry.bufnr = buf_nr_gss_file
            let entry.lnum = str2nr(matchstr(item,
                        \ '^\S\+(\zs\d\+\ze)')) + correct_lnum
            let error_file = matchstr(item, '^\zs\S\+\ze(\d\+')
            let error_base_file = fnamemodify(error_file, ':t:r')
            if error_base_file !=# base_file
                let entry.bufnr = bufnr(error_file)
                if entry.bufnr == -1 && filereadable(error_file)
                    silent execute 'badd ' . error_file
                    let entry.bufnr = bufnr(error_file)
                endif
                let entry.lnum = str2nr(matchstr(item, '^\S\+(\zs\d\+\ze)'))
            endif
            " If we have warnings set the error type and warning text
            " accordingly and remove the warning from the output text
            if match(item, 'Warning') != -1
                let entry.type = 'W'
                let entry.text = matchstr(item, 'Warning\s:\s\zs.*')
                call remove(output, item_index)
            else
                let entry.type = 'E'
                let entry.nr = str2nr(matchstr(item, ':\serror\sG\zs\d\+\ze\s'))
                let entry.text = matchstr(item, 'G\d\+\s:\s\zs.*')
            endif
            call add(qflist, entry)

        " Finally the traceback
        elseif match(item, '^Stack trace:') != -1
            let entry.text = item
            call add(qflist, entry)
        elseif match(item, '\scalled\sfrom\s') != -1
            let entry.bufnr = buf_nr_gss_file
            let entry.lnum = str2nr(matchstr(item, '\sline\s\zs\d\+\ze')) +
                        \ correct_lnum
            let error_file = matchstr(item, 'called\sfrom\s\zs\S\+\ze,\sline')
            let error_base_file = fnamemodify(error_file, ':t:r')
            if error_base_file !=# base_file
                let entry.bufnr = bufnr(error_file)
                if entry.bufnr == -1 && filereadable(error_file)
                    silent execute 'badd ' . error_file
                    let entry.bufnr = bufnr(error_file)
                endif
                let entry.lnum = str2nr(matchstr(item, '\sline\s\zs\d\+\ze'))
            endif
            let entry.type = 'E'
            let entry.text = matchstr(item, '\S\+') .  ' called from this line.'
            call add(qflist, entry)

        " End possible cases
        endif
    " Update index counter
    let item_index = item_index + 1
    endfor " End looping over output lines

    " Since we might have deleted some lines from the output (i.e lines with
    " warnings messages) we need to recompute its height
    let height = len(output)

    " Open the quickfix if there are errors
    if !empty(qflist)
        " Set quickfix
        call setqflist(qflist, 'r')
        " Open quickfix window as a bottom window with appropiate height
        copen
        wincmd J
        let height_qf = len(qflist)
        if height_qf > 10
            let height_qf = 10
        endif
        execute height_qf . ' wincmd _'
        " Return to previous window
        wincmd p
        " If there are errors exit without displaying output buffer
        for entry in qflist
            if entry.type ==# 'E'
                return
            endif
        endfor
        " If there are warnings we do want to display the output buffer along
        " with the quickfix window unless the height of the output buffer is 0
        " (because this means we have warnings without output so we also return
        " after opening the quickfix window)
        if height == 0
            return
        endif
    endif

    " If we have output  we create a buffer to dump that output
    execute 'silent botright new gauss_output'
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight previewwindow

    " Actually append output
    call append(line('$'), output)

    " Delete extra line at the beginning and any potential other extra line at
    " beginning and end
    silent normal! ggdd
    if getline(1) ==# ''
        silent normal! ggdd
        let height = height - 1
    endif
    if getline(line('$')) ==# ''
        silent normal! Gdd
        let height = height - 1
    endif
    " Remove extra double indent?
    silent normal! gg<G
    silent normal! gg<G

    " Resize the buffer height
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'

    " If there is a quickfix window we want to place it below the output window:
    " Return to previous window and get its window number
    wincmd p
    let active_window = winnr()
    " Now go back to the output buffer window and move up to check if there is a
    " quickfix window: if there is one then switch them
    wincmd p
    wincmd k
    if &filetype ==# 'qf'
        wincmd x
    endif
    " Return to original window
    execute active_window . ' wincmd w'
endfunction

augroup show_gauss_output
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowGaussOutput()
augroup END

" }}}
" Miscellaneous {{{

" File deletion {{{

function! s:DeleteAuxFiles()
    " If the extensions to be deleted are wildignored they won't be recognised
    " by globpath function. Thus we first save and empty the wildignore setting
    let old_wig = &wildignore
    set wildignore=

    " Save working directory and switch to current file and define search path
    let l:save_pwd = getcwd()
    lcd %:p:h
    let path = expand('%:p:h') . '/**'

    " Get tkf files
    let extensions = 'tkf'
    let file_list = globpath(path,'*.{' . extensions . '}', 0, 1)

    let nr_filetypes = len(file_list)
    if nr_filetypes < 1
        echohl Error
        echo 'No auxiliary files are readable.'
        echohl none
        return
    endif
    if confirm('Really delete ' . nr_filetypes . ' tkf file(s)?',
                \ "&Yes\n&No") == 1
        for item in file_list
            if exists(':VimProcBang') && s:is_win
                call vimproc#delete_trash(item)
            else
                execute delete(item)
            endif
        endfor
        redraw!
        echo nr_filetypes ' tkf file(s) deleted.'
    endif
    " Restore wildignore and working directory
    let &wildignore = old_wig
    execute 'lcd ' . save_pwd
endfunction

" }}}
" Get included files {{{

" Get lines with included files (for visual compilation)
function! s:GetIncluded(beg_visual)
    let included_lines = []
    let line_nr = 1
    " The last line to check for included variables is the beginning of the
    " visual selection
    let end_line = a:beg_visual - 1
    while line_nr <= end_line
        let curline = getline(line_nr)
        " Match libraries (also matches libraries loaded with leading spaces,
        " such as those in conditionals; for these cases remove these leading
        " space before saving the line)
        if match(curline, '^\s*\(library\|dlibrary\|#include\)') != -1
            let curline = substitute(curline, '\s*', '', '')
            let included_lines = add(included_lines, curline)
        endif
        let line_nr = line_nr + 1
    endwhile
    return included_lines
endfunction

" }}}
" View (PDF) figure {{{

function! s:ViewPdfFigure()
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Construct the pdf (eps) file full path (get a base filename from the first
    " argument of export_fig function, remove possible extension and search
    " downwards in the current directory for a pdf file with that name)
    let search_path = expand('%:p:h') . '/**'
    let figure_file = matchstr(getline('.'), '-cf=\zs\S*\ze\s-c=1')
    let figure_file = fnamemodify(figure_file, ':t:r')
    let pdf_file = globpath(search_path, figure_file . '.eps')

    " Try to open the PDF file
    if !filereadable(pdf_file)
        echohl Error
        echo  figure_file . '.eps not found in ' . search_path
        echohl none
        return
    endif
    if s:is_win
        if !executable('SumatraPDF')
            echoerr 'SumatraPDF is not installed or not in your path.'
            return
        endif
        let viewer = 'silent! !start SumatraPDF -reuse-instance ' . pdf_file
        execute viewer
    endif

    " Restore previous working directory
    execute 'lcd ' . save_pwd
endfunction

" }}}
" }}}
" Mappings {{{

" Append a semicolon at the end of a line
nnoremap <silent> <buffer> <Leader>as mzA;<Esc>`z

" Background compilation
nnoremap <silent> <buffer> <F7> :call <SID>RunGauss('normal', 'background')<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunGauss('normal', 'background')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualGaussBackground<CR>
" Foreground compilation
nnoremap <silent> <buffer> <Leader>rf :call
            \ <SID>RunGauss('normal', 'foreground')<CR>
vnoremap <silent> <buffer> <Leader>rf :EvalVisualGaussVimshell<CR>
" Run in the command line (useful when input is required)
nnoremap <silent> <buffer> <F5> :call
            \ <SID>RunGauss('normal', 'foreground_os')<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunGauss('normal', 'foreground_os')<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualGaussForeground<CR>

" (Open) Interpreter or console
if exists(':Topen')
    nnoremap <silent><buffer> <Leader>oi :lcd %:p:h<CR>:T
                \ tgauss<CR>
endif
nnoremap <silent><buffer> <Leader>oc :lcd %:p:h<CR>:!start /b gauss<CR>

" View PDF figure
nnoremap <buffer> <silent> <Leader>vp :call <SID>ViewPdfFigure()<CR>

" Delete tkf (auxiliary) files
nnoremap <silent> <buffer> <Leader>da :call <SID>DeleteAuxFiles()<CR>

" }}}
