" TODO: Include loaded files when running a visual selection
" TODO: Run matlab from neovim terminal? Not possible on Windows
" TODO: Completion similar to jedi with neocomplete?
" TODO: Use one matlab instance instead of creating a new one each time

" Installation notes {{{

" This file has been tested and works with Matlab R2015a

" We added C:/OD/OneDrive/programming/Matlab/libraries (and its subfolders) to
" our search path:
    " addpath(genpath('C:/OD/OneDrive/programming/Matlab/libraries'))
" Re-run this command whenever adding a new library/toolbox

" Compilation:
" In order to compile we need to add the bin folder to path
" Note that matlab files cannot contain spaces (directories, on the other hand,
" may contain spaces)

" This script uses a function defined in our search path, getReportFullPath,
" which returns full paths of those files in the stack trace (instead of just
" the file name). This function file (.m file) must be included in your Matlab
" search path. In our case it is located in:
    " C:/OD/OneDrive/programming/Matlab/libraries/vim-compilation

" To keep focus on Vim, on Windows, we use an autohotkey script located in:
" C:/OD/OneDrive/programming/Matlab/libraries/vim-compilation/activate_vim.ahk

" Mlint:
" To use the linter (mlint) we also need to add the bin/win64 folder to path.
" To catch unused/unset variables, in the linter preferences (Preferences ->
" Code Analyzer) enable:
    " The value assigned to variable <name> but might be unused (within a ...)
    " Variable <name> is used, but might be unset (within a script)
" Note that mlint cannot determine if a variable is undefined (at least with
" R2015a). Code Analyzer can't determine this either since setting:
    " Code Analyzer cannot determine whether <name> is a variable or ...
