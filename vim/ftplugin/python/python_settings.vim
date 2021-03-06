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

function! s:Dedent(lines)
    " Reindent this lines (i.e make first line have 0 indent)
    " First get number of spaces in the first line and remove those spaces
    let indent_length = match(a:lines[0], '\w')
    let new_lines = []
    for line in a:lines
        let line = substitute(line, '^\s\{' . indent_length . '}\ze\s*\S',
                    \ '', '')
        call add(new_lines, line)
    endfor
    return new_lines
endfunction

" }}}
" Options {{{

setlocal textwidth=88

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
    " want to capture this we use -G instead of +G
    setlocal errorformat+=%+GTraceback%.%#
    setlocal errorformat+=%+GDuring\ handling%.%#
    setlocal errorformat+=%+GThe\ above\ exception%.%#
    " Warnings (we ignore/delete the continuation line in the output function
    " that is called with the QuickFixCmdPost event)
    setlocal errorformat+=%f:%l:\ %.%#%tarning:%m
    " setlocal errorformat+=%-G%.%#warnings%.%#
endfunction

function! s:RunPython(compiler, mode, compilation, debugging, ...)
    " Check if python is installed
    if !executable(a:compiler)
        echoerr a:compiler . 'is not installed or not in your path.'
        return
    endif

    " Get debugger argument
    let debugger_mode = a:debugging

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

    " Set compiler (prefer python3)
    if a:compiler ==# 'python'
        let compiler = 'python3'
    else
        let compiler = a:compiler
    endif

    " If we are inside a venv then override the compiler
    if isdirectory($VIRTUAL_ENV)
        let compiler_bin = $VIRTUAL_ENV . '/bin'
        let compiler = compiler_bin . '/' . compiler
    endif

    let compiler = compiler . ' '

    " Add debugging flags (allows post-mortem debugging)
    if debugger_mode
        let compiler .= '-m pdb -cc '
    endif

    " Define file to run
    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file in the current directory with visual content (and
        " imported modules)
        let current_file = expand('%:t:r') . '_tmpvisual.py'
        let visual_lines = getline(a:1, a:2)
        let new_visual_lines = s:Dedent(visual_lines)
        " Add import lines and write it to a temp file
        let lines = import_lines + new_visual_lines
        call writefile(lines, current_file)
    else
        let current_file = expand('%:p')
    endif

    " Use neovim terminal for foreground async compilation (either in regular
    " python or ipython)
    if a:compilation ==# 'foreground' && exists(':Topen')
        let old_size = g:neoterm_size
        let old_autoinsert = g:neoterm_autoinsert
        let g:neoterm_size = 12
        let g:neoterm_autoinsert = 0

        if match(trim(split(compiler, '/')[-1]), '^ipython') == -1
            Topen
            " If we are inside an ipython instance exit first (and reset name)
            let last_active_instance = g:neoterm.last()
            let buf_nr = last_active_instance.buffer_id
            if bufexists(buf_nr)
                let term_buf_name = bufname(buf_nr)
            endif
            if term_buf_name ==# 'ipython'
                execute 'T exit'
                let winid = win_findbuf(buf_nr)[0]
                call win_gotoid(winid)
                keepalt file bash
                wincmd p
            endif
            if a:mode ==# 'visual'
                execute 'T ' . compiler .  current_file .
                            \ '; command rm ' . current_file
            else
                execute 'T ' . compiler .  current_file
            endif
        else
            " We only do normal ipython run here since visual runs are handled
            " by IPyREPL function defined afterwards (below)
            call s:EnsureIpythonNeotermInstance()
            if a:mode !=# 'visual'
                execute 'T %run ' . current_file
            endif
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
    " Note: on mac this requires iTerm to be open
    if a:compilation ==# 'foreground_os'
        let bang_command = '!'
        let remove_visual_command = ''
        if exists(':Dispatch')
            let dispatch_title = 'py-'. fnamemodify(current_file, ':t')[:8]
            let bang_command = 'Spawn -wait=always -title=' .
                        \ dispatch_title . ' '
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

" Define commands to run visual selections (always in python3)
command! -range -nargs=* EvalVisualPyVimshell
      \ call s:RunPython(<f-args>, 'visual', 'foreground', 0, <line1>, <line2>)
command! -range -nargs=* EvalVisualPyBackground
      \ call s:RunPython(<f-args>, 'visual', 'background', 0, <line1>, <line2>)
command! -range -nargs=* EvalVisualPyForeground
            \ call s:RunPython(<f-args>, 'visual', 'foreground_os', 0, <line1>,
            \ <line2>)
command! -range -nargs=* EvalVisualPyDebug
            \ call s:RunPython(<f-args>, 'visual', 'foreground_os', 1, <line1>,
            \ <line2>)

" }}}
" Output/Errors {{{

" Show py output from the qf in a preview window
function! s:ShowPyOutput()
    " Only call this function after a python run
    let compiler = split(split(&makeprg, '')[0], '/')[-1]
    if compiler !=# 'python3' && compiler !=# 'python'
        return
    endif

    " Close/delete previous output preview window buffer
    silent! pclose
    silent! bwipeout python_output

    " Get current active window
    let active_window = win_getid()

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

    " Check if there are errors
    for entry in qflist
        if entry.type ==# 'E'
            let first_error_index = index(qflist, entry)
            " If there are errors insert a line to indicate they start here
            let new_entry = {'valid': 0, 'type': '',
                \ 'text': repeat('*', 40) . '-ERRORS-' . repeat('*', 40)}
            call insert(qflist, new_entry, first_error_index - 1)
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
        " replace qflist entries with the modified ones.
        silent! delmarks V M
        call setqflist(qflist, 'r')


        " If there are only errors exit
        if has_errors == 1
            for entry in qflist
                " Get all non-valid lines and remove blank lines
                " FIXME: Remove only blank lines after first error
                if entry.valid == 0 && match(entry.text, '^$') != -1
                    call remove(qflist, index(qflist, entry))
                endif
            endfor
            call setqflist(qflist, 'r')
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

    " Get output text and then remove this output entries from the quickfix
    " list
    for entry in qflist
        if entry.valid == 0  " get all 'non-valid' lines
        " FIXME: The max line length is 4096
        " See https://github.com/neovim/neovim/blob/
            " 51808a244ecaa0a40b4e8280938333d2792d8422/src/nvim/api/vim.c#L37
            " On Windows with locale latin1 the error messages have the locale
            " encoding so we need to convert them back to utf-8
            if s:is_win
                let entry.text = iconv(entry.text, 'latin1', 'utf-8')
            endif
            let output = add(output, entry.text)
            call remove(qflist, index(qflist, entry))
        endif
    endfor
    " Compute number of lines in output
    let height = len(output)

    " Delete visual marks and then replace the quickfix list with the
    " (shortened) qflist
    silent! delmarks V M
    call setqflist(qflist, 'r')

    " If we don't have output we return (when there no warnings giving a
    " message); if we have output (and potentially warnings) we create a buffer
    " to dump that output
    if height == 0
        if has_warnings == 0
            redraw
            unsilent echo 'No (printable) python output'
        endif
        return
    else
        execute 'silent botright new python_output'
        let output_win = win_getid()
        if has_warnings == 1
            " When there are warnings and output and we are using Dispatch, the
            " output window is not resized properly because the quickfix window
            " opens after it (due to Dispatch Make calling cwindow). To prevent
            " this this we call cwindow ourselves so that when Dispatch calls
            " cwindow again nothing happens (because the quickfix window will be
            " already opened)
            cwindow
        endif
        call win_gotoid(output_win)
        execute '1 wincmd _'
    endif

    " Set output buffer properties
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight

    " Actually append output
    call append(line('$'), output)

    " Delete extra line at the beginning
    silent normal! ggdd

    " Mapping to enable syntax highlighting of SQL output
    nnoremap <silent> <buffer> <Leader>ss :set syntax=sql<CR>

    " Resize the output buffer and then return to the last active  window
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'
    call win_gotoid(active_window)
endfunction

augroup show_py_output
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowPyOutput()
augroup END

function! s:LoadTracebackFromTmux(tmux_win_nr)
    " Note: we assume we want the first (unique) pane from the tmux window
    let pane_id = matchstr(split(trim(system('tmux list-panes -t ' .
                \ a:tmux_win_nr)), '\n')[0], '\zs%\d\+\ze')
    let pane_content = split(trim(system('tmux capture-pane -p -t ' . pane_id)),
                \ '\n')
    let tmp_file = expand('%:t:r') . '_qf_tmp.txt'
    call writefile(pane_content[:-2], tmp_file)
    let old_efm = &l:efm
    call s:SetPyEfm()
    silent doautocmd QuickFixCmdPre cgetfile
    call setqflist([], 'r')
    execute 'cgetfile ' . tmp_file
    silent doautocmd QuickFixCmdPost cgetfile
    call delete(tmp_file)
    copen
    let &l:efm = old_efm
endfunction
command! -nargs=1 LoadTraceFromTmux call s:LoadTracebackFromTmux(<f-args>)

" }}}
" Formatting {{{

function! s:RuniSort(...)
    " Don't run isort if it is not installed
    if !executable('isort')
        echoerr 'isort is not installed or not in your path.'
        return
    endif
    " Don't run isort if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Change shellredir to avoid inserting error output into the buffer (i.e
    " don't include stderr in output buffer)
    let shrd = &shellredir
    set shellredir=>%s
    let old_formatprg = &l:formatprg
    let &l:formatprg = 'isort -'
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
endfunction

function! s:RunBlack(...)
    " Don't run black if it is not installed
    if !executable('black')
        echoerr 'black is not installed or not in your path.'
        return
    endif
    " Don't run black if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Try first to sort imports if full run
    if a:0 == 0
        call s:RuniSort()
    endif

    " Change shellredir to avoid inserting error output into the buffer (i.e
    " don't include stderr in output buffer)
    let shrd = &shellredir
    set shellredir=>%s
    let old_formatprg = &l:formatprg
    let &l:formatprg = 'black --config ' . expand($HOME . '/.black.toml') . ' -'
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
endfunction

" Automatically run black and flake8 on save. After that run semantic higlighter
" (it needs to be done after Neomake otherwise hl won't work)
augroup py_linting
    au!
    au BufWritePost *.py lclose | call s:RunBlack() | silent noautocmd update |
                \ silent Neomake | silent Semshi enable
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
        silent call jedi#show_documentation()
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

function! s:RunPyTest(level, compilation, ...)
    " Don't run if pytest or coverage are not installed
    " TODO: Find a way to check if pytest-cov is installed
    let compiler = 'py.test'
    let coverage_exe = 'coverage'
    if isdirectory($VIRTUAL_ENV)
        let compiler_bin = $VIRTUAL_ENV . '/bin'
        if compiler_bin !=# ''
            let compiler = compiler_bin . '/' . compiler
            if ! filereadable(expand(compiler))
                echoerr 'py.test not found in ' . compiler_bin
                return
            endif
            let coverage_exe = compiler_bin . '/' . coverage_exe
            if ! filereadable(expand(coverage_exe))
                echoerr 'coverage not found in ' . compiler_bin
                return
            endif
        endif
    else
        if !executable(compiler)
            echoerr 'py.test is not installed or not in your path.'
            return
        endif
        if !executable(coverage_exe)
            echoerr 'coverage is not installed or not in your path.'
            return
        endif
    endif

    " Don't run py.test if we are in a Gdiff (when file path includes .git)
    if expand('%:p') =~# "/\\.git/"
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf and location list, save working directory and get current file
    cclose
    lclose
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Use a mark to find path be used in the quickfix later on
    silent! delmarks C
    silent execute 'mark C'

    " Check if we have a tests dir and change lcd to it (essentially move up
    " from the current directory until we find a `tests` directory)
    " Note: this assumes we have a tests dir outside the application code (i.e
    " at the same level as the application code)
    let test_dir = ''
    let dir_level = ':p:h'
    for i in [1, 2, 3, 4]
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

    " Ensure the current file is a 'test' file
    let need_prefix = 0
    if match(current_file, '^test_') == -1
        let current_file = 'test_' . current_file
        let need_prefix = 1
    else
        " If the current file is already a test file it might be inside nested
        " inner dirs so get here those inner dirs
        let current_file = split(expand('%:p'), 'tests')[-1]
    endif

    " Set compiler options (run in parallel (requires pytest-xdist), use short
    " traceback print mode and decrease verbosity)
    let parallel = get(a:, 1, 0)
    if parallel
        let compiler = compiler . ' -n auto'
    endif
    let compiler = compiler . ' --tb=short -q '

    " Allow to run the whole test suite, just one test file (module) or specific
    " classes or methods inside a test file. When running the whole suite also
    " perform test coverage.
    if a:level ==# 'suite'
        " We want to get coverage when running the full test suite (assume here
        " that we want to run coverage for all files and let the config file
        " determine which files to omit)
        let compiler = compiler . '--cov-report term-missing --cov=. '

        " Check if we have a coveragerc file
        let search_path = fnamemodify(test_dir, ':p:h') . '/**'
        let coveragerc_file = globpath(search_path, '.coveragerc*')
        if coveragerc_file ==# ''
            let coveragerc_file = globpath(search_path, '*coveragerc*')
        endif
        if !filereadable(coveragerc_file)
            let coveragerc_file = input('Enter coveragerc path: ', '', 'file')
            if empty(coveragerc_file)
                let coveragerc_file = ''
            endif
        endif
        if coveragerc_file !=# ''
            let cov_config = ' --cov-config ' . coveragerc_file
        else
            let cov_config = ''
        endif
        let &l:makeprg = compiler . 'tests/' . cov_config
    elseif a:level ==# 'file'
        " Also run test coverage here but only for this file/module
        let compiler = compiler . '--cov-report term-missing --cov='
        " We already ensured that the current file has `test_` preprended so get
        " module name by stripping the prefix
        let cov_module = split(fnamemodify(current_file, ':t:r'), 'test_')[-1]
        " Check if the module is in the current dir otherwise look for it and
        " modify it's name accordingly (i.e if the module is foo and foo exists
        " in the current dir do nothing but if foo is inside bar then define
        " module as foo.bar)
        let base_file = cov_module . '.py'
        if !filereadable(test_dir . '/' . base_file)
            let base_file = globpath(test_dir . '/**', base_file)
            if filereadable(base_file)
                let cov_module = fnamemodify(base_file, ':p:.:r:s?/?\.?')
            endif
        endif
        let &l:makeprg = compiler . cov_module . ' tests/' . current_file
    else
        " When not running for the whole suite or a test file then get current
        " tag using Tagbar plugin
        execute 'lcd ' . test_dir . '/tests'
        if !exists(':Tagbar')
            echoerr 'Tagbar plugin is needed for this functionality.'
            return
        endif

        let current_tag = split(tagbar#currenttag('%s', '', 'f'), '\.')
        if len(current_tag) >= 2
            let class = current_tag[0]
            let method = split(current_tag[1], '(')[0]
            " If the method is private and thus starts with an underscore don't
            " add an extra underscore
            let prefix = (match(method, '^_') == -1)? 'test_' : 'test'
            if need_prefix == 1
                let class = 'Test' . class
                let method = prefix . method
            endif
        else
            let method = split(current_tag[0], '(')[0]
            let prefix = (match(method, '^_') == -1)? 'test_' : 'test'
            if need_prefix == 1
                let method = prefix . method
            endif
        endif
        if a:level ==# 'class'
            let &l:makeprg = compiler . current_file . '::' . class
        else
            if exists('class')
                let &l:makeprg = compiler . current_file . '::' . class .
                            \ '::' . method
            else
                let &l:makeprg = compiler . current_file . '::' . method
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

    " We might want to do a foreground compilation in the regular os console
    if a:compilation ==# 'foreground'
        let bang_command = '!'
        if exists(':Dispatch')
            let bang_command = 'Spawn -wait=always -title=pytest '
        endif
        execute bang_command . &l:makeprg
        " Restore error format and working directory
        let &l:efm = old_efm
        execute 'lcd ' . l:save_pwd
    endif

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
        let coverage_start = 0
        for entry in qflist
            if entry.type ==# 'E'
                let coverage_end = index(qflist, entry) - 1
                break
            endif
        endfor
        call remove(qflist, coverage_start, coverage_end)
        call setqflist(qflist, 'r')
        silent! delmarks C
        return
    endif

    " If there are no errors get output text (i.e coverage report) and then
    " remove this output entries from the quickfix list (i.e empty qflist)
    for entry in qflist
        if match(entry.text, '^no tests ran\s*.') != -1
            " There is nothing to do in this case, therefore exit
            break
        endif
        if entry.valid == 0
            if s:is_win
                let entry.text = iconv(entry.text, 'latin1', 'utf-8')
            endif
            let output = add(output, entry.text)
            call remove(qflist, index(qflist, entry))
        endif
    endfor

    " We will show the coverage output inside the quickfix, so create a
    " container for it
    let cov_qflist = []

    " Add report as text to the quickfix (the key is to set the entry type to
    " something not valid)
    for line in output
        " Remove empty and not relevant lines
        if line ==# '' || line ==# '..'
            continue
        endif
        let entry = {}
        let entry.valid = 0
        let entry.text = line
        call add(cov_qflist, entry)
    endfor

    " Get file that called the tests using C mark
    let test_call_file = bufname(getpos("'C")[0])
    silent! delmarks C
    " Get root dir by looking for a tests dir
    let base_dir = ''
    let dir_level = ':p:h'
    for i in [1, 2, 3]
        let curr_dir = fnamemodify(test_call_file, dir_level)
        if isdirectory(curr_dir . '/tests')
            let base_dir = curr_dir
            break
        else
            let dir_level .= ':h'
        endif
    endfor

    " Get those lines with missing coverage and add them to the quickfix list
    " as valid entries (so we can jump directly to the line)
    let has_missing_lines = 0
    for line in output
        let entry = {}
        let entry.type = 'W'
        let missing_lines = matchstr(line, '\d\+%\s\+\zs\d*.*')
        if missing_lines !=# ''
            let has_missing_lines = 1
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

    " If there are no missing lines then we need to explicitly open the quickfix
    " window to see the coverage output; to do that we add fake valid empty
    " entry
    if has_missing_lines == 0
        let entry = {}
        let entry.valid = 1
        let entry.text = ''
        call add(cov_qflist, entry)
    endif

    if !empty(cov_qflist)
        " Set quickfix
        call setqflist(cov_qflist, 'r')
    endif
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
" REPL (neoterm) {{{

function! s:EnsureIpythonNeotermInstance()
    let term_buf_name = ''
    if g:neoterm.has_any()
        " If we alreay have a terminal buffer check if it has ipython
        " running
        let last_active_instance = g:neoterm.last()
        let buf_nr = last_active_instance.buffer_id
        if bufexists(buf_nr)
            let term_buf_name = bufname(buf_nr)
        endif
    endif
    if !g:neoterm.has_any() || term_buf_name !=# 'ipython'
        " This ensures we have an instance
        execute 'T ipython3'
        " Rename terminal buffer to ipython (note however that we cannot
        " use neoterm origin as winid because it's wrongly set)
        let last_active_instance = g:neoterm.last()
        let bufnr = last_active_instance.buffer_id
        let winid = win_findbuf(bufnr)[0]
        call win_gotoid(winid)
        keepalt file ipython
        wincmd p
    endif
endfunction

function! s:OpenREPL(repl)
    let old_size = g:neoterm_size
    let g:neoterm_size = 12
    if g:neoterm.has_any()
        " If an ipython instance exists jump to it
        let last_active_instance = g:neoterm.last()
        let buf_nr = last_active_instance.buffer_id
        if bufexists(buf_nr)
            let term_buf_name = bufname(buf_nr)
        endif
        if term_buf_name ==# 'ipython'
            let winid = win_findbuf(buf_nr)[0]
            call win_gotoid(winid)
        endif
        return
    endif
    botright Topen
    execute 'T ' .  a:repl
    keepalt file ipython
    let g:neoterm_size = old_size
endfunction

" Latest ipython doesn't allow to send multiple lines therefore we must add
" bracketed paste sequences to the text being sent to the interpreter
" See https://github.com/ipython/ipython/issues/9948
function! s:IPythonSelection()
    let [l:lnum1, l:col1] = getpos("'<")[1:2]
    let [l:lnum2, l:col2] = getpos("'>")[1:2]
    let l:lines = getline(l:lnum1, l:lnum2)
    let l:lines = s:Dedent(l:lines)
    let l:lines[-1] = l:lines[-1][:l:col2 - 1]
    let l:lines[0] = l:lines[0][l:col1 - 1:]
    let l:lines[0] = "\e[200~" . l:lines[0]
    let l:lines[-1] = l:lines[-1] . "\e[201~"
    call s:EnsureIpythonNeotermInstance()
    " The following avoids prepending `ipython` before the command which if ran
    " from within ipython results in an error
    let g:neoterm_auto_repl_cmd = 0
    call g:neoterm.repl.exec(l:lines)
endfunction

command! -range IPythonNeoterm silent call <SID>IPythonSelection()

function! s:IPyREPL() range
    let old_size = g:neoterm_size
    let old_autoinsert = g:neoterm_autoinsert
    let g:neoterm_size = 12
    let g:neoterm_autoinsert = 0
    IPythonNeoterm  " Instead of 'TREPLSendSelection'
    stopinsert
    let g:neoterm_size = old_size
    let g:neoterm_autoinsert = old_autoinsert
    call neoterm#repl#set('ipython')
endfunction

function! s:TmuxPdbDebugger(...)
    let visual_lines = s:Dedent(getline(a:1, a:2))
    let tmux_lines = []
    for l in visual_lines
        " Pdb only accepts a single line so trim starting indent spaces
        call add(tmux_lines, trim(l))
    endfor
    let tmux_text = shellescape(join(tmux_lines, ''), 1)
    " Assumes this is the max window in current session
    let pane_id = trim(system("tmux display-message -p '#{session_windows}'"))
    silent! execute '!tmux send-keys -t '. pane_id . ' ' . tmux_text | redraw!
endfunction
command! -range TmuxDebug silent call s:TmuxPdbDebugger(<line1>, <line2>)

" }}}
" Debugging {{{

function! s:AddBreakPoint()
    let save_cursor = getcurpos()
    let current_line = line('.')
    let breakpoint_line = current_line - 1
    let indent_length = match(getline(current_line), '\w')
    let indents = repeat(' ', indent_length)
    let bp_statement = 'breakpoint()'
    call append(breakpoint_line, indents . bp_statement)
    silent noautocmd update
    call setpos('.', save_cursor)
endfunction

function! s:RemoveBreakPoint()
    let save_cursor = getcurpos()
    execute 'g/breakpoint()/d'
    silent noautocmd update
    call setpos('.', save_cursor)
endfunction

function! s:ListBreakpoints(...)
    if !exists(':Denite')
        echoerr 'Denite plugin is needed to list breakpoints.'
        return
    endif
    lcd %:p:h
    if a:0 >=1 && a:1 ==# '.'
        let target = a:1
    else
        let target = expand('%')
    endif
    call denite#start([{'name': 'grep',
                \ 'args': [target, '--type python','breakpoint()']}])
