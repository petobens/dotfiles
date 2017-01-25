"===============================================================================
"          File: python_settings.vim
"        Author: Pedro Ferrari
"       Created: 30 Jan 2015
" Last Modified: 25 Jan 2017
"   Description: Python settings for Vim
"===============================================================================
" TODO: Learn OOP and TDD
" TODO: Learn how to use breakpoints
" TODO: Use mypy

" Installation notes {{{

" On Windows if we use the `winpython` distribution then we need to add the
" following to Path variable
" C:\prog-lang\winpython\python-3.4.3.amd64;
" C:\prog-lang\winpython\python-3.4.3.amd64\Scripts;
" C:\prog-lang\winpython\python-3.4.3.amd64\DLLs;
" In order for gvim to work we also need to create a PYTHONHOME env variable:
" C:\prog-lang\winpython\python-3.4.3.amd64
" Finally we use a requirements.txt file to install packages not included in
" winpython distribution (see dotfile folder)

" If we don't use winpython then some scientific packages (those that required
" compilation) must be installed with lepisma/pipwin or directly downloaded from
" Christoph Gohlke page.
" TODO: When using pipwin also use a requirements file

" }}}
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
" Options {{{

setlocal textwidth=79

" }}}
" Compiling {{{

" Set error format properly: if a line does not completely match one of the
" entries in 'efm', that line is added to the qf list and marked as 'not valid'.
" These 'not-valid' lines are the output we later show in a preview window.
" Therefore we must not use the catchnone '%-G%.%#' because if we use it all
" these `not-valid` lines will be ignored and not added to the qflist as we
" need.
" Note: most in the comments inside the function follow python-mode/run.vim
function! s:SetPyEfm()
    " The error message itself starts with a line with 'File' in it and comes
    " in a couple of variations
    setlocal errorformat=%E\ \ File\ \"%f\"\\\,\ line\ %l\\\,%m%\\C
    setlocal errorformat+=%E\ \ File\ \"%f\"\\\,\ line\ %l%\\C
    " The possible continutation lines are idenitifed to Vim by %C.
    " A pointer (^) identifies the column in which the error occurs (but will
    " not be entirely accurate due to indention of Python code)
    setlocal errorformat+=%C%p^
    " Any text indented by more than two spaces contains useful information
    " (and if we want it to appear in the quickfix we add %+ instead of %-)
    setlocal errorformat+=%-C\ \ %.%#
    setlocal errorformat+=%-C\ \ \ \ %.%#
    " The last line (%Z) does not begin with any whitespace. We use a zero
    " width lookahead (\@=) to check this. The line contains the error message
    " itself (%m)
    setlocal errorformat+=%Z%\\@=%m
    " setlocal errorformat+=%+Z%.%#Error\:\ %.%#
    " Python errors are multiline and often start with 'Traceback', if we don't
    " want to capture this so we use -G instead of +G
    setlocal errorformat+=%+GTraceback%.%#
    " Warnings (we ignore/delete the continuation line in the output function
    " that is called with the QuickFixCmdPost event)
    setlocal errorformat+=%f:%l:\ %.%#%tarning:%m
    " setlocal errorformat+=%-G%.%#warnings%.%#
endfunction

