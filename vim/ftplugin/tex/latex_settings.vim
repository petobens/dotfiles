"===============================================================================
"          File: latex_settings.vim
"        Author: Pedro Ferrari
"       Created: 27 Aug 2013
" Last Modified: 14 Apr 2017
"   Description: Latex settings
"===============================================================================
" TODOs:
" Add pie, line and bar plots to templates?
" Improve fold function? See vimtex issue #52 and begin frame title argument,
" and don't fold sections or frames in the preamble
" tikz: change big arrow definition (abandon postaction) with arrows.meta and
" hence remove wrong standalone behaviour with axis arrows bounding box; opened
" a feature request on pgf development page in sourceforge
" Print black hyperlinks (patch with fixes not included in hyperref)
" Refsection biblatex warning when compiling; NO FIX?

" Installation notes {{{

" Miktex:
" Install 64-bit version for a single user and check that this user has
" permissions to write the folder were miktex was installed (such as
" C:/prog-lang/miktex)
" If miktex gives an error about a missing mfc120.dll file then install
" vcredist_x64 (Microsoft Visual C++ 2013 Redistributable)

" Note that to be able to use texcount we need a Perl distribution (such as
" Strawberry Perl). We can install directly with msys2 and pandoc

" Also note that if we want to use our own packages we need to add
" C:\OD\OneDrive\Latex\localtexmf to the root search path

" Basictex:
" On Mac install basictex using 'brew cask install basictex' and then add the
" following to your bash_profile:
" export PATH="/Library/TeX/texbin:$PATH"

" To install texdoc, enable automatic build of documentation and build
" documentation for all installed packages do:
" sudo tlmgr install texdoc
" sudo tlmgr option docfiles 1
" sudo tlmgr install --reinstall $(tlmgr list --only-installed | sed -e 's/^i //' -e 's/:.*$//')

" Install additional packages with `sudo tlmgr install package_name`
" Update tex live manager with `sudo tlmgr update --self`
" Update all packages with `sudo tlmgr update all`
" To install our own packages we need to create a folder in ~/Library/texmf with
" TDS structure

" In particular to fix font errors install `collection-fontsrecommended` package
" To count words and lint install texcount and chktex with tlmgr

" To uninstall basictex (in order to update texlive) remove with `rm -rf` the
" following directories: '/usr/local/texlive/', '/Library/TeX/' and
" '/Library/texlive'

" To install arara build it with maven and then create a script called `arara4`
" with the following contents:

" #!/bin/sh
"
" exec java -jar $0 "$@"
"
" Take care to add several empty lines at the end. Then run
" cat ./arara4.jar >> ./arara
" chmod +x ./arara
" And add the arara folder (along the executable) to your path

" Linter:
" In order to use ChkTeX linter on Windows, from the chektex directory we first
" run `./configure` and then `mingw32-make.exe` from the msys2 cmd prompt
" (assuming we have msys2 and mingw64 installed). Then we add the chktex
" executable to the path.
"
" Vimtex:
" We use b:vimtex.tex variable (provided by vimtex plugin) to get the path of
" the main tex file. We then build arara 4 from source (using maven) to compile
" the document; to do that (on Windows) we first to download the Java SKD and
" create a JAVA_HOME env variable set to the root of the jdk installation:
" C:\prog-lang\java\java-jdk (note there is no need to install the jre since it
" is included in the jdk). Then also add C:\prog-lang\java\java-jdk\bin to path.
" Finally we need to add the maven bin folder to path:
" C:\prog-tools\maven-325\bin

" This file also uses and sometimes requires the following plugins:
" EasyAlign, Dispatch, Ultisnips, Vimproc and neoterm
" Besides SumatraPDF is used as the default PDF viewer on Windows.

" }}}
" Initialization {{{

" Check if this file exists and avoid loading it twice
if exists('b:loaded_latex_settings_file')
    finish