endfunction

" }}}
" Pre-commit {{{

function! s:RunPreCommitHook()
    " Check if pre-commit is installed
    if !executable('pre-commit')
        echoerr 'pre-commit is not installed or not in your path.'
        return
    endif

    " Close qf and location list, save and change working directory
    cclose
    lclose
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Since pre-commit outputs relative paths will use a mark to find absolute
    " paths to be used in the quickfix later on
    silent! delmarks P
    silent execute 'mark P'

    " Set compiler
    let compiler = 'pre-commit run'

    " Set makeprg and error format when running make or Make (background
    " compilation)
    let &l:makeprg = compiler
    let old_efm = &l:efm
    setlocal errorformat=%f:%l:%c:%m

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        echon 'running bash with dispatch ...'
        " Make
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        return
    endif

    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

function! s:FixPreCommitQfPaths()
    " Only call this function after a pre-commit run
    let compiler = split(&makeprg, '')[0]
    if compiler !=# 'pre-commit'
        return
    endif

    " Get file that called the pre-commit using P mark
    let precommit_file = bufname(getpos("'P")[0])
    " Get root dir by looking for pre-commit.yaml file
    let precommit_yaml_file = '.pre-commit-config.yaml'
    let dir_level = ':p:h'
    let precommit_root = ''
    for i in [1, 2, 3]
        let curr_dir = fnamemodify(precommit_file, dir_level)
        if filereadable(expand(curr_dir . '/' . precommit_yaml_file))
            let precommit_root = curr_dir
            break
        else
            let dir_level .= ':h'
        endif
    endfor

    " Get current qflist and fix paths
    let qflist = getqflist()
    for entry in qflist
        if entry.valid == 1
            let file_tail =  bufname(entry.bufnr)
            let full_file_path = precommit_root . '/' . file_tail
            if filereadable(full_file_path)
                silent execute 'badd ' . full_file_path
                let entry.bufnr = bufnr(full_file_path)
            endif
        endif
    endfor
    call setqflist(qflist, 'r')

    silent! delmarks P
