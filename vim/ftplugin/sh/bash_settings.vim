" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:my_bash_settings_file')
    finish
endif
let b:my_bash_settings_file = 1

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

function! s:RunSh(mode, compilation, ...)
    " Check if sh files are executable
    if !executable('bash')
        echoerr 'bash is not installed or not in your path.'
        return
    endif

    " Place uppercase marks at i) the beginning of visual selection
    silent! delmarks V " Delete previous marks
    if a:mode ==# 'visual' && a:0 >= 1 && strlen(a:1)
        silent execute a:1 . ' mark V'
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf and location list, save and change working directory
    cclose
    lclose
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Set compiler
    let compiler = 'bash '

    if a:mode ==# 'visual' && a:0 >= 2 && strlen(a:1) && strlen(a:2)
        " Create temp file in the current directory with visual content (and
        " imported modules)
        let current_file = expand('%:t:r') . '_tmpvisual.sh'
        let lines = getline(a:1, a:2)
        call writefile(lines, current_file)
    else
        let current_file = expand('%:p:t')
    endif

    " Use neovim terminal for foreground async compilation
    if a:compilation ==# 'foreground' && exists(':Topen')
        let old_size = g:neoterm_size
        let old_autoinsert = g:neoterm_autoinsert
        let g:neoterm_size = 12
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
    " Note: on mac this requires iTerm to be open
    if a:compilation ==# 'foreground_os'
        let bang_command = '!'
        let remove_visual_command = ''
        if exists(':Dispatch')
            let dispatch_title = 'sh-'. fnamemodify(current_file, ':t')[:8]
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
    " compilation); for details see bash-support.vim
    " https://github.com/WolfgangMehner/vim-plugins
    let &l:makeprg = compiler . current_file
    let old_efm = &l:efm
    setlocal errorformat=%f:\ %[%^0-9]%#\ %l:%m,%f:\ %l:%m,%f:%l:%m,%f[%l]:%m

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
        " Use regular make otherwise
        echon 'running bash with make...'
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
            if bufname('%') ==# 'bash_output'
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
command! -range EvalVisualShVimshell
      \ call s:RunSh('visual', 'foreground', <line1>, <line2>)
command! -range EvalVisualShBackground
      \ call s:RunSh('visual', 'background', <line1>, <line2>)
command! -range EvalVisualShForeground
            \ call s:RunSh('visual', 'foreground_os', <line1>, <line2>)

" }}}
" Output/Errors {{{

" Show py output from the qf in a preview window
function! s:ShowShOutput()
    " Only call this function after a sh run
    let compiler = split(&makeprg, '')[0]
    if compiler !=# 'bash'
        return
    endif

    " Close/delete previous output preview window buffer
    silent! pclose
    silent! bdelete bash_output

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
            unsilent echo 'No (printable) bash output'
        endif
        return
    else
        execute 'silent botright new bash_output'
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
        if bufname('%') ==# 'bash_output'
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

augroup show_sh_output
    au!
    " We use make event for regular make and cgetfile event for Dispatch
    au QuickFixCmdPost {make,cgetfile} call s:ShowShOutput()
augroup END

" }}}
" Linting {{{

function! s:RunBeautySh(...)
    " Don't run beautysh if it is not installed
    if !executable('beautysh')
        echoerr 'beautysh is not installed or not in your path.'
        return
    endif
    " Don't run beautysh if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Change shellredir to avoid inserting error output into the buffer (i.e
    " don't include stderr in output buffer)
    let shrd = &shellredir
    set shellredir=>%s
    let old_formatprg = &l:formatprg
    let &l:formatprg = 'beautysh -f -'
    let save_cursor = getcurpos()
    if a:0 && a:1 ==# 'visual'
        execute 'normal! gvgq'
    else
        execute 'silent! normal! gggqG'
    endif
    if v:shell_error == 1
        silent undo
    endif
    call setpos('.', save_cursor)
    let &shellredir = shrd
    let &l:formatprg = old_formatprg
endfunction

" Automatically run beautysh and shellcheck on save
augroup sh_linting
    au!
    au BufWritePost *.sh call s:RunBeautySh() | silent noautocmd update |
                \ silent Neomake
augroup END

" }}}
" Docs {{{

function! s:ViewShDoc()
    " Search for word under the cursor or ask for object
    let object = expand('<cword>')
    if empty(object)
        let object = input('Enter object to view doc: ')
        if empty(object)
            redraw!
            return
        endif
    endif

    " Obtain help file (using vim's man page viewer)
    runtime! ftplugin/man.vim
    let compiler = 'Man ' . object
    silent execute compiler

    " Place the window at the bottom and resize height
    execute 'wincmd J'
    let height = line('$')
    if height > 15
        let height = 15
    endif
    execute height . ' wincmd _'
endfunction


" }}}
" Mappings {{{

" Background compilation
nnoremap <silent> <buffer> <F7> :call <SID>RunSh('normal', 'background')<CR>
inoremap <silent> <buffer> <F7> <ESC>:call
            \ <SID>RunSh('normal', 'background')<CR>
vnoremap <silent> <buffer> <F7> :EvalVisualShBackground<CR>
" Foreground compilation
nnoremap <silent> <buffer> <Leader>rf :call
            \ <SID>RunSh('normal', 'foreground')<CR>
vnoremap <silent> <buffer> <Leader>rf :EvalVisualShVimshell<CR>
" Run in the command line (useful when input is required)
nnoremap <silent> <buffer> <F5> :call
            \ <SID>RunSh('normal', 'foreground_os')<CR>
inoremap <silent> <buffer> <F5> <ESC>:call
            \ <SID>RunSh('normal', 'foreground_os')<CR>
vnoremap <silent> <buffer> <F5> :EvalVisualShForeground<CR>

" Linting
nnoremap <silent> <buffer> <Leader>rl :silent Neomake<CR>
nnoremap <silent> <buffer> <Leader>fc :call <SID>RunBeautySh()<CR>

" Documentation
nnoremap <silent> <buffer> <S-k> :call <SID>ViewShDoc()<CR>

" }}}