endif
let b:loaded_latex_settings_file = 1

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

" Tabs
setlocal shiftwidth=2
setlocal tabstop=2
setlocal softtabstop=2

" Editing
setlocal formatoptions=trj

" Spell checking
setlocal spell

" }}}
" Editing {{{

" Intelligent paragraph formatting (takes into account the start and end of
" environments)
" TODO: Is this no longer need since vimtex has now a paragraph motion? We might
" replace this function with gqip
function! s:TexParFormat()
    if getline('.') !=# ''
        let save_cursor = getpos('.')
        let old_wrapscan = &wrapscan
        set nowrapscan
        let par_begin = '^\(%D\)\=\s*\($\|\\label\|\\begin\|\\end\|\\[\|\\]\|'.
                        \ '\\\(sub\)*section\>\|\\item\>\|\\NC\>\|\\blank\>\|'.
                         \ '\noindent\>\)'
        let par_end   = '^\(%D\)\=\s*\($\|\\begin\|\\end\|\\[\|\\]\|\\place\|'.
                    \ '\\\(sub\)*section\>\|\\item\>\|\\NC\>\|\\blank\>\)'
        try
            execute '?' . par_begin . '?+'
            catch /E384/
            1
        endtry
        normal! V
        try
            execute '/' . par_end . '/-'
            catch /E385/
            $
        endtry
        normal! gq
        let &wrapscan = old_wrapscan
        call setpos('.', save_cursor)
    endif
endfunction

" Open relevant files for editing
if !exists('*s:EditFile')
    function! s:EditFile(file)
        let line = getline('.')
        let expr = a:file
        if a:file ==# 'figure'
            let file_no_ext = matchstr(line, '\v\\includegraphics(\[.*\])?' .
                        \ '\{\zs([^\.}]+)')
            " The figure might be a tex or a py file
            let tex_fig = file_no_ext . '.tex'
            let py_fig  = file_no_ext . '.py'
        elseif a:file ==# 'include'
            let expr = matchstr(line, '\v\\(include|input)\{\zs([^\.}]+)') .
                        \ '.tex'
        endif
        let path = b:vimtex.root . '/**'
        let file_path = globpath(path, expr)
        if a:file ==# 'main'
            let file_path = b:vimtex.tex
        elseif a:file ==# 'figure'
            let file_path = globpath(path, tex_fig) . globpath(path, py_fig)
        elseif a:file ==# 'find'
            let file = input('Enter file name: ')
            redraw!
            if empty(file)
                echohl Error
                echo 'Please input a file name.'
                echohl none
                return
            endif
            if s:is_win
                let file_path = system('findtexmf '. file)
            endif
        endif

        if empty(file_path)
            echohl Error
            if a:file ==# 'preamble.tex'
                echon 'The preamble file you are trying to edit was not found.'
                  \ . "\nUse the mapping to edit input files to try to open it."
            else
                echon 'The ' a:file ' file you are trying to edit was '
                  \ . 'not found.'
            endif
            echohl none
            return
        endif

        " Open the file in a horizontal or vertical split
        let split_windows = 'vsplit '
        if winwidth(0) <= 2 * (&textwidth ? &textwidth : 80)
            let split_windows = 'split '
        endif
        execute split_windows . file_path
    endfunction
endif

" }}}
" Compiling {{{