endfunction

augroup fix_pre_commit_paths_qf
    au!
    " We use cgetfile for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:FixPreCommitQfPaths()
augroup END

" }}}

" }}}
" Mappings {{{

" Anon snippets for triple quotes
if exists(':UltiSnipsEdit')
    inoremap <buffer> <silent> tq tq<C-R>=UltiSnips#Anon('"""${1:${VISUAL}}"""',
                \ 'tq', '', 'i')<CR>
endif

" Breakpoints
nnoremap <silent> <buffer> <Leader>bp :call <SID>AddBreakPoint()<CR>
nnoremap <silent> <buffer> <Leader>rb :call <SID>RemoveBreakPoint()<CR>
nnoremap <silent> <buffer> <Leader>lb :call <SID>ListBreakpoints('.')<CR>
nnoremap <silent> <buffer> <Leader>lB :call <SID>ListBreakpoints()<CR>
augroup ft_quickfix_py
    au!
    au Filetype qf nnoremap <silent> <buffer> <Leader>rB
        \ :cdo g/breakpoint()/d<bar>silent noautocmd update<CR>:cclose<CR><C-o>
augroup END

" Background compilation
nnoremap <silent> <buffer> <F7> :call
            \ <SID>RunPython('python3', 'normal', 'background', 0)<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunPython('python3', 'normal', 'background', 0)<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualPyBackground python3<CR>