function! s:RunPython(mode, compilation, ...)
    " Check if python is installed
    if !executable('python3') && !executable('python')
        echoerr 'python is not installed or not in your path.'
        return
    endif

    " Place uppercase marks at i) the beginning of visual selection and ii)
    " counting how many lines there are importing modules in order to compute
    " correct line numbers in the quickfix later
    silent! delmarks V M   " Delete previous marks
    if a:mode ==# 'visual' && a:0 >= 1 && strlen(a:1)
        let modules = s:GetModules()
        let import_lines = modules[0]
        let last_module_line = modules[1]
        if last_module_line > 0
            " Only set a mark for modules if modules are indeed imported
            silent execute last_module_line . ' mark M'
        endif
        silent execute a:1 . ' mark V'
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf and location list, save and change working directory
    cclose
    lclose
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Set compiler (prefer python3) and file to run compiler
    let compiler = 'python3'
    if !executable(compiler)
        let compiler = 'python'
    endif
    " Add space to compiler
    let compiler = compiler . ' '


    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file in the current directory with visual content (and
        " imported modules)
        let current_file = expand('%:t:r') . '_tmpvisual.py'
        let visual_lines = getline(a:1, a:2)
        " Reindent this lines (i.e make first line have 0 indent)
        " First get number of spaces in the first line and remove those spaces
        let indent_length = match(visual_lines[0], '\w')
        let new_visual_lines = []
        for line in visual_lines
            let line = substitute(line, '^\s\{' . indent_length . '}\ze\s*\S',
                        \ '', '')
            call add(new_visual_lines, line)
        endfor
        " Add import lines and write it to a temp file
        let lines = import_lines + new_visual_lines
        call writefile(lines, current_file)
    else
        let current_file = expand('%:p:t')
    endif

    " Use Vimshell for foreground async compilation
    if a:compilation ==# 'foreground' && exists(':VimShell')
        VimShellBufferDir -popup
        " If we are on Windows we need to fix the encoding first
        let fix_encoding = ''
        if s:is_win
            let fix_encoding = 'exe --encoding=latin1 '
        endif
        if a:mode ==# 'visual'
            return vimshell#interactive#send([fix_encoding . compiler .
                        \ current_file, 'rm ' . current_file])
        else
            execute 'VimShellSendString ' . fix_encoding . compiler .
                        \ current_file
            wincmd p
        endif
        " Return to previous working directory and exit the function
        execute 'lcd ' . save_pwd
        return
    endif

    " We might want to do a foreground compilation in the regular os console
    " Note: on mac this requires iTerm to be open
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
    call s:SetPyEfm()

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        echon 'running python with dispatch ...'
        " Make
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running python with make...'
        silent make!
        " Open the quickfix window as a bottom window with appropiate height if
        " the quickfix list is not empty (since we remove output from the
        " quickfix list this is equivalent to open it only when there are valid
        " errors or warnings)
        let qflist = getqflist()
        if !empty(qflist)
            copen
            wincmd J
            let height_qf = len(qflist)
            if height_qf < 10
                execute height_qf . ' wincmd _'
            else
                execute '10 wincmd _'
            endif
            wincmd p  " Return to previous window
            " If there are warnings we might have an output buffer not properly
            " resized so now we resized it
            let active_window = winnr()
            " Now go back to the quickfix window and move up to check if there
            " is an output buffer: if there is one then resize it
            wincmd p
            wincmd k
            if bufname('%') ==# 'python_output'
                let output_height = line('$')
                if output_height < 15
                    execute output_height . ' wincmd _'
                else
                    execute '15 wincmd _'
                endif
            endif
            " Return to original window
            execute active_window . ' wincmd w'
        endif
    endif

    " Restore error format and return to previous working directory
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

" Define commands to run visual selections
command! -range EvalVisualPyVimshell
      \ call s:RunPython('visual', 'foreground', <line1>, <line2>)
command! -range EvalVisualPyBackground
      \ call s:RunPython('visual', 'background', <line1>, <line2>)
command! -range EvalVisualPyForeground
            \ call s:RunPython('visual', 'foreground_os', <line1>, <line2>)

" }}}
" Output/Errors {{{