function! s:CompileTex(...)
    " Check if arara is installed
    if !executable('arara')
        echoerr 'arara is not installed or not in your path.'
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update
    " Clear quickfixlist window and delete any preview window (log file)
    call setqflist([])
    cclose
    pclose
    if bufname('.log') !=# ''
        execute 'silent! bdelete ' . bufname('.log')
    endif

    " Temporary change working directory to current file (we need this)
    let save_pwd = getcwd()
    lcd %:p:h
    let mainfile = b:vimtex.tex

    " Set the compiler
    let compiler = 'arara '

    " Set batch directive key defined in arara config file (arararc.yaml); arara
    " gives an error if it doesn't exist so there is no need to check existance
    let directives = '-p minimize_runs '

    " Use neovim terminal for foreground async compilation
    if a:0 && exists(':Topen')
        let old_size = g:neoterm_size
        let old_autoinsert = g:neoterm_autoinsert
        let g:neoterm_size = 10
        let g:neoterm_autoinsert = 0
        execute 'T ' . compiler . directives . '-v ' . mainfile
        " Avoid getting into insert mode using `au BufEnter * if &buftype ==
        " 'terminal' | startinsert | endif`
        stopinsert
        let g:neoterm_size = old_size
        let g:neoterm_autoinsert = old_autoinsert
        " Return to previous working directory and exit the function
        execute 'lcd ' . save_pwd
        return
    endif

    " Set makeprg (background compilation)
    let &l:makeprg = compiler . directives . mainfile

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch') != 0
        echon 'compiling with arara using dispatch...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif
    else
        " Use regular make otherwise
        echon 'compiling with arara...'
        silent make!
    endif
    execute 'lcd ' . save_pwd
endfunction

" Use the errorformat from vimtex:
function! s:SetTexEfm()
    " Push file to file stack
    setlocal errorformat=%-P**%f
    setlocal errorformat+=%-P**\"%f\"
    " Match errors
    setlocal errorformat+=%E!\ LaTeX\ %trror:\ %m
    setlocal errorformat+=%E%f:%l:\ %m
    setlocal errorformat+=%E!\ %m
    " More info for undefined control sequences
    setlocal errorformat+=%Z<argument>\ %m
    " More info for some errors (this clashes with the log-preview function)
    " setlocal errorformat+=%Cl.%l\ %m
    " Show warnings
    if !exists('g:vimtex_quickfix_ignore_all_warnings')
        let g:vimtex_quickfix_ignore_all_warnings = 0
    endif
    if g:vimtex_quickfix_ignore_all_warnings == 0
        " Ignore some warnings
        if !exists('g:vimtex_quickfix_ignored_warnings')
            let g:vimtex_quickfix_ignored_warnings = []
        endif
        for w in g:vimtex_quickfix_ignored_warnings
            let warning = escape(substitute(w, '[\,]', '%\\\\&', 'g'), ' ')
            exe 'setlocal errorformat+=%-G%.%#'. warning .'%.%#'
        endfor
        setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
        setlocal errorformat+=%+W%.%#\ at\ lines\ %l--%*\\d
        setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %m
        setlocal errorformat+=%+W%.%#%.%#Warning:\ %m
        " Parse biblatex warnings
        setlocal errorformat+=%-C(biblatex)%.%#in\ t%.%#
        setlocal errorformat+=%-C(biblatex)%.%#Please\ v%.%#
        setlocal errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
        setlocal errorformat+=%-Z(biblatex)%m
        " Parse babel warnings
        setlocal errorformat+=%-Z(babel)%.%#input\ line\ %l.
        setlocal errorformat+=%-C(babel)%m
        " Parse hyperref warnings
        setlocal errorformat+=%-C(hyperref)%.%#on\ input\ line\ %l.
    endif
    " Ignore unmatched lines
    setlocal errorformat+=%-G%.%#
endfunction

" Function to parse log file for errors (and update PDF file when needed)
function! s:QuickFixLog()
    " Only call this function after an arara run
    if split(&makeprg, '')[0] !=# 'arara'
        return
    endif

    " Get the base file from the makeprg
    let base_file = matchstr(&makeprg, 'minimize_runs\s\zs.*\.\ze')

    " Set the log file as the error file
    let logfile = base_file . 'log'
    if !filereadable(logfile)
        call setqflist([])
        redraw
        unsilent echo 'Log file not found but PDF document probably compiled' .
                    \' successfully.'
        return
    endif

    " Set proper error format to parse log file
    let old_errorformat = &l:errorformat
    call s:SetTexEfm()
    execute 'cgetfile ' . fnameescape(logfile)
    let &l:errorformat = old_errorformat

    " Open quick fix window if there are errors
    if !empty(getqflist())
        copen
        wincmd J
        wincmd p
    else
        redraw
        unsilent echo 'PDF document successfully compiled.'
    endif