" Foreground compilation
nnoremap <silent> <buffer> <Leader>rf :call
            \ <SID>RunPython('python3', 'normal', 'foreground', 0)<CR>
vnoremap <silent> <buffer> <Leader>rf :EvalVisualPyVimshell python3<CR>
if executable('ipython') || executable('ipython3')
        nnoremap <silent> <buffer> <Leader>ri :call
            \ <SID>RunPython('ipython3', 'normal', 'foreground', 0)<CR>
        vnoremap <silent> <buffer> <Leader>ri :call <SID>IPyREPL()<CR>
endif
" Run in the command line (useful when input is required)
nnoremap <silent> <buffer> <F5> :call
            \ <SID>RunPython('python3', 'normal', 'foreground_os', 0)<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunPython('python3', 'normal', 'foreground_os', 0)<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualPyForeground python3<CR>
" Debugger run
nnoremap <silent> <buffer> <F6> :call
            \ <SID>RunPython('python3', 'normal', 'foreground_os', 1)<CR>
inoremap <silent> <buffer> <F6> <ESC>:call
            \ <SID>RunPython('python3', 'normal', 'foreground_os', 1)<CR>
vnoremap <silent> <buffer> <F6> :EvalVisualPyDebug python3<CR>
" Send line to tmux pdb
vnoremap <silent> <buffer> <Leader>td :TmuxDebug<CR>
" Load traceback from tmux window
nnoremap <buffer> <Leader>lt :LoadTraceFromTmux<space>

