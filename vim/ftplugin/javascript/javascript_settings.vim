"===============================================================================
"          File: javascript_settings.vim
"        Author: Pedro Ferrari
"       Created: 02 Dec 2016
" Last Modified: 22 Jan 2017
"   Description: My Javascript settings
"===============================================================================
" Installation notes {{{

" To use the linter we need to install eslint (install it with npm).

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_js_settings_file')
    finish
endif
let b:my_js_settings_file = 1

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

function! s:RunJS(mode, compilation, ...)
    " Check if js files are executable
    if !executable('node')
        echoerr 'node is not installed or not in your path.'
        return
    endif

    " Place uppercase marks at i) the beginning of visual selection
    silent! delmarks V " Delete previous marks
    if a:mode ==# 'visual' && a:0 >= 1 && strlen(a:1)
        silent execute a:1 . ' mark V'
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf, save and change working directory
    cclose
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Set compiler
    let compiler = 'node '

    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file in the current directory with visual content (and
        " imported modules)
        let current_file = expand('%:t:r') . '_tmpvisual.js'
        let lines = getline(a:1, a:2)
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
    " compilation); for details see
    " https://github.com/felixge/vim-nodejs-errorformat/
    let &l:makeprg = compiler . current_file
    let old_efm = &l:efm
    let &l:efm  = '%AError: %m' . ','
    let &l:efm .= '%AEvalError: %m' . ','
    let &l:efm .= '%ARangeError: %m' . ','
    let &l:efm .= '%AReferenceError: %m' . ','
    let &l:efm .= '%ASyntaxError: %m' . ','
    let &l:efm .= '%ATypeError: %m' . ','
    let &l:efm .= '%Z%*[\ ]at\ %f:%l:%c' . ','
    let &l:efm .= '%Z%*[\ ]%m (%f:%l:%c)' . ','
    let &l:efm .= '%*[\ ]%m (%f:%l:%c)' . ','
    let &l:efm .= '%*[\ ]at\ %f:%l:%c' . ','
    let &l:efm .= '%Z%p^,%A%f:%l,%C%m' . ','
    let &l:efm .= '%-G%.%#'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " Make
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'running js with make...'
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
            if bufname('%') ==# 'sh_output'
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

    " Delete visual file, restore error format and return to previous working
    " directory (when using MacVim we delete the visual file later in the
    " callback function)
    if !has('gui_macvim')
        if a:mode ==# 'visual'
            call delete(current_file)
        endif
    endif
    " let &l:efm = old_efm
    execute 'lcd ' . save_pwd
endfunction

" Define commands to run visual selections
command! -range EvalVisualJSVimshell
      \ call s:RunJS('visual', 'foreground', <line1>, <line2>)
command! -range EvalVisualJSBackground
      \ call s:RunJS('visual', 'background', <line1>, <line2>)
command! -range EvalVisualJSForeground
            \ call s:RunJS('visual', 'foreground_os', <line1>, <line2>)

" }}}
" Output/Errors {{{

" Show py output from the qf in a preview window
function! s:ShowJSOutput()
    " Only call this function after a sh run
    let compiler = split(&makeprg, '')[0]
    if compiler !=# 'node'
        return
    endif

    " Close/delete previous output preview window buffer
    silent! pclose
    silent! bdelete js_output

    " Get current file
    let current_file = split(&makeprg, '')[1]
    " When using MacVim delete visual temp file here
    if has('gui_macvim') && match(current_file, '_tmpvisual') != -1
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
        " at the beginning of the visual selection.
        if match(current_file, '_tmpvisual') != -1
            let correct_file = join(split(current_file, '_tmpvisual'), '')
            let buf_nr_sh_file = bufnr(correct_file)
            let correct_lnum = line("'V")
            " Now actually fix filename and line numbers
            for entry in qflist
                let buffer_number = get(entry, 'bufnr', '')
                if bufname(buffer_number) ==#  current_file
                    let entry.bufnr = buf_nr_sh_file
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
            unsilent echo 'No (printable) js output'
        endif
        return
    else
        execute 'silent botright new js_output'
    endif
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline winfixheight

    " Actually append output
    call append(line('$'), output)

    " Delete extra line at the beginning
    silent normal! ggdd

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
        if bufname('%') ==# 'js_output'
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

augroup show_js_output
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowJSOutput()
augroup END

" }}}
" Linting {{{

function! s:UpdateJsBuffer()
    " Only run this function for javascript files
    if &filetype !=# 'javascript'
        return
    endif
    checktime
endfunction

" Run eslint and reload buffer for style autofixing
augroup js_linting
    au!
    au BufWritePost *.js silent Neomake
    au User NeomakeJobFinished call s:UpdateJsBuffer()
augroup END

" }}}
" Mappings {{{

" Background compilation
nnoremap <silent> <buffer> <F7> :call <SID>RunJS('normal', 'background')<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunJS('normal', 'background')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualJSBackground<CR>
" Foreground compilation
nnoremap <silent> <buffer> <Leader>rf :call
            \ <SID>RunJS('normal', 'foreground')<CR>
vnoremap <silent> <buffer> <Leader>rf :EvalVisualJSVimshell<CR>:wincmd p<CR>
" Run in the command line (useful when input is required)
nnoremap <silent> <buffer> <F5> :call
            \ <SID>RunJS('normal', 'foreground_os')<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunJS('normal', 'foreground_os')<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualJSForeground<CR>

" Linting
nnoremap <buffer> <Leader>rl :call <SID>RunEsLint()<CR>

" }}}