endfunction

augroup parse_log_file
    au!
    au QuickFixCmdPost {make,cgetfile} call s:QuickFixLog()
augroup END

" }}}
" Linting {{{

" To install chktex use tlmgr
function! s:CheckTex()
    " Don't run chktex if it is not installed
    if !executable('chktex')
        echoerr 'ChkTeX is not installed or not in your path.'
        return
    endif
    " Also don't run it if there is only one empty line or we are in a Gdiff
    " (when file path includes .git)
    if (line('$') == 1 && getline(1) ==# '') || expand('%:p') =~# "/\\.git/"
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Close qf, save working directory and get current file and directory
    cclose
    let save_pwd = getcwd()
    lcd %:p:h
    let current_file = expand('%:p:t')

    " Set compiler (for warning/error codes see section 7 'Explanation of Error
    " Messages' in ChkTeX manual)
    let compiler = 'chktex '
    let ignore_warnings = '-n1 -n3 -n8 -n25 -n36 '
    let &l:makeprg = compiler . ignore_warnings . current_file

    " Set error format
    let old_errorformat = &l:errorformat
    let &l:errorformat = '%EError %n in %f line %l: %m,' .
        \ '%WWarning %n in %f line %l: %m,' .
        \ '%WMessage %n in %f line %l: %m,' .
        \ '%Z%p^,' .
        \ '%-G%.%#'

    " Use Dispatch for background async compilation if available
    if exists(':Dispatch')
        " First add extra catchall because Dispatch removes it
        let &l:errorformat = &errorformat . ',%-G%.%#'
        echon 'running chktex with dispatch ...'
        if s:is_win
            call s:NoShellSlash('Make')
        else
            execute 'silent Make'
        endif

    else
        " Use regular make otherwise
        echon 'running chktex ...'
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
            echon 'Finished chktex successfully.'
        endif
    endif

    " Restore error format and working directory
    let &l:errorformat = old_errorformat
    execute 'lcd ' . l:save_pwd
endfunction

" Automatically run on save
" augroup tex_linting
    " au!
    " au BufWritePost *.tex call s:CheckTex()
" augroup END

" }}}
" Miscellaneous {{{

" File deletion {{{

function! s:DeleteAuxFiles()
    " If the extensions to be deleted are wildignored they won't be recognised
    " by globpath function. Thus we first save and empty the wildignore setting
    let old_wig = &wildignore
    set wildignore=
    let extensions = 'aux,bbl,bcf,blg,idx,log,xml,toc,nav,out,snm,gz,ilg,ind'
    let path = b:vimtex.root
    let file_list = globpath(path,'*.{' . extensions . '}', 0, 1)
    let nr_filetypes = len(file_list)
    if nr_filetypes < 1
        echohl Error
        echo 'No auxiliary files are readable.'
        echohl none
        return
    endif
    if confirm('Really delete ' . nr_filetypes . ' aux file(s)?',
                \ "&Yes\n&No") == 1
        for item in file_list
            if exists(':VimProcBang') && s:is_win
                call vimproc#delete_trash(item)
            else
                execute delete(item)
            endif
        endfor
        redraw!
        echo nr_filetypes 'auxiliary file(s) deleted.'
    endif
    let &wildignore = old_wig
endfunction

function! s:DeleteBiberCache()
    let biber_cache = system('biber --cache')
    redraw!
    if empty(biber_cache)
        echohl Error
        echo 'biber cache directory not found'
        echohl none
        return
    endif
    if confirm('Really delete biber cache directory?', "&Yes\n&No") == 1
        if s:is_win
            silent execute '!RMDIR /S /Q ' . biber_cache
        else
            silent execute '!rm -rf ' . biber_cache
        endif
        redraw!
        echo  'biber cache directory was deleted'
    endif
endfunction

" }}}
" Log preview {{{

function! s:SearchLog()
    let line = getline('.')
    let qfregex = '^\f*|\d\+ \(error\|warning\)|\s\zs.\{-}\ze$\|' .
                \ '^|\d\+ warning|\s\zs.*\|' .
                \ '^||\s\zs.*'

    let errstring = escape(matchstr(line, qfregex), '[\ ')
    if line =~# '|\d\+ error|'
        let errstring = matchstr(line, '^\f*|\zs\d\+\ze') . ': ' . errstring
    endif

    " Find the correct log file (read it from the quick fix title)
    let logfile = matchstr(w:quickfix_title, 'minimize_runs\s\zs.*\.\ze') .
                \ 'log'

    " Open preview window, move to that window and perform search
    execute 'bot pedit +0 '. logfile
    wincmd j
    call search(errstring, 'W')

    " Highlight search and show result on top
    hi def link previewloghl Search
    execute 'match previewloghl "'. errstring .'"'
    normal! zt
endfunction

function! s:ViewLog()
    " Change scrolloff to show result on top
    let save_scrolloff = &scrolloff
    set scrolloff=0
    call s:SearchLog()
    if &previewwindow
        " Adjust window size
        4 wincmd _
        wincmd p
    endif
    let &scrolloff = save_scrolloff
endfunction

" }}}
" PDF and Doc Viewing {{{

function! s:ForwardInverseSearch(direction)
    let pdf_file = fnamemodify(b:vimtex.tex, ':r') . '.pdf'
    if !filereadable(pdf_file)
        echohl Error
        echo 'PDF file not found'
        echohl none
        return
    endif

    if s:is_win
        if !executable('SumatraPDF')
            echoerr 'SumatraPDF is not installed or not in your path.'
            return
        endif
        let viewer = 'silent! !start SumatraPDF -reuse-instance ' . pdf_file
        let inverse = ' -inverse-search ' .
                    \ '"gvim --remote-silent +\%l|foldo\! \%f"'
        let forward =  ' -forward-search ' . expand('%:p') . ' ' . line('.')

    elseif s:is_mac
        let displayline_path = '/Applications/Skim.app/Contents/' .
                    \ 'SharedSupport/displayline'
        if !executable('displayline') && !filereadable(displayline_path)
            echoerr 'Skim displayline is not installed or not in your path.'
            return
        endif
        if filereadable(displayline_path)
            let displayline_cmd = displayline_path
        else
            let displayline_cmd = 'displayline'
        end
        let bang_command = '! '
        if exists(':Dispatch')
            let bang_command = 'Start! '
        endif
        let viewer = 'silent! ' . bang_command . displayline_cmd
        let forward =  ' -r -g ' . line('.') . ' ' . pdf_file .  ' ' .
              \ expand('%:p')
    endif

    if a:direction ==# 'inv'
        if s:is_mac
            " Inverse search settings in Skim must be set directly from Skim
            " preferences Sync tab (i.e they cannot be set with flags) as a Custom
            " preset with Command: `nvr` and Arguments: `--remote-silent
            " +"%line|foldo!" "%file"`
            " Note: to allow automatic reload, check the box that says `Check for
            " file changes` and then run the following command
                " defaults write -app Skim SKAutoReloadFileUpdate -boolean true
            " Note that for inverse search to work with nvim we need to install
            " neovim-remote python module
            let open_cmd = 'open '
            if exists('$TMUX') && executable('reattach-to-user-namespace')
                " In tmux we need to fix the open command
                let open_cmd = 'reattach-to-user-namespace open '
            endif
            execute 'silent! !' . open_cmd . '-a Skim ' . pdf_file
            " We need to redraw screen here!
            redraw!
        else
            execute viewer . inverse
        endif
    else
        execute viewer . forward
    endif
endfunction

function! s:ViewDoc()
    let line = getline('.')
    " Note: \usepackage must be in the same line as the package name
    let package = matchstr(line, '\v\\usepackage([.*\])?\{\zs\w*\ze')
    if empty(package)
        let package = input('Enter package name: ')
        redraw!
    endif
    let flags = ''
    if s:is_win
        let flags = '--view'
    endif
    echohl Error
    echo system('texdoc '. flags . ' ' . package)
    echohl none
endfunction

" }}}
" Word counting {{{

" Install texcount with tlmgr
function! s:CountWords()
    " Check if perl is installed
    if !executable('perl')
        echoerr 'perl is not installed or not in your path.'
        return
    endif
    if !executable('texcount')
        echoerr 'texcount is not installed or not in your path.'
        return
    endif

    " Get main file and then restore working directory
    let save_pwd = getcwd()
    lcd %:p:h
    let mainfile = b:vimtex.tex

    " Close/delete previous word count buffer
    silent! bdelete tex_word_count

    " Get output from texcount perl script
    let flags = '-nosub -inc -total '
    let compiler = 'texcount ' . flags . mainfile
    let output = split(system(compiler), '\n')

    " Restore previous directory
    execute 'lcd ' . save_pwd

    " Remove unneeded information
    for item in output
        if match(item, 'Words in text') != -1
            let start_index = index(output, item)
        elseif match(item, 'Number of math displayed:') != -1
            let end_index = index(output, item)
            break
        endif
    endfor
    let word_count = output[start_index : end_index]

    " Create a buffer of appropiate height to dump output
    let height = len(word_count)
    execute 'silent botright ' . height . 'new tex_word_count'

    " Set buffer options
    silent! setlocal buftype=nofile bufhidden=delete noswapfile nowrap
                \ colorcolumn=0 textwidth=0 nonumber norelativenumber
                \ nocursorline

    " Actually dump the output
    call append(line('$'), word_count)

    " Delete extra lines at the beginning and make the buffer nomodifiable
    silent normal! ggdd
    setlocal nomodifiable nomodified

    " Set highlighting
    syntax match TexcountValue /.*:\zs.*/
    highlight link TexcountValue Constant
endfunction

" }}}
" Convert to docx {{{

" FIMXE: Currently it is not possible to:
" citations hyperlink don't seem to work either
" use graphicspath
" number sections or equations, or figures or tables
function! s:ConvertDocx()
    " Check if pandoc is installed
    if !executable('pandoc')
        echoerr 'pandoc is not installed or not in your path.'
        return
    endif

    " Update the file but ignore linting autocommand
    silent noautocmd update

    " Get current directory and switch to current file directory
    let l:save_pwd = getcwd()
    lcd %:p:h

    " Obtain tex files and eventual bib files
    let tex_file = b:vimtex.tex
    let bib_file = globpath(b:vimtex.root, '*.bib')
    let docx_file = fnamemodify(tex_file, ':r') . '.docx'

    " Define pandoc cmd to convert to docx files
    if empty(bib_file)
        let biblatex_cmd = ''
    else
        let biblatex_cmd = '--bibliography=' . bib_file
    endif
    let pandoc_cmd = 'pandoc --toc --number-sections -s ' . biblatex_cmd .  ' '
                \ . tex_file . ' -o ' .  docx_file

    " Actually convert file, echo status message and return to previous
    " working directory
    unsilent echo 'Converting  .tex file to .docx ...'
    execute '!' . pandoc_cmd
    redraw
    unsilent echo 'converted ' . tex_file . ' to ' . docx_file
    execute 'lcd ' . save_pwd
endfunction

" }}}

" }}}
" Mappings {{{

" Anon snippets for inline math, sub and supra indexes
if exists(':UltiSnipsEdit') != 0
    inoremap <buffer> <silent> $$ $$<C-R>=UltiSnips#Anon('\$${1:${VISUAL}}\$$0',
                \ '$$', '', 'i')<cr>
    inoremap <buffer> <silent> __ __<C-R>=UltiSnips#Anon('_\{${1:${VISUAL}}\}',
                \ '__', '', 'i')<cr>
    inoremap <buffer> <silent> ^& ^&<C-R>=UltiSnips#Anon('^\{${1:${VISUAL}}\}',
                \ '^&', '', 'i')<cr>