" Linting, formatting and import sorting
nnoremap <silent> <buffer> <Leader>rl :Neomake<CR>
nnoremap <buffer> <silent> <Leader>is :call <SID>RuniSort()<CR>
" Note: The visual map messes up proper comment indentation/formatting:
vnoremap <silent> <buffer> Q :call <SID>RunBlack('visual')<CR>
nnoremap <silent> <buffer> <Leader>fc :call <SID>RunBlack()<CR>

" Tests and coverage (py.test dependant)
nnoremap <buffer> <Leader>pts :call <SID>RunPyTest('suite', 'background')<CR>
nnoremap <buffer> <Leader>Pts :call <SID>RunPyTest('suite', 'background', 1)<CR>
nnoremap <buffer> <Leader>ptf :call <SID>RunPyTest('file', 'background')<CR>
nnoremap <buffer> <Leader>Ptf :call <SID>RunPyTest('file', 'foreground')<CR>
nnoremap <buffer> <Leader>ptc :call <SID>RunPyTest('class', 'background')<CR>
nnoremap <buffer> <Leader>Ptc :call <SID>RunPyTest('class', 'foreground')<CR>
nnoremap <buffer> <Leader>ptm :call <SID>RunPyTest('method', 'background')<CR>
nnoremap <buffer> <Leader>Ptm :call <SID>RunPyTest('method', 'foreground')<CR>
nnoremap <buffer> <silent> <Leader>rt :call
            \ <SID>RunPyTest('suite', 'foreground')<CR>
