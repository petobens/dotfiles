" TODO: Close figure window with x button (without need of using locator(1))
" TODO: Better completion with Vim-R plugin and eventually with neocomplete
" TODO: Add function to view R source code of an object or library?

" Installation notes {{{

" On Windows we need to add the following to Path variable in order to compile R
" code: C:\prog-lang\R\R-version_nr\bin

" In order to install packages without administrative rights we need to give
" permissions to the user to read a write the library folder of the R
" installation: C:\prog-lang\R\R-version_nr\library
" On the other to install new packages in another location, add the following
" environmental (system) variable and check it is the first directory listed by
" `.libPaths()`: R_LIB = C:\prog-lang\R\libraries

" To see the docs in nice markdown format we need pandoc

" We install the following R packages (and their dependencies):
" devtools, lintr, plm, lmtest, gridExtra, gtable

" We use the vim-R-plugin for completion which in turns requires the vimcom
" library. For this to work we need to place (via a symlink) the Rprofile file
" in the Users/Documents folder

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_settings_for_R')
    finish
endif
let b:my_settings_for_R = 1

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

function! s:RunR(mode, compilation, ...)
    " Check if R is installed
    if !executable('R')
        echoerr 'R is not installed or not in your path.'
        return
    endif

    " Place uppercase marks at i) the beginning of visual selection and ii)
    " counting how many lines there are importing modules in order to compute
    " correct line numbers in the quickfix later
    silent! delmarks V L   " Delete previous marks
    if a:mode ==# 'visual' && a:0 >= 1 && strlen(a:1)
        let libraries = s:GetLibraries()
        let library_lines = libraries[0]
        let last_library_line = libraries[2]
        if last_library_line > 0
            " Only set a mark for libraries if libraries are indeed loaded
            silent execute last_library_line . ' mark L'
        endif
        silent execute a:1 . ' mark V'
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update
    cclose
    lclose
    " Change directory
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Set working directory and file to run with the compiler (note that we
    " don't use the full path for the file since we change the working directory
    " before sourcing an R file)
    let working_dir = expand('%:p:h')
    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file in the current directory with visual content. Since R
        " can have two possible extensions (R and r) we need to provide the
        " proper extension for the visual file
        let current_file_ext = expand('%:e')
        let current_file = expand('%:t:r') . '_tmpvisual.' . current_file_ext
        let visual_lines = getline(a:1, a:2)
        let lines = library_lines + visual_lines
        call writefile(lines, current_file)
    else
        let current_file = expand('%:t')
    endif

    " Define R flags and commands
    " We use '--slave' to make R run as quiet as possible,  '--no-save' to avoid
    " asking if we want to save the workspace, '--no-restore' to avoid loading a
    " saved image from the workspace and '-e' to execute a command an exit.
    let flags = '--slave --no-save --no-restore -e '
    " Force warnings to become errors?
    " let error_options = 'options(show.error.locations=TRUE,warn=2);'
    let error_options = 'options(show.error.locations=TRUE);'
    let set_wd = 'setwd(''' . working_dir . ''');'
    let source_file = 'source(''' . current_file . ''',keep.source=TRUE,' .
                \ 'encoding=''UTF-8'')'

    " Actually define the compiler
    let compiler = 'R ' . flags . '"' . error_options . set_wd .  source_file .
                \ '"'

    " We might want to do a foreground compilation in the regular os console
    if a:compilation ==# 'foreground_os'
        let bang_command = '!start '
        let pause_command = '&& pause'
        let remove_visual_command = ''
        if exists(':Dispatch')
            let bang_command = 'Start -wait=always '
            let pause_command = ''
        endif
        if a:mode ==# 'visual'
            let remove_visual_command = '; rm ' . current_file
        endif
        execute bang_command . compiler . remove_visual_command . pause_command
        execute 'lcd ' . save_pwd
        return
    endif

    " Set makeprg and error format when running make or Make (background
    " compilation)
    let &l:makeprg = compiler
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
        echon 'running R with dispatch ...'
        " Make
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running R with make...'
        silent make!
    endif

    " Restore error format and return to previous working directory
    let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

" Define commands to run visual selections (foreground visual compilation is
" done directly with nvimr plugin)
command! -range EvalVisualRBackground
            \ call s:RunR('visual', 'background', <line1>, <line2>)
command! -range EvalVisualRForeground
            \ call s:RunR('visual', 'foreground_os', <line1>, <line2>)

" }}}
" Output/Errors {{{

" Show R output from the qf in a preview window
function! s:ShowROutputOrError()
    " Only call this function after a R run and not after linting (i.e only run
    " it if we sourced an R file)
    if matchstr(&makeprg, ';\zssource\ze(') !=# 'source'
        return
    endif

    " Close/delete previous output preview window buffer
    silent! pclose
    silent! bdelete R_output
    cclose

    " Get the R file, log file and directory from makeprg
    let makeprg_string = &makeprg
    let base_dir = matchstr(makeprg_string, 'setwd(''\zs.*\ze\'');')
    let base_file = matchstr(makeprg_string, 'source(''\zs.*\ze\'',')
    let current_file = base_dir . '/' . base_file

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

    " If there is no output exit
    let height = len(output)
    if height == 0
        redraw
        unsilent echo 'No (printable) R output'
        return
    endif

    " Initiate the new quickfix list
    let qflist = []

    " When running a visual selection get the correct file and line number
    let buf_nr_r_file = bufnr(current_file)
    let correct_lnum = 0
    if match(current_file, '_tmpvisual') != -1
        let correct_file = join(split(current_file, '_tmpvisual'), '')
        let buf_nr_r_file = bufnr(correct_file)

        " Now get the correct line number: the V mark is placed at the beginning
        " of the visual selection while the L mark measures the number of lines
        " that load libraries. Note that if no libraries were loaded then the L
        " mark is not set and line("'L") correctly (for our needs) returns 0.
        let correct_lnum = (-line("'L") - 1) + line("'V")
        " Finally delete visual marks since they are not needed anymore
        silent! delmarks V L
    endif

    " The next for loop builds the quickfix if there are errors:
    " R errors always start with the word Error or ERROR (i.e in lower or upper
    " case) and always halts at the first error.
    " Errors seem to be displayed in three formats (and variations on these
    " formats):
        " i) Error message (from file#line_nr) : error explanation
        " ii) Error message:
                " file:line_nr:column_nr: error explanation
        " iii) Error message (from file#line_nr) :
                " different_file:line_nr:column_nr: error explanation
    for item in output
        let entry = {}  " Each element of the qflist is a dictionary

        if match(item , '^\<\(Error\|ERROR\)\>') != -1
            let error_ind = index(output, item)
            let entry.type = 'E'   " Set error type

            " If the last non-whistespace character of the error line is a semi-
            " colon then we have a multiline message that we must join into a
            " single line error message
            if matchstr(item, '\zs\S\ze\s*$') ==# ':'
                let extra_err_line =  matchstr(output[error_ind + 1],
                            \ '\s*\zs.*$')
                let item = item . extra_err_line
            endif

            " Get filename (taking into account that the error might be in a
            " sourced file different from the current one)
            let entry.bufnr = buf_nr_r_file
            " The following might be an absolute path
            let error_file = matchstr(item, '\S\+\.\w\+\ze:')
            let error_file_dir = fnamemodify(error_file, ':p:h')
            let error_file_base = fnamemodify(error_file, ':t')
            if empty(error_file)
                " The following is always a base file name in the
                " current directory since we set the R working
                " directory to the current folder before sourcing
                let error_file_base = matchstr(item, 'from\s\zs\S\+\ze#')
                let error_file_dir = base_dir
            endif
            if error_file_base != base_file
                let correct_error_file = error_file_dir . '/' . error_file_base
                let entry.bufnr = bufnr(correct_error_file)
                " If the buffer is not loaded this will return -1 even if the
                " file exists. Therefore we need to add it to the buffer list
                " (without loading it) using :badd
                if entry.bufnr == -1 && filereadable(correct_error_file)
                    silent execute 'badd ' . correct_error_file
                    let entry.bufnr = bufnr(correct_error_file)
                endif
            endif

            " Get line (and column) numbers
            let entry.lnum = str2nr(matchstr(item, ':\zs\d\+\ze')) +
                        \ correct_lnum
            if empty(entry.lnum)
                let entry.lnum = str2nr(matchstr(item, '\#\zs\d\+\ze')) +
                            \ correct_lnum
            else
                let entry.col = str2nr(matchstr(item, ':\d\+:\zs\d\+\ze'))
            endif

            " Remove filename and line number from error message since we
            " already have that information
            let item =  substitute(item, '(from.*)\s', '', '')
            let item = substitute(item, '\S\+\.\w\+:.*:\s', '','')
            let entry.text = item

            " Add entry to qflist list and break for loop because we only want
            " the first error (this is actually the unique error since R halts
            " when it encounters an error)
            call add(qflist, entry)
            break
            " TODO: Show warning but also output? Or convert warnings to errors?
            " See what we did in matlab settings and python; the problem here is
            " that we cannot get warning line numbers
        endif
    endfor

    " If the file was run from a visual selection delete temp file since we
    " don't need it anymore
    if match(current_file, '_tmpvisual') != -1
        call delete(current_file)
    endif

    " Open the quickfix (if there are errors)
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
        " Finally return to previous window and exit
        wincmd p
        return
    endif

    " If there are no errors create a buffer to dump output
    execute 'silent botright new R_output'
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight previewwindow

    " Actually append output
    call append(line('$'), output)

    " Delete extra line at the beginning
    silent normal! ggdd

    " Resize the buffer height
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'

    " Return to previous window
    wincmd p
endfunction

augroup show_R_output
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowROutputOrError()
augroup END

" }}}
" Linting {{{

" TODO: Run this without calling R (i.e as an external tool) because otherwise
" it is slow
function! s:LintR()
    " Don't run lintr if R is not installed
    if !executable('R')
        echoerr 'R is not installed or not in your path.'
        return
    endif
    " Check if the formatR library is installed (using $R_LIBS_USER env variable)
    if empty($R_LIBS_USER) == 1
        echoerr 'Please set R_LIBS_USER env variable.'
    endif
    let lintr_dir = expand($R_LIBS_USER . '/lintr')
    if !isdirectory(lintr_dir)
        echoerr "The library 'lintr' was not found in " . lintr_dir
        return
    endif

    " Don't run lintr if there is only one empty line or we are in a Gdiff (when
    " file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf, save working directory and get current file and directory
    cclose
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')
    let current_dir = expand('%:p:h')

    " Set compiler
    let flags = '--slave --no-save --no-restore -e '
    let set_wd = 'setwd(''' . current_dir . ''');'
    let lintr_opts = 'with_defaults('
                \. 'line_length_linter(80), '
                \. 'commented_code_linter = NULL, '
                \. 'camel_case_linter, '
                \. 'snake_case_linter = NULL'
                \. ')'
    let lint_command = 'library(lintr);lint(cache = FALSE, commandArgs(TRUE), '
                \  . lintr_opts . ')'
    let file_args = ' --args ' . current_file
    let compiler = 'R ' . flags . '"' . set_wd . lint_command . '"' . file_args
    let &l:makeprg = compiler

    " Set error format
    let old_efm = &l:efm
    let &l:efm = '%W%f:%l:%c: style: %m,%W%f:%l:%c: warning: %m,' .
                \ '%E%f:%l:%c: error: %m,%-G%.%#'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchall because Dispatch removes it
        let &l:efm = &errorformat . ',%-G%.%#'
        echon 'running lintr with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif

    else
        " Use regular make otherwise
        echon 'running lintr ...'
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
            echon 'Finished lintr successfully.'
        endif
    endif

    " Restore error format and working directory
    let &l:efm = old_efm
    execute 'lcd ' . l:save_pwd
endfunction

function! s:FormatR(...)
    " Don't run formatR if R is not installed
    if !executable('R')
        echoerr 'R is not installed or not in your path.'
        return
    endif
    " Check if the formatR library is installed (using $R_LIBS_USER env variable)
    if empty($R_LIBS_USER) == 1
        echoerr 'Please set R_LIBS_USER env variable.'
    endif
    let formatr_dir = expand($R_LIBS_USER . '/formatR')
    if !isdirectory(formatr_dir)
        echoerr "The library 'formatR' was not found in " . formatr_dir
        return
    endif

    " Don't run formatR if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Save working directory and get current file and directory
    let l:save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')
    let current_dir = expand('%:p:h')

    " Save cursor position
    let save_cursor = getcurpos()

    " Yank the whole buffer
    silent normal! ggyG

    " Set compiler
    let flags = '--slave --no-save --no-restore -e '
    let tidy_command = 'library(formatR);x <- tidy_source(source = ' .
                \ '\"clipboard\", width.cutoff = 80, arrow = TRUE)'
    let compiler = 'R ' . flags . '"' . tidy_command . '"'

    " Run the command
    let output = split(system(compiler), '\n')

    " FIXME: For some reason this sometimes fails and gives no output
    if len(output) == 0
        call setpos('.', save_cursor)
        return
    endif

    " If there are errors simply return
    if match(output[0], '^Error') != -1
        call setpos('.', save_cursor)
        return
    endif

    silent normal! ggdG
    call append(line('$'), output)

    " Delete extra lines at the beginning and set markdown filetype with folding
    " at subsection level
    silent normal! ggdd

    " Save file and restore cursor position
    silent noautocmd update
    call setpos('.', save_cursor)
endfunction

" Automatically run formatR and lintr on save
augroup R_linting
    au!
    au BufWritePost *.{r,R} call s:LintR()
    " Don't autoformat since it's pretty basic
    " au BufWritePost *.{r,R} call s:FormatR() | call s:LintR()
augroup END

" }}}
" Docs {{{

function! s:ViewRDoc(...)
    " Check if pandoc is installed
    if !executable('pandoc')
        echoerr 'pandoc is not installed or not in your path.'
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Get current directory to save temp html and markdown files
    let l:save_pwd = getcwd()
    lcd %:p:h
    let working_dir = expand('%:p:h')

    " Search for library or object in library
    if a:0 >= 1 && strlen(a:1)
        let library = input('Enter library to view doc: ')
        if empty(library)
            redraw!
            return
        endif
        let object = input('Enter object to view doc or leave empty to see ' .
                    \ '`' . library . '` index: ')
        if empty(object)
            let help_arg = library
        else
            let help_arg = '\`' . object . '\`' . ',' . library
        endif
    else
        " Search for word under the cursor or ask for object
        let library = ''
        let object = expand('<cword>')
        if empty(object)
            let object = input('Enter object to view doc: ')
            if empty(object)
                redraw!
                return
            endif
        endif
        let help_arg = '\`' . object . '\`'
    endif
    " Redraw to remove command line text
    redraw!

    " If the function is called from a doc buffer save the library name present
    " in the bufname before deleting the doc buffer
    let current_bufname = bufname('%')
    if match(current_bufname, 'R_doc') != -1
        let doc_library_name = matchstr(current_bufname, '(\zs.*\ze)')
    else
        let doc_library_name = ''
    endif
    " The following will indeed delete the R doc buffer because it matches the
    " beginning of the buffer name
    silent! bdelete R_doc

    " Obtain doc file in HTML format
    let help_command = 'tools:::Rd2HTML(utils:::.getHelpFile(help(' .
                \ help_arg . ')))'
    if !empty(library) && empty(object)
        " If we only enter a library name then obtain library index
        let help_command = 'cat(readLines(file.path(find.package(''' .
                    \ help_arg . '''), ''INDEX'')), sep = ''\\\n'')'
    endif
    let flags = '--slave --no-save --no-restore -e '
    let compiler = 'R ' . flags . '"' . help_command . '"'
    let output = split(system(compiler), '\n')

    " If there is no documentation give error message
    if match(output[0] , '^Error\s\in') != -1
        " Get libraries from the R doc bufname or loaded in an R file
        let library_names = []
        if doc_library_name ==# 'builtin'
            let library_names = []
        elseif doc_library_name !=# ''
            let library_names = add(library_names, doc_library_name)
        else
            " Note that uniq() only works with adjacent items
            let library_names = uniq(s:GetLibraries()[1])
        endif

        " If only an object was entered and no doc was found try to find the
        " object in the obtained libraries before giving an error message
        if empty(library) && !empty(library_names)
            let lib_nr = 1
            for package in library_names
                let help_arg = '\`' . object . '\`' . ',' . package
                let help_command = 'tools:::Rd2HTML(utils:::.getHelpFile'.
                            \ '(help(' .  help_arg . ')))'
                let compiler = 'R ' . flags . '"' . help_command . '"'
                let output = split(system(compiler), '\n')
                if match(output[0] , '^Error\s\in') == -1
                    " If we found a matching doc save the package name and break
                    " the loop
                    let library = package
                    break
                elseif lib_nr == len(library_names)
                    " If we finished checking for the object in all loaded
                    " library without any match then do give an error message
                    redraw!
                    echohl Error
                    echo 'No documentation found for `' . object .
                                \ '` (including the following libraries: ' .
                                \ join(library_names, ', ') . ').'
                    echohl none
                    return
                endif
                let lib_nr = lib_nr + 1
            endfor
        else
            redraw!
            let not_found_object = '`' . object . '`'
            if !empty(library) && empty(object)
                let not_found_object = 'library `' . library . '`'
            endif
            echohl Error
            echo 'No documentation found for ' . not_found_object
            echohl none
            return
        endif
    endif

    " If we only want the index for a library then we already have it
    if !empty(library) && empty(object)
        let output_md = output
    else
        " If there is documentation convert it from html to markdown using
        " pandoc
        let html_temp = working_dir . '/temp_html.html'
        let md_temp = working_dir . '/temp_md.md'
        call writefile(output, html_temp)
        silent execute '!pandoc ' . html_temp . ' -o ' . md_temp
        let output_md = readfile(md_temp)

        " Delete temp file
        call delete(html_temp)
        call delete(md_temp)
    endif
    " Restore working directory
    execute 'lcd ' . l:save_pwd

    " Create a buffer to dump output
    let buffer_doc_name = 'R_doc(builtin)'
    if !empty(library)
        let buffer_doc_name = 'R_doc('. library . ')'
    endif
    execute 'silent botright new ' . buffer_doc_name
    silent normal! dGgg

    " Actually dump the output
    call append(line('$'), output_md)

    " Delete extra lines at the beginning and set markdown filetype with folding
    " at subsection level
    silent normal! ggdd
    setlocal nomodifiable nomodified filetype=markdown foldlevel=2

    " Resize the buffer height
    let height = len(output_md)
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'

    " Mappings to jump to tags, search for another object and exit buffer
    nnoremap <silent> <buffer>  <C-]> :call <SID>ViewRDoc()<CR>
    nnoremap <silent> <buffer> K :call <SID>ViewRDoc()<CR>
    nnoremap <silent> <buffer> <Leader>pd :call <SID>ViewRDoc('library')<CR>
    nnoremap <silent> <buffer> Q :bd!<CR>

    " Highlight R code within markdown (we match R code to text indented with 4
    " or more spaces)
    unlet! b:current_syntax
    syn include @mdRScript syntax/r.vim
    syn region mdRRegion start=/^\v {4}/ end=/\v^( {4}|\n)@!/ contains=@mdRScript
    let b:current_syntax = 'markdown'
endfunction

" }}}
" Miscellaneous {{{

" Get libraries {{{

" Get lines with libraries (for visual compilation)
function! s:GetLibraries()
    let library_lines = []
    let library_names = []
    let line_nr = 1
    let end_line = 25  " Last line to check for loaded libraries
    if line('$') < end_line
        let end_line = line('$')
    endif
    while line_nr <= end_line
        let curline = getline(line_nr)
        " Match libraries (also matches libraries loaded with leading spaces,
        " such as those in conditionals; for these cases remove these leading
        " space before saving the line)
        if match(curline, '^\s*\(library\|require\)') != -1
            let curline = substitute(curline, '\s*', '', '')
            let library_lines = add(library_lines, curline)
            let library_names = add(library_names, matchstr(curline,
                        \ '(\zs\w*\ze)\|(\W\zs\w*\ze\W)'))
        endif
        let line_nr = line_nr + 1
    endwhile
    " Get how many libary lines we have in order to correctly compute error line
    " numbers
    let last_library_line = len(library_lines)
    " Return a list
    let return_list = [library_lines, library_names, last_library_line]
    return return_list
endfunction

" }}}
" View (PDF) figure {{{

function! s:ViewPdfFigure()
    " Save working directory and switch to current file
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Construct the pdf file full path (get a base filename from the first
    " argument of ggsave() function, remove possible extension and search
    " downwards in the current directory for a pdf file with that name)
    let search_path = expand('%:p:h') . '/**'
    let figure_file = matchstr(getline('.'), '^ggsave(\"\zs\S*\ze\"')
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
" Debugging {{{

function! s:AddBreakPoint()
    let save_cursor = getcurpos()
    let current_line = line('.')
    let breakpoint_line = current_line - 1
    let indent_length = match(getline(current_line), '\w')
    let indents = repeat(' ', indent_length)
    let bp_statement = 'browser()'
    call append(breakpoint_line, indents . bp_statement)
    silent noautocmd update
    call setpos('.', save_cursor)
endfunction

function! s:RemoveBreakPoint()
    let save_cursor = getcurpos()
    execute 'g/browser()/d'
    silent update
    call setpos('.', save_cursor)
endfunction

" }}}

" }}}
" Mappings {{{

" Anon snippets for <-
if exists(':UltiSnipsEdit')
    inoremap <buffer> <silent> <<
                \ <<<C-R>=UltiSnips#Anon('<-','<<', '', 'i')<CR>
endif

" Breakpoints
nnoremap <silent> <buffer> <Leader>bp :call <SID>AddBreakPoint()<CR>
nnoremap <silent> <buffer> <Leader>rb :call <SID>RemoveBreakPoint()<CR>

" Background compilation
nnoremap <silent> <buffer> <F7> :call <SID>RunR('normal', 'background')<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunR('normal', 'background')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualRBackground<CR>
" Foreground compilation in os console
nnoremap <silent> <buffer> <F5> :call <SID>RunR('normal', 'foreground_os')<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunR('normal', 'foreground_os')<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualRForeground<CR>

" Linting and format R
nnoremap <buffer> <silent> <Leader>rl :call <SID>LintR()<CR>
nnoremap <buffer> <silent> <Leader>fr :call <SID>FormatR()<CR>

" (Open) Interpreter (we mostly use nvim-r for this now)
if exists(':Topen')
    nnoremap <silent><buffer> <Leader>oi :lcd %:p:h<CR>:T
                \ R --ess --no-save --no-restore<CR>
endif

" Documentation
nnoremap <silent><buffer> <S-k> :call <SID>ViewRDoc()<CR>
nnoremap <silent><buffer><Leader>pd :call <SID>ViewRDoc('library')<CR>

" View PDF figure
nnoremap <buffer> <silent> <Leader>vp :call <SID>ViewPdfFigure()<CR>

" }}}