" Show py output from the qf in a preview window
function! s:ShowPyOutput()
    " Only call this function after a python run
    let compiler = split(&makeprg, '')[0]
    if compiler !=# 'python3' && compiler !=# 'python'
        return
    endif

    " Close/delete previous output preview window buffer
    silent! pclose
    silent! bdelete python_output

    " Get current file
    let current_file = split(&makeprg, '')[1]
    " Delete visual temp file here (if it exists)
    if match(current_file, '_tmpvisual') != -1
        call delete(current_file)
    endif

    " Get current qflist and inititate output and boolean to check for errors
    " and warnings
    let qflist = getqflist()
    let output = []
    let has_errors = 0
    let has_warnings = 0

    " If the error type is indeed and error then we want to slice the qlist
    " until this first error to avoid showing output or warnings before it
    for entry in qflist
        if entry.type ==# 'E'
            let qflist = qflist[index(qflist, entry):]
            let has_errors = 1
            break
        endif
    endfor

    " Check if there are warnings
    for entry in qflist
        if entry.type ==# 'W'
            let has_warnings = 1
            break
        endif
    endfor

    if has_errors == 1 || has_warnings == 1
        " If we have errors or warnings we need to get the correct file and
        " line numbers whenever we run a visual selection: the V mark is placed
        " at the beginning of the visual selection while the M mark measures
        " the number of lines that import modules. Note that if no modules were
        " imported then the M mark is not set and line("'M") correctly (for our
        " needs) returns 0
        if match(current_file, '_tmpvisual') != -1
            let correct_file = join(split(current_file, '_tmpvisual'), '')
            let buf_nr_py_file = bufnr(correct_file)
            let correct_lnum = (-line("'M") - 1) + line("'V")
            " Now actually fix filename and line numbers
            for entry in qflist
                let buffer_number = get(entry, 'bufnr', '')
                if bufname(buffer_number) ==#  current_file
                    let entry.bufnr = buf_nr_py_file
                    let entry.lnum = entry.lnum + correct_lnum
                endif
            endfor
        endif
        " Delete visual marks since they are not longer needed and actually
        " replace qflist entries with the modified ones. If there are only
        " errors then exit
        silent! delmarks V M
        call setqflist(qflist, 'r')
        if has_errors == 1
            return
        endif
    endif

    " If we have warnings delete the (continuation) line after the actual
    " warning (we tried to do this with errorformat but failed)
    if has_warnings
        for entry in qflist
            if entry.type ==# 'W'
                call remove(qflist, index(qflist, entry) + 1)
            endif
        endfor
    endif

    " If there are no errors (but potentially warnings) get output text and
    " then remove this output entries from the quickfix list
    for entry in qflist
        if entry.valid == 0
            " On Windows with locale latin1 the error messages have the locale
            " encoding so we need to convert them back to utf-8
            if s:is_win
                let entry.text = iconv(entry.text, 'latin1', 'utf-8')
            endif
            let output = add(output, entry.text)
            call remove(qflist, index(qflist, entry))
        endif
    endfor

    " In these cases also delete visual marks and then replace the quickfix
    " list with the (shortened) qflist
    silent! delmarks V M
    call setqflist(qflist, 'r')

    " If we don't have output we return (when there no warnings giving a
    " message); if we have output (and potentially warnings) we create a
    " buffer to dump that output
    let height = len(output)
    if height == 0
        if has_warnings == 0
            redraw
            unsilent echo 'No (printable) python output'
        endif
        return
    else
        execute 'silent botright new python_output'
    endif
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight

    " Actually append output
    call append(line('$'), output)

    " Delete extra line at the beginning
    silent normal! ggdd

    " Mapping to enable syntax highlighting of SQL output
    nnoremap <silent> <buffer> <Leader>ss :set syntax=sql<CR>

    " When there are warnings and output and we are using Dispatch, the output
    " window is not resized properly because the quickfix window opens after it
    " (due to Dispatch Make calling cwindow). To prevent this this we call
    " cwindow ourselves so that when Dispatch calls cwindow again nothing
    " happens (because the quickfix window will be already opened)
    if has_warnings == 1 && exists(':Dispatch')
        " Move back to the current window, get its number and then open the
        " quickfix list with cwindow (which makes the cursor move to the qf)
        wincmd p
        let active_window = winnr()
        cwindow
        " Since the quickfix window will be open as a bottom window, now move
        " up to the output buffer and resize it
        wincmd k
        if bufname('%') ==# 'python_output'
            if height > 15
                let height = 15
            endif
            execute height . ' wincmd _'
        endif
        " Finally return to original window and exit
        execute active_window . ' wincmd w'
        return
    endif

    " When we only have output we simply resize the output buffer and then
    " return to the current window
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'
    wincmd p
endfunction

augroup show_py_output
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowPyOutput()
augroup END

" }}}
" Linting {{{

function! s:RunYapf(...)
    " Don't run yapf if it is not installed
    if !executable('yapf')
        echoerr 'yapf is not installed or not in your path.'
        return
    endif
    " Don't run yapf if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Try first to sort imports (requires impsort.vim plugin)
    if exists(':ImpSort')
        ImpSort
    endif

    " Yapf can fail so we don't use format gq motions here (we always run yapf
    " on the whole file)
    let old_formatprg = &l:formatprg
    let save_cursor = getcurpos()
    let &l:formatprg = 'yapf '
    silent execute '0,$!' . &l:formatprg
    if v:shell_error == 1
        silent undo
    endif
    call setpos('.', save_cursor)
    let &l:formatprg = old_formatprg
endfunction

" Automatically run autopep8 and flake8 on save
augroup py_linting
    au!
    au BufWritePost *.py call s:RunYapf() | silent noautocmd update |
                \ silent Neomake