nnoremap <buffer> <silent> <Leader>rT :call
            \ <SID>RunPyTest('suite', 'foreground', 1)<CR>
nnoremap <buffer> <silent> <Leader>et :call <SID>EditTestFile()<CR>

" (Open) and run visual selection in the interpreter (in neovim terminal) and
" ipython
if exists(':Topen')
    nnoremap <buffer> <silent> <Leader>oi :call <SID>OpenREPL('python3')<CR>
    if executable('ipython') || executable('ipython3')
        nnoremap <buffer> <silent> <Leader>ip :call
            \ <SID>OpenREPL('ipython3')<CR>
        nnoremap <buffer> <silent> <Leader>tr
            \ :T %reset -f<CR><ESC>
            \ :call neoterm#clear({})<CR><ESC>
    endif
endif

" Documentation
nnoremap <buffer> <silent> <S-k> :call <SID>PyDoc()<CR>

" View PDF figure
nnoremap <buffer> <silent> <Leader>vp :call <SID>ViewPdfFigure()<CR>

" View module source code
nnoremap <buffer> <silent> <Leader>vm :call <SID>ViewPyModule()<CR>

" Close output buffer
nnoremap <buffer> <silent> <Leader>oc :silent! bdelete python_output<CR>

" Commit hook
nnoremap <buffer> <silent> <Leader>rh :call <SID>RunPreCommitHook()<CR>

" }}}