endif

" Align end of row backlashes in tables using Easy-Align plugin
if exists(':EasyAlign') != 0
    nmap <silent> <Leader>\ :execute
                \ "silent normal mz\<Plug>(EasyAlign)ip*\\`z"<CR>
    vmap <silent> <Leader>\ :mz<C-u>execute
                \ "silent normal gv\<Plug>(EasyAlign)*\\"<CR>`z
endif

" Advance through cell columns and rows
inoremap <buffer> <silent> <A-c> <Esc>f&lli
inoremap <buffer> <silent> <A-r> <Esc>j0f&hi

" Editing
nnoremap <buffer> <silent> Q :call <SID>TexParFormat()<CR>
" vnoremap <buffer> <silent> Q :call TexParFormat()<CR>

" Compilation
nnoremap <buffer> <silent> <F7> :call <SID>CompileTex()<CR>
inoremap <buffer> <silent> <F7> <ESC>:call <SID>CompileTex()<CR>
nnoremap <buffer> <silent> <Leader>rf :call <SID>CompileTex('foreground')<CR>
nnoremap <silent> <buffer> <Leader>da :call <SID>DeleteAuxFiles()<CR>
nnoremap <silent> <buffer> <Leader>db :call <SID>DeleteBiberCache()<CR>

" Linting
nnoremap <silent> <buffer> <Leader>rl :call <SID>CheckTex()<CR>

" Viewing (view pdf and search line with forward search)
nnoremap <buffer> <silent> <Leader>vp :call <SID>ForwardInverseSearch('inv')<CR>
nnoremap <buffer> <silent> <Leader>sl :call <SID>ForwardInverseSearch('for')<CR>

" Docs
nnoremap <buffer> <silent> <S-k> :call <SID>ViewDoc()<CR>

" Log preview
augroup qfviewlog
    au!
    au Filetype qf nnoremap <buffer> <silent> <Leader>vl
            \ :call <SID>ViewLog()<CR>
    au FileType qf nnoremap <buffer> <silent> <expr> j
            \ getwinvar(winnr("#"), "&pvw") ? 'j:call <SID>ViewLog()<CR>' : 'j'
    au FileType qf nnoremap <buffer> <silent> <expr> k
            \ getwinvar(winnr("#"), "&pvw") ? 'k:call <SID>ViewLog()<CR>' : 'k'
augroup END

" Open files for editing
nnoremap <buffer> <silent> <Leader>em :call <SID>EditFile('main')<CR>
nnoremap <buffer> <silent> <Leader>ep :call <SID>EditFile('preamble.tex')<CR>
nnoremap <buffer> <silent> <Leader>eb :call <SID>EditFile('*.bib')<CR>
nnoremap <buffer> <silent> <Leader>ei :call <SID>EditFile('include')<CR>
nnoremap <buffer> <silent> <Leader>ef :call <SID>EditFile('figure')<CR>
nnoremap <buffer> <silent> <Leader>ek :call <SID>EditFile('find')<CR>

" Word counting
nnoremap <buffer> <silent> <Leader>cw :call <SID>CountWords()<CR>

" Convert to docx file
nnoremap <buffer> <silent> <Leader>cx :call <SID>ConvertDocx()<CR>

" }}}