augroup END

" }}}
" Docs {{{

function! s:PyDoc()
    " Check if python is installed
    if !executable('python3') && !executable('python')
        echoerr 'python is not installed or not in your path.'
        return
    endif

    " If there is a word under the cursor try to use jedi - documentation
    " function to retrieve docs; otherwise use pydoc
    let object = expand('<cword>')
    if !empty(object)
        call jedi#show_documentation()
        return
    else
    " Note that here the  object should be entered without parenthesis, i.e
    " numpy.add and not numpy.add()
        let object = input('Enter object to view doc: ')
        if empty(object)
            return
        endif
    endif

    " Delete previous doc buffers
    silent! bdelete Py_doc
    silent! bdelete __doc__

    " Define settings for this new buffer and read/paste output from pydoc
    let compiler = 'python3'
    if !executable(compiler)
        let compiler = 'python'
    endif
    " Add space to compiler
    let compiler = compiler . ' '

    let pydoc_command = compiler . ' -m pydoc ' . object
    let output = split(system(pydoc_command), '\n')

    " If there is no documentation give error message
    if match(output[0] , '^no Python documentation') != -1
        redraw!
        echohl Error
        echo 'No Python docs found for `' . object . '`'
        echohl none
        return
    endif

    " If there is documentation create a buffer to dump output
    let height = len(output)
    execute 'silent botright new Py_doc'

    " Actually dump the output
    call append(line('$'), output)

    " Delete extra line at the end (only if it's empty), at the beginning,
    " remove extra indent and set buffer to nonmodifiable and filetype rst
    if getline(line('$')) ==# ''
        silent normal! Gdd
        let height = height - 1
    endif
    silent normal! ggdd
    silent normal! gg<G
    setlocal nomodifiable nomodified filetype=rst

    " Resize the buffer height
    if height > g:jedi#max_doc_height
        let height = g:jedi#max_doc_height
    endif
    execute height . ' wincmd _'

    " Mappings to quit this buffer easily and search for another object
    nnoremap <silent> <buffer> Q :bd!<CR>
    nnoremap <silent> <buffer>  <C-]> :call <SID>PyDoc()<CR>
    nnoremap <silent> <buffer> <S-k> :call <SID>PyDoc()<CR>

    " Highlight python code within rst
    unlet! b:current_syntax
    syn include @rstPythonScript syntax/python.vim
    syn region rstPythonRegion start=/^\v {4}/ end=/\v^( {4}|\n)@!/
                \ contains=@rstPythonScript
    syn region rstPythonRegion matchgroup=pythonDoctest start=/^>>>\s*/
                \ end=/\n/ contains=@rstPythonScript
    let b:current_syntax = 'rst'
endfunction

augroup py_doc_rst
    au!
    " Allow also to search for another object in jedi docs
    au FileType rst if fnamemodify(bufname(''), ':t') ==# '''__doc__''' |
                \ nnoremap <silent> <buffer> K :call <SID>PyDoc()<CR> |
                \ nnoremap <silent> <buffer>  <C-]> :call <SID>PyDoc()<CR> |
                \ endif
augroup END

" }}}
" (Py)Tests {{{