" gives warnings about built-in functions!

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice (we use b:did_ftplugin to
" override matlab ftplugin file in vim runtime directory)
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

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

" Editing
setlocal comments=:%>,:%

" When searching with gf include matlab files
setlocal suffixesadd=.m

" For matchit plugin
if exists('loaded_matchit')
    let s:conditional_end = '\([-+{\*\:(\/]\s*\)\@<!\<end\>'.
                \ '\(\s*[-+}\:\*\/)]\)\@!'
    let b:match_words = '\<\%(if\|switch\|for\|while\|try\|function\|' .
                \ 'classdef\)\>:\<\%(elseif\|case\|break\|continue\|else\|' .
                \ 'otherwise\|catch\)\>:'. s:conditional_end
    unlet s:conditional_end
endif

" Define folder containg getReportFullPath function and autohotkey script
let s:vim_matlab_search_path_dir = expand($CLOUD . '/programming/Matlab/' .
            \ 'libraries/vim-compilation/')

" }}}
" Compiling {{{

" TODO: Jump to file (from command window ) when compiling without exiting?
function! s:RunMatlab(mode, jvm_exit, ...)
    " Check if matlab is installed
    if s:is_win
        if !executable('matlab')
            echoerr 'Matlab is not installed or not in your path.'
            return
        endif
    elseif s:is_mac
        if !isdirectory('/Applications/MATLAB_R2015b.app/bin/')
            return
        endif
    endif

    " Place an uppercase mark at beginning of visual selection so we get the
    " correct line numbers in the quickfix later
    if a:mode ==# 'visual' && a:0 >= 1 && strlen(a:1)
        silent execute a:1 . ' mark V'
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Define current matlab file
    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file with visual content
        let current_file = expand('%:t:r') . '_tmpvisual.m'
        let lines = getline(a:1, a:2)
        call writefile(lines, current_file)
    else
        let current_file = expand('%:p')
    endif
    " Set log file to write output
    let log_file = fnamemodify(current_file, ':r') . '.log'

    " We now define matlab three different compilation methods
    " Generally we want to disable java virtual machine (since compilation is
    " faster), wait for compilation to finish, exit once it does and save output
    " to a logfile (that might contain spaces in path hence the double quotes)
    let jvm_flag = '-nojvm '
    let wait_flag = '-wait '
    let exit_command = ';exit'
    let m_logfile = '-logfile "' . log_file . '"'
    " If we plot figures we need to enable java virtual (we tried to speed this
    " up setting a MATLAB_JAVA env variable pointing to jre path it doesn't
    " make much difference)
    if a:jvm_exit ==# 'jvm'
        let jvm_flag = ''
        " When plotting figures we only want to exit when all figure windows are
        " closed
        let exit_command = ';while ~isempty(findall(0,''Type'',''Figure''));' .
                    \ 'pause(0.01);drawnow;end;exit'
    " If we don't want to exit the command window we also don't want to wait or
    " to create a log file
    elseif a:jvm_exit ==# 'noexit'
        let wait_flag = ''
        " let jvm_flag = ''
        let exit_command = ''
        let m_logfile = ''
        if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
            " When running a visual selection without exiting, delete temp file
            let exit_command = ';delete(''' . current_file . ''')'
        endif
    endif
    " In all three cases when running a script we want to catch errors (note
    " that we use run() which is a convenience function that runs scripts that
    " are not currently on the path) using a function defined in our search
    " path, getReportFullPath, which returns full paths of those files in the
    " stack trace (instead of just the file name)
    let try_run_catch = 'try;run(''' .  current_file .
                \ ''');catch ME;disp(getReportFullPath(ME));end'

    " FIXME: Vim loses focus when matlab cmd window opens
    " A partial solution on Windows is first to use autohotkey to restore vim
    " focus (however we still lose focus for a few seconds while matlab loads)
    let restore_focus = ''
    if s:is_win
        let ahk_script = s:vim_matlab_search_path_dir . 'activate_vim.ahk'
        if filereadable(ahk_script)
            let restore_focus = 'system(''' . ahk_script . ''');'
        endif
    endif

    " Set uft-8 encoding (this makes the log file latin1 instead of utf-8 hence
    " forcing us to use read instead of append but allows to have utf-8
    " characters in plots)
    let encoding = 'feature(''DefaultCharacterSet'', ''utf-8'');'

    " Construct makeprg from the above flags and matlab commands
    let flags = '-nodisplay -nodesktop -nosplash -minimize ' . wait_flag .
                \ jvm_flag . m_logfile
    let matlab_commands = restore_focus . encoding . try_run_catch .
                \ exit_command
    let &l:makeprg = 'matlab ' . flags . ' -r "' . matlab_commands . '"'


    " Set error format (don't catch any output)
    let old_efm = &l:efm
    setlocal efm=%-G%.%#

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchnone because Dispatch removes it
        let &l:efm = &efm . ',%-G%.%#'
        echon 'running matlab with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running matlab with make...'
        silent make!
    endif

    " Restore error format and return to previous working directory
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

" Define commands to run visual selection
command! -range EvalVisualMat
            \ call s:RunMatlab('visual', 'nojvm', <line1>, <line2>)
command! -range EvalVisualMatFig
            \ call s:RunMatlab('visual', 'jvm', <line1>, <line2>)
command! -range EvalVisualMatNoExit
            \ call s:RunMatlab('visual', 'noexit', <line1>, <line2>)

" }}}
" Output/Errors {{{

function! s:ShowMatOutputOrError()
    " Only call this function after a matlab run or when we are not retrieving
    " documentation
    if split(&makeprg, '')[0] !=# 'matlab' || match(&makeprg, 'disp(help') != -1
        return
    endif
    " When we are explicitly exiting after a run suggest checking the command
    " window for output and then exit
    if match(&makeprg, ');end\"$') != -1 || match(&makeprg, 'delete(') != -1
        redraw
        unsilent echo 'Check Matlab Command Window for output'
        return
    endif

    " Close/delete previous output preview window buffer and quickfix
    silent! pclose
    silent! bdelete Matlab_output
    cclose

    " Get matlab file and log from makeprg (note that the logfile path is
    " surrounded by double quotes)
    let log_file = matchstr(&makeprg, 'logfile\s\"\zs.*.log\ze')
    let current_file = fnamemodify(log_file, ':r') . '.m'

    " Also get base file name (without .m extension) and directory in order to
    " obtain proper traceback (note that we want the base_file of a visual
    " selection to include  _tmpvisual since we afterwards compare file names in
    " order to get proper traceback)
    let base_file = fnamemodify(log_file, ':t:r')
    let base_dir = fnamemodify(log_file, ':p:h')

    " If the file was run from a visual selection delete temp file
    if match(current_file, '_tmpvisual') != -1
        call delete(current_file)
    endif

    " Get output from logfile but remove first four lines with Matlab message
    let output = readfile(log_file)
    let output = output[4:]

    " If there is no output delete the logfile and exit
    let height = len(output)
    if height == 0
        silent! call delete(log_file)
        redraw
        unsilent echo 'No (printable) Matlab output'
        return
    endif

    " Initiate quickfix and warning lines list
    let qflist = []
    let warn_lines = []

    " When running a visual selection get the correct file and line number
    " (using the V mark to define line number offset)
    let buf_nr_m_file = bufnr(current_file)
    let correct_lnum = 0
    if match(current_file, '_tmpvisual') != -1
        let correct_file = join(split(current_file, '_tmpvisual'), '')
        let buf_nr_m_file = bufnr(correct_file)
        let correct_lnum = line("'V") - 1   " Fixes line numbers
        " Finally delete visual mark since it is not needed anymore
        silent! delmarks V
    endif

    for item in output
        " Each element of the qflist is a dictionary
        let entry = {}


        " The first type of error are compile-time errors and have the following
        " form:
            " Error: File: full_path Line: line_nr Column: col_nr
            " Error message
        " If the error is in a function file then it appears as:
            " Error: File: full_path function_file Line: line_nr Column: col_nr
            " Error message
            " blank line
            " Error in full_path base_file (line line_nr)
            " contents of line_nr
        " Note that this type of errors are generally syntax errors and will
        " most likely be detected by the linter
        if match(item , '^Error:') != -1
            let entry.bufnr = buf_nr_m_file
            let entry.lnum = str2nr(matchstr(item, 'Line:\s\zs\d\+\ze')) +
                        \ correct_lnum
            " If the error is in a function file we need to get the correct
            " buffer number
            let error_file = matchstr(item, 'File:\s\zs\S\+\ze')
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
                let entry.lnum = str2nr(matchstr(item, 'Line:\s\zs\d\+\ze'))
            endif
            let entry.col = matchstr(item, 'Column:\s\zs\d\+\ze')
            let entry.type = 'E'
            let entry.text = output[index(output, item) + 1]
            " Add this entry, get traceback up to the current file and break the
            " for loop
            call add(qflist, entry)
            call s:GetErrorTraceBack(output, item, base_file, error_file,
                        \ error_base_file, buf_nr_m_file, correct_lnum, qflist)
            break


        " The second type of errors are runtime errors and have the following
        " form:
                " Error using full_path file (line line_nr)
                " Error message
        elseif match(item, '^Error\susing\s\S*\s(line') != -1
            let entry.bufnr = buf_nr_m_file
            let entry.lnum = str2nr(matchstr(item, 'line\s\zs\d\+\ze')) +
                        \ correct_lnum
            let error_file = matchstr(item, 'Error\susing\s\zs\S\+\ze')
            let error_base_file = fnamemodify(error_file, ':t:r')
            if error_base_file !=# base_file
                let entry.bufnr = bufnr(error_file)
                if entry.bufnr == -1 && filereadable(error_file)
                    silent execute 'badd ' . error_file
                    let entry.bufnr = bufnr(error_file)
                endif
                let entry.lnum = str2nr(matchstr(item, 'line\s\zs\d\+\ze'))
            endif
            let entry.type = 'E'
            let entry.text = output[index(output, item) + 1]
            call add(qflist, entry)
            call s:GetErrorTraceBack(output, item, base_file, error_file,
                        \ error_base_file, buf_nr_m_file, correct_lnum, qflist)
            break


        " The third type of errors (which are also runtime errors) have the
        " following form:
                " Error message (starting as '{^H')
                " blank line
                " Error in full_path filename (line line_nr)
        " It is also possible that this type of errors are shown as
                " Error using some_operator
                " Error message (starting as '{^H')
                " blank line
                " Error in full_path filename (line line_nr)
        " Note that in this case the `Error using` line doesn't have a line nr
        " or a full path
        elseif match(item, '^Error\sin') != -1
            let entry.bufnr = buf_nr_m_file
            let entry.lnum = str2nr(matchstr(item, 'line\s\zs\d\+\ze')) +
                        \ correct_lnum
            let error_file = matchstr(item, 'Error\sin\s\zs\S\+\ze')
            let error_base_file = fnamemodify(error_file, ':t:r')
            if error_base_file !=# base_file
                let entry.bufnr = bufnr(error_file)
                if entry.bufnr == -1 && filereadable(error_file)
                    silent execute 'badd ' . error_file
                    let entry.bufnr = bufnr(error_file)
                endif
                let entry.lnum = str2nr(matchstr(item, 'line\s\zs\d\+\ze'))
            endif
            let entry.type = 'E'
            " Check if the error message starts with 'Error using' and change
            " the error message text accordingly
            let error_ind = index(output, item)
            if (error_ind - 2) != 0 &&
                        \ match(output[error_ind - 3], '^Error using') != -1
                let entry.text = output[error_ind - 3] . ': ' .
                            \ output[error_ind - 2]
            else
                let entry.text = output[error_ind - 2]
            endif
            call add(qflist, entry)
            call s:GetErrorTraceBack(output, item, base_file, error_file,
                        \ error_base_file, buf_nr_m_file, correct_lnum, qflist)
            break


        " Finally there might be multiple warnings (on the other hand errors
        " are unique since Matlab halts when it finds one)
                " Warning: warning message.
                "> In file at line_nr
        " Since we can have multiple warnings with the same warning message
        " we need to get the correct line number first.
        " Note we don't match at the beginning of the line because of the ^{H
        " character
        " Also note that for Warnings we DON'T have full paths
        elseif match(item, '>\sIn') != -1
            let line_nr = matchstr(item, 'line\s\zs\d\+\ze')
            let war_line_nr_ind = index(output, item)
            if match(output[war_line_nr_ind - 1], 'Warning:') != -1
                let entry.bufnr = buf_nr_m_file
                let entry.lnum = str2nr(line_nr) + correct_lnum
                let error_base_file = matchstr(item, 'In\s\zs\w\+\ze')
                if error_base_file !=# base_file
                    let correct_error_file = base_dir . '/' . error_base_file .
                                \ '.m'
                    let entry.bufnr = bufnr(correct_error_file)
                    if entry.bufnr == -1 && filereadable(correct_error_file)
                        silent execute 'badd ' . correct_error_file
                        let entry.bufnr = bufnr(correct_error_file)
                    endif
                    let entry.lnum = str2nr(line_nr)
                endif
                let entry.type = 'W'
                let entry.text = matchstr(output[war_line_nr_ind - 1],
                            \ 'Warning:\s\zs.*\.\ze')
                " Since we don't have full paths, if there is a warning in a
                " file outside of the current folder (for instance in a builtin
                " matlab function) its buffer number will be -1 and Vim will
                " exit with an error if we include this entry in the quickfix
                " list. Therefore we only add entries to the quickfix list with
                " valid buffer numbers
                if entry.bufnr != -1
                    call add(qflist, entry)
                endif

                " Get traceback up to the current file (now we cannnot use our
                " GetErrorTraceBack function because the structure is different)
                let distance = 1
                while error_base_file != base_file
                    let new_entry = {}
                    let new_item = output[war_line_nr_ind + distance]
                    let new_entry.bufnr = buf_nr_m_file
                    let new_entry.lnum = str2nr(matchstr(new_item,
                                \ 'line\s\zs\d\+\ze')) + correct_lnum
                    let error_base_file = matchstr(new_item,
                                \ 'In\s\zs\w\+\ze')
                    if error_base_file !=# base_file
                        let correct_error_file = base_dir . '/' .
                                    \ error_base_file . '.m'
                        let new_entry.bufnr = bufnr(correct_error_file)
                        if new_entry.bufnr == -1 &&
                                    \ filereadable(correct_error_file)
                            silent execute 'badd ' . correct_error_file
                            let new_entry.bufnr = bufnr(correct_error_file)
                        endif
                        let new_entry.lnum = str2nr(matchstr(new_item,
                                \ 'line\s\zs\d\+\ze'))
                    endif
                    let new_entry.type = 'W'
                    let new_entry.text = ''
                    if new_entry.bufnr != -1
                        call add(qflist, new_entry)
                    endif
                    let distance = distance + 1
                endwhile
                " Remove this warnings lines from output because when there are
                " warnings we show both the quickfix and the output buffer
                call remove(output, war_line_nr_ind - 1,
                            \ war_line_nr_ind + distance)
                " Since we use read instead of append we need to save this line
                " numbers (accounting for the fact that lists are zero based) to
                " delete them once we dump (read) the file into the output
                " buffer
                call add(warn_lines, [(war_line_nr_ind - 1) + 1,
                            \ (war_line_nr_ind + distance) + 1])
            endif
            " Note that we don't break the for loop here

        " End possible cases
        endif
    " End looping over output lines
    endfor

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
        wincmd p  " Return to previous window

        " If there are errors we want to exit without displaying any output
        " buffer but first deleting the log file
        for entry in qflist
            if entry.type ==# 'E'
                silent! call delete(log_file)
                return
            endif
        endfor

        " If there are warnings we do want to display the output buffer along
        " with the quickfix window unless the height of the output buffer is 0
        " (because this means we have warnings without output so we also return
        " after opening the quickfix window)
        if height == 0
            silent! call delete(log_file)
            return
        endif
    endif

    " If there are no errors create a buffer to dump output
    execute 'silent botright new Matlab_output'
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight previewwindow

    " Read the log file but ignore the first four lines with Matlab message
    " (note that we don't use append because the log file is encoded in latin1
    " while readfile (and therefore append) use utf-8 encoding which means
    " that spanish characters won't we properly displayed)
    execute 'read ++edit ' . log_file
    execute '1,4delete'

    " Remove log file since we don't need it anymore
    silent! call delete(log_file)

    " Delete extra line at the end (only if it's empty), at the beginning and
    " remove extra indent
    if getline(line('$')) ==# ''
        silent normal! Gdd
        let height = height - 1
    endif
    silent normal! ggdd
    silent normal! gg<G

    " Remove warning lines (if any)
    if !empty(warn_lines)
        for range in warn_lines
            execute range[0] . ',' . range[1] . 'delete'
        endfor
    end

    " Resize the buffer height
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'

    " If there is a quickfix window we want to place it below the output window:
    " Return to previous window (not working in async mode when delete file
    " works?) and get its window number
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

function! s:GetErrorTraceBack(output, item, base_file, error_file,
            \ error_base_file, buf_nr_m_file, correct_lnum, qflist)
    " If the error is in a file other than the current file then we want a
    " traceback up to the current file.
    " Note that we might have recursive function calls:
        " Error in full_path function_file (line line_nr)
        " Error message
        " blank line
        " Error in full_path another_function_file (line line_nr)
        " contents of line_nr
        " blank line
        " Error in full_path base_file (line line_nr)
        " contents of line_nr
    let distance = 1
    let fix_blank = 0
    let base_index = index(a:output, a:item)
    let error_base_file = a:error_base_file
    while error_base_file !=# a:base_file
        let new_entry = {}
        let new_item = a:output[base_index + (3 * distance) + fix_blank]
        " Note that this new item might be a blank line so we need first to
        " check if it starts with `Error in` and, if not, update the distance
        " accordingly (try print(2))
        while match(new_item, '^Error\sin') == -1
            let fix_blank = fix_blank + 1
            let new_item = a:output[base_index + (3 * distance) + fix_blank]
        endwhile
        let new_entry.bufnr = a:buf_nr_m_file
        let new_entry.lnum = str2nr(matchstr(new_item,
                    \ 'line\s\zs\d\+\ze')) + a:correct_lnum
        let error_file = matchstr(new_item, 'Error\sin\s\zs\S\+\ze')
        let error_base_file = fnamemodify(error_file, ':t:r')
        if error_base_file !=# a:base_file
            let new_entry.bufnr = bufnr(error_file)
            if new_entry.bufnr == -1 && filereadable(error_file)
                silent execute 'badd ' . error_file
                let new_entry.bufnr = bufnr(error_file)
            endif
            let new_entry.lnum = str2nr(matchstr(new_item,
                    \ 'line\s\zs\d\+\ze'))
        endif
        let new_entry.type = 'E'
        let new_entry.text = a:output[base_index + ((3 * distance) + fix_blank
                    \ + 1)]
        call add(a:qflist, new_entry)
        let distance = distance + 1
    endwhile
endfunction

augroup show_mat_output_errors
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowMatOutputOrError()
augroup END

" }}}
" Linting {{{

function! s:SetMEfm()
    setlocal errorformat=\L\ %l\ (C\ %c):\ %m
    setlocal errorformat=+\L\ %l\ (C\ %c-%*[0-9]):\ %m
endfunction

" FIXME: Check for undefined variables; NO FIX
function! s:Mlint()
    " Don't run mlint if it is not installed or if there is only one empty line
    if !executable('mlint')
        echoerr 'mlint is not installed or not in your path.'
        return
    endif
    if line('$') == 1 && getline(1) ==# ''
        return
    endif
    " Don't try to run lint from a Gdiff (when file path includes .git)
    if expand('%:p') =~# "/\\.git/"
        return
    endif

    " Close qf, save working directory and get current file
    cclose
    let save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Set compiler and error format
    let compiler = 'mlint '
    let &l:makeprg = compiler . current_file
    let old_efm = &l:efm
    call s:SetMEfm()

    " Mlint is fast enough to be run with regular make so we don't use Dispatch
    " even when it might be available
    echon 'running mlint ...'
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
        unsilent echo 'Finished mlint successfully.'
    endif

    " Restore error format and return to previous working directory
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

function! s:ParseMlintAddSemiColon()
    " Only call this function after a mlint run
    if split(&makeprg, '')[0] !=# 'mlint'
        return
    endif

    " If there are no errors/warnings return
    let qflist = getqflist()
    if empty(qflist)
        return
    endif

    " Get the matlab file buffer number from the makeprg
    let mat_file_buf_nr = bufnr(split(&makeprg, '')[1])

    " Correct the quick fix using the information in the mlint
    " message
    for entry in qflist
        let mlint_message = get(entry, 'text', '')
        let entry.bufnr = mat_file_buf_nr
        let entry.lnum = matchstr(mlint_message, 'L\s\zs\d\+\ze')
        let entry.col = matchstr(mlint_message, 'C\s\zs\d\+\ze')
        let entry.text = matchstr(mlint_message, ':\s\zs.*')
    endfor

    " Get those lines that should end with a semicolon and remove them from the
    " quickfix list since we will (consecutively) add that missing semicolon and
    " can therefore ignore this warning
    let missing_semi_colons = []
    for entry in qflist
        if match(entry.text, '^Terminate') != -1
            call add(missing_semi_colons, entry.lnum)
            call remove(qflist, index(qflist, entry))
        endif
    endfor
    " Indeed add missing semicolons
    if !empty(missing_semi_colons)
        let save_cursor = getcurpos()
        for lnum in missing_semi_colons
            execute lnum . 'normal! A;'
        endfor
        call setpos('.', save_cursor)
    endif

    " Finally replace qflist
    call setqflist(qflist, 'r')
endfunction

" Automatically run mlint on save
augroup m_linting
    au!
    au BufWritePost *.m call s:Mlint()
    " We only use regular make sinc mlint is fast enough
    au QuickFixCmdPost make call s:ParseMlintAddSemiColon()
augroup END

" }}}
" Docs {{{

function! s:GetMatDoc()
    " Check if matlab is installed
    if !executable('matlab')
        echoerr 'Matlab is not installed or not in your path.'
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h
    let working_dir = expand('%:p:h')

    " Set log file to write output
    let current_file = expand('%:p')
    let log_file = fnamemodify(current_file, ':r') . '.log'

    " Search for word under the cursor or ask for object
    let object = expand('<cword>')
    if empty(object)
        let object = input('Enter object to view doc: ')
        if empty(object) && a:0 < 1
            redraw!
            return
        endif
    endif
    " Redraw to remove command line text
    redraw!

    " Delete previous doc buffer
    silent! bdelete Matlab_doc

    " Set compiler
    let flags = '-nodisplay -nodesktop -nosplash -wait -nojvm -minimize '
    let m_logfile = '-logfile "' . log_file . '"'
    let help_command ='"disp(help(''' . object . '''));exit"'
    let &l:makeprg = 'matlab ' . flags . m_logfile . ' -r ' . help_command

    " Set error format (don't catch any output)
    let old_efm = &l:efm
    setlocal efm=%-G%.%#

    " Use regular make to get the doc info
    echon 'Searching for `' . object . '` in Matlab docs ...'
    silent make!

    " Restore error format and return to previous working directory
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

function! s:ParseMatDoc()
    " Only call this function after a matlab run that retrieves documentation
    let makeprg_string = &makeprg
    if split(makeprg_string, '')[0] !=# 'matlab' ||
                \ match(makeprg_string, 'disp(help') == -1
        return
    endif

    " Get and log file and object from makeprg
    let log_file = matchstr(makeprg_string, 'logfile\s\"\zs.*.log\ze')
    let object =  matchstr(makeprg_string, 'help(''\zs.*\ze'')')

    " Get output from logfile but remove first four lines with Matlab message
    let output = readfile(log_file)
    let output = output[4:]
    " Remove log file since we don't need it anymore
    silent! call delete(log_file)

    " If there is no output it means there was an error (which we, on purpose,
    " didn't catch) stating that no documentation was found
    let height = len(output)
    if height == 0
        redraw!
        echohl Error
        unsilent echo 'No Matlab doc found for `' . object . '`'
        echohl none
        return
    endif

    " If there is documentation remove lines beginning with `Overloaded methods`
    " (which 4 preceding spaces)
    let overloaded_index = index(output, '    Overloaded methods:')
    if overloaded_index >= 0
        let output = output[:overloaded_index - 1]
    endif
    " Add blank line after the first line (title of the doc)
    let output = insert(output, '', 1)

    " Now create a buffer output
    execute 'silent botright new Matlab_doc'

    " Actually dump the output
    call append(line('$'), output)

    " Delete extra line at the end (only if it's empty), at the beginning,
    " remove extra indent and set buffer to nonmodifiable
    if getline(line('$')) ==# ''
        silent normal! Gdd
        let height = height - 1
    endif
    silent normal! ggdd
    silent normal! gg<G
    setlocal nomodifiable nomodified

    " Resize the buffer height
    let height = len(output)
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'

    " Mappings to jump to tags, search for another object and exit buffer
    nnoremap <silent> <buffer>  <C-]> :call <SID>GetMatDoc()<CR>
    nnoremap <silent> <buffer> K :call <SID>GetMatDoc()<CR>
    nnoremap <silent> <buffer> Q :bd!<CR>
endfunction

augroup show_mat_doc
    au!
    au QuickFixCmdPost make call s:ParseMatDoc()
augroup END

" }}}
" Miscellaneous {{{

" Open Command Window {{{

" Function to open matlab interpreter
function! s:OpenMatConsole()
    let flags = '-nodisplay -nodesktop -nosplash'
    let mat_exe = 'matlab '
    execute '!start /b ' . mat_exe . flags
endfunction

" }}}
" Jump to tag or file {{{

if !exists('*s:JumpMatTagOrFile')
    function! s:JumpMatTagOrFile()
        " Get object under the cursor and cursor position
        let object = expand('<cword>')
        let cursor_pos = getpos('.')

        " If we have Unite tag source and Neoinclude use it; otherwise use
        " regular tags
        if exists(':NeoIncludeMakeCache') && exists(':Unite') &&
                    \ !empty(unite#get_all_sources('tag/include'))
            execute 'NeoIncludeMakeCache'
            execute 'UniteWithCursorWord -immediately -sync ' .
                        \ '-default-action=context_split tag/include'
        else
            silent! execute 'tag ' . object
        endif

        " If the cursor didn't move this means that no tag was found so we try
        " to search for the file using gf mapping (go to file)
        if getpos('.') == cursor_pos
            try
                if winwidth(0) <= 2 * (&tw ? &tw : 80)
                    wincmd f
                else
                    vertical wincmd f
                endif
            catch
                " If no file was found then give an error message (instead of
                " catching the error we could have again checked if the cursor
                " moved)
                echohl Error
                echon 'No tag or file found matching `' . object . '`.'
                echohl none
            endtry
        endif
    endfunction
endif

" }}}
" View (PDF) figure {{{

function! s:ViewPdfFigure()
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Construct the pdf file full path (get a base filename from the first
    " argument of export_fig function, remove possible extension and search
    " downwards in the current directory for a pdf file with that name)
    let search_path = expand('%:p:h') . '/**'
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

" (Background) Compilation
nnoremap <silent> <buffer> <F7> :call <SID>RunMatlab('normal', 'nojvm')<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunMatlab('normal', 'nojvm')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualMat<CR>
" Compilation with figures
nnoremap <silent> <buffer> <Leader>rf :call <SID>RunMatlab('normal', 'jvm')<CR>
vnoremap <silent> <buffer> <Leader>rf :EvalVisualMatFig<CR>
" Compilation without exiting
nnoremap <silent> <buffer> <F5> :call <SID>RunMatlab('normal', 'noexit')<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunMatlab('normal', 'noexit')<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualMatNoExit<CR>

" Linter
nnoremap <silent> <buffer> <Leader>rl :call <SID>Mlint()<CR>

" Open Matlab Command Window
nnoremap <silent> <buffer> <Leader>oc :lcd %:p:h<CR>:call
            \ <SID>OpenMatConsole()<CR>

" Documentation
nnoremap <silent> <buffer> <S-k> :call <SID>GetMatDoc()<CR>

" Tags
nnoremap <buffer> <silent> <C-]> :call <SID>JumpMatTagOrFile()<CR>

" View PDF figure
nnoremap <buffer> <silent> <Leader>vp :call <SID>ViewPdfFigure()<CR>

" }}}