function! s:RunPyTest(level)
    " Don't run if pytest if it is not installed
    if !executable('py.test')
        echoerr 'py.test is not installed or not in your path.'
        return
    endif
    " Also exit if coverage is not installed
    if !executable('coverage')
        echoerr 'coverage is not installed or not in your path.'
        return
    endif
    " Don't run py.test if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf, save working directory and get current file
    cclose
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Set compiler (Use short traceback print mode and decrease verbosity)
    let compiler = 'py.test --tb=short -q '
    " let &l:makeprg = compiler . current_file

    " Check if we have a tests dir and change lcd to it
    let test_dir = ''
    let dir_level = ':p:h'
    for i in [1, 2, 3]
        let curr_dir = fnamemodify(current_file, dir_level)
        if !isdirectory(curr_dir . '/tests')
            let dir_level = dir_level . ':h'
        else
            let test_dir = fnamemodify(current_file, dir_level)
            break
        endif
    endfor
    if test_dir ==# ''
        echohl Error
        echo  'No `tests` directory found.'
        echohl none
        return
    endif
    execute 'lcd ' . test_dir

    " Allow to run the whole test suite, just one test file (module) or specific
    " classes or methods inside a test file. When running the whole suite also
    " perform test coverage.
    if a:level ==# 'suite'
        " We want to get coverage when running the full test suite
        let compiler = compiler . '--cov-report term-missing --cov='
        " Try to infer project name (by searching for a main.py file)
        let proj_dir = globpath(test_dir . '/**', 'main.py', 0, 1)
        if len(proj_dir) == 1
            let project = fnamemodify(proj_dir[0], ':h:t')
        else
            let project = input('Enter project to view coverage: ')
            if empty(project)
                redraw!
                return
            endif
        endif
        let &l:makeprg = compiler . project . ' tests/'
    elseif a:level ==# 'file'
        execute 'lcd ' . test_dir . '/tests'
        if match(current_file, '^test_') == -1
            let current_file = 'test_' . current_file
        endif
        let &l:makeprg = compiler . current_file
    else
        " When not running for the whole suite or a test file then get current
        " tag using Tagbar plugin
        execute 'lcd ' . test_dir . '/tests'
        if exists(':Tagbar')
            let current_tag = split(tagbar#currenttag('%s', '', 'f'), '\.')
            if len(current_tag) == 2
                let class = current_tag[0]
                let method = split(current_tag[1], '(')[0]
            else
                let method = split(current_tag[0], '(')[0]
            endif
            if a:level ==# 'class'
                if match(current_file, '^test_') == -1
                    let current_file = 'test_' . current_file
                    let class = 'Test' . class
                endif
                let &l:makeprg = compiler . current_file . '::' . class
            else
                let &l:makeprg = compiler . current_file . '::' . class .
                            \ '::' . method
            endif
        endif
    endif

    " Set error format (see https://github.com/5long/pytest-vim-compiler)
    let old_efm = &l:efm
    setlocal errorformat =
      \%-G=%#\ ERRORS\ =%#,
      \%-G=%#\ FAILURES\ =%#,
      \%-G%\\s%\\*%\\d%\\+\ tests\ deselected%.%#,
      \ERROR:\ %m,
      \%E_%\\+\ %m\ _%\\+,
      \%Cfile\ %f\\,\ line\ %l,
      \%CE\ %#%m,
      \%EE\ \ \ \ \ File\ \"%f\"\\,\ line\ %l,
      \%ZE\ \ \ %[%^\ ]%\\@=%m,
      \%Z%f:%l:\ %m,
      \%Z%f:%l,
      \%C%.%#,
      \%-G%.%#\ seconds,
      \%-G%.%#,

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchall because Dispatch removes it
        " let &l:efm = &efm . ',%-G%.%#'
        echon 'running py.test with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running py.test ...'
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
            echon 'Finished py.test successfully.'
        endif
    endif
    " Restore error format and working directory
    let &l:efm = old_efm
    execute 'lcd ' . l:save_pwd
endfunction

function! s:ShowPyTestCoverage()
    " Only call this function after a pytest run with coverage report
    if index(split(&makeprg, ''), '--cov-report') < 0
        return
    endif

    " Delete previous coverage buffer
    silent! bdelete coverage_output

    " Get current qflist and inititate output and boolean to check for errors
    let qflist = getqflist()
    let output = []

    " Check for errors
    let has_errors = 0
    for entry in qflist
        if entry.type ==# 'E'
            let has_errors = 1
            break
        endif
    endfor

    " If there are errors remove coverage stats from quickfix and then exit
    if has_errors == 1
        for entry in qflist
            if match(entry.text , '^---------- coverage') != -1
                let coverage_start = index(qflist, entry) - 1
            elseif match(entry.text , '^TOTAL') != -1
                let coverage_end = index(qflist, entry) + 1
                break
            endif
        endfor
        call remove(qflist, coverage_start, coverage_end)
        call setqflist(qflist, 'r')
        return
    endif

    " If there are no errors get output text (i.e coverage report) and then
    " remove this output entries from the quickfix list (i.e empty qflist)
    for entry in qflist
        if entry.valid == 0
            if s:is_win
                let entry.text = iconv(entry.text, 'latin1', 'utf-8')
            endif
            let output = add(output, entry.text)
            call remove(qflist, index(qflist, entry))
        endif
    endfor

    " Check if we have a file with dir matching to our project
    let project = matchstr(&makeprg, '-cov=\zs.*\ze\s')
    let base_dir = ''
    for i in range(1, bufnr('$'))
        let buf_name = fnamemodify(bufname(i), ':p')
        if fnamemodify(buf_name, ':h:t') ==# project
            let base_dir = fnamemodify(buf_name, ':h:h')
            break
        endif
    endfor

    " Get those lines with missing coverage and add them to the quickfix list
    let cov_qflist = []
    for line in output
        let entry = {}
        let entry.type = 'W'
        let missing_lines = matchstr(line, '\d\+%\s\+\zs\d*.*')
        if missing_lines !=# ''
            " Get first missing line of the file (and report in the message all
            " missing line numbers)
            let missing_file = matchstr(line, '^\w*.*\.py')
            let uncovered_file = base_dir . '/' . missing_file
            let entry.bufnr = bufnr(uncovered_file)
            if entry.bufnr == -1 && filereadable(uncovered_file)
                silent execute 'badd ' . uncovered_file
                let entry.bufnr = bufnr(uncovered_file)
            endif
            let line_nr  = split(split(missing_lines, ',')[0], '-')[0]
            let entry.lnum = line_nr
            let entry.text = 'Untested lines: ' . missing_lines
            call add(cov_qflist, entry)
        endif
    endfor

    if !empty(cov_qflist)
        " Set quickfix
        call setqflist(cov_qflist, 'r')
    endif

    " If we have output we create a buffer to dump that output
    let height = len(output)
    if height != 0
        execute 'silent botright new coverage_output'
    else
        return
    endif
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight

    " Actually append output
    call append(line('$'), output)

    " Delete extra line at the end (only if it's empty) and at the beginning
    " and set the buffer to not modifiable
    if getline(line('$')) ==# ''
        silent normal! Gdd
        let height = height - 1
    endif
    silent normal! ggdd
    setlocal nomodifiable nomodified

    " Resize the buffer height
    if height > g:jedi#max_doc_height
        let height = g:jedi#max_doc_height
    endif
    execute height . ' wincmd _'
endfunction

augroup show_pytest_coverage
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowPyTestCoverage()
augroup END

" Function to open to test file
if !exists('*s:EditTestFile')
    function! s:EditTestFile()
        let l:save_pwd = getcwd()
        lcd %:p:h
        let current_file = expand('%:p:t')

        " Check if we have a tests dir and change lcd to it
        let test_dir = ''
        let dir_level = ':p:h'
        for i in [1, 2, 3]
            let curr_dir = fnamemodify(current_file, dir_level)
            if !isdirectory(curr_dir . '/tests')
                let dir_level = dir_level . ':h'
            else
                let test_dir = fnamemodify(current_file, dir_level) . '/tests/'
                break
            endif
        endfor
        if test_dir ==# ''
            echohl Error
            echo  'No `tests` directory found.'
            echohl none
            return
        endif
        execute 'lcd ' . test_dir

        " Open the file in a horizontal or vertical split
        let test_file = 'test_' . current_file
        let split_windows = 'vsplit '
        if winwidth(0) <= 2 * (&textwidth ? &textwidth : 80)
            let split_windows = 'split '
        endif
        execute split_windows . test_file
    endfunction
endif

" }}}
" Miscellaneous {{{

" Get modules {{{

" Get lines with modules (for visual compilation)
function! s:GetModules()
    let import_lines = []
    let line_nr = 1
    let end_line = 25  " Last line to check for modules (increase if necessary)
    if line('$') < end_line
        let end_line = line('$')
    endif
    while line_nr <= end_line
        let curline = getline(line_nr)
        " Match imports (also matches modules loaded with leading spaces, such
        " as those in conditionals; for these cases remove these leading space
        " before saving the line)
        " FIXME: This won't work with import( in multiple lines
        if match(curline, '^\s*\(import\|from\)') != -1
            let curline = substitute(curline, '\s*', '', '')
            let import_lines = add(import_lines, curline)
        endif
        let line_nr = line_nr + 1
    endwhile
    " Get how many import lines we have to correctly compute error line numbers
    let last_module_line = len(import_lines)
    " Return a list
    let return_list = [import_lines, last_module_line]
    return return_list
endfunction

" }}}
" View (PDF) figure {{{

function! s:ViewPdfFigure()
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Construct the pdf file full path (get a base filename from the first
    " argument of plt.savefig() function, remove possible extension and search
    " downwards in the current directory for a pdf file with that name)
    let search_path = expand('%:p:h:h') . '/**'
    let figure_file = matchstr(getline('.'), '\''\zs\S*\ze\''')
    let figure_file = fnamemodify(figure_file, ':t:r')
    let pdf_file = globpath(search_path, figure_file . '.pdf')

    " Try to open the PDF file
    if !filereadable(pdf_file)
        echohl Error
        echo  figure_file . '.pdf not found in ' . search_path
        echohl none
        return
    endif
    if s:is_win
        if !executable('SumatraPDF')
            echoerr 'SumatraPDF is not installed or not in your path.'
            return
        endif
        let viewer = 'silent! !start SumatraPDF -reuse-instance ' . pdf_file

    else
        let open_cmd = 'open '
        if exists('$TMUX') && executable('reattach-to-user-namespace')
            " In tmux we need to fix the open command
            let open_cmd = 'reattach-to-user-namespace open '
        endif
        let viewer = 'silent! !' . open_cmd . '-a Skim ' . pdf_file
    endif
    execute viewer
    redraw!

    " Restore previous working directory
    execute 'lcd ' . save_pwd
endfunction

" }}}
" View Module {{{

" Function to view a module source code
if !exists('*s:ViewPyModule()')
    function! s:ViewPyModule()
        if !exists(':Pyimport')
            echohl Error
            echo 'jedi-vim is not installed.'
            echohl none
            return
        endif
        let import = input('Enter module name: ')
        if empty(import)
            return
        endif
        execute 'Pyimport ' . import
    endfunction
endif

" }}}

" }}}
" Mappings {{{

" Anon snippets for triple quotes
if exists(':UltiSnipsEdit')
    inoremap <buffer> <silent> tq tq<C-R>=UltiSnips#Anon('"""${1:${VISUAL}}"""',
                \ 'tq', '', 'i')<CR>
endif

" Background compilation
nnoremap <silent> <buffer> <F7> :call <SID>RunPython('normal', 'background')<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunPython('normal', 'background')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualPyBackground<CR>
" Foreground compilation
nnoremap <silent> <buffer> <Leader>rf :call
            \ <SID>RunPython('normal', 'foreground')<CR>
vnoremap <silent> <buffer> <Leader>rf :EvalVisualPyVimshell<CR>:wincmd p<CR>
" Run in the command line (useful when input is required)
nnoremap <silent> <buffer> <F5> :call
            \ <SID>RunPython('normal', 'foreground_os')<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunPython('normal', 'foreground_os')<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualPyForeground<CR>

" Linting (and import sorting)
nnoremap <buffer> <Leader>rl :call <SID>RunFlake8()<CR>
nnoremap <buffer> <Leader>ap :call <SID>RunAutoPep8()<CR>
if exists(':ImpSort')
    nnoremap <buffer> <silent> <Leader>is :ImpSort<CR>
endif
" The visual map messes up proper comment indentation/formatting:
" vnoremap <buffer> Q :call <SID>RunAutoPep8('visual')<CR>
nnoremap <buffer> <Leader>yp :call <SID>RunYapf()<CR>

" Tests and coverage (py.test dependant)
nnoremap <buffer> <Leader>rt :call <SID>RunPyTest('suite')<CR>
nnoremap <buffer> <Leader>tf :call <SID>RunPyTest('file')<CR>
nnoremap <buffer> <Leader>tc :call <SID>RunPyTest('class')<CR>
nnoremap <buffer> <Leader>tm :call <SID>RunPyTest('method')<CR>
nnoremap <buffer> <silent> <Leader>et :call <SID>EditTestFile()<CR>

" (Open) Interpreter (in vimshell) and ipython
if exists(':VimShell')
    nnoremap <buffer> <silent> <Leader>oi :VimShellInteractive python<CR>
endif
if executable('ipython')
    nnoremap <buffer> <silent> <Leader>ip :!start /b ipython qtconsole<CR>
endif

" Documentation
nnoremap <buffer> <silent> <S-k> :call <SID>PyDoc()<CR>

" View PDF figure
nnoremap <buffer> <silent> <Leader>vp :call <SID>ViewPdfFigure()<CR>

" View module source code
nnoremap <buffer> <silent> <Leader>vm :call <SID>ViewPyModule()<CR>

" Close output buffer
nnoremap <buffer> <silent> <Leader>oc :silent! bdelete python_output<CR>

" }}}
