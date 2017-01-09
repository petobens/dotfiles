"===============================================================================
"          File: vimrc
"        Author: Pedro Ferrari
"       Created: 29 Dec 2012
" Last Modified: 09 Jan 2017
"   Description: My vimrc file
"===============================================================================
" TODOs:
" Try the job feature
" Move highlight and airline colors to heraldish; see itchyny landscape.vim
" SQL support?
" Filter to convert markdown to html, useful for mails

" Preamble {{{

" Define OS variable
let s:is_win = has('win32') || has('win64')
let s:is_mac = !s:is_win && (has('mac') || has('macunix') || has('gui_macvim')
            \ || system('uname') =~? '^darwin')
let s:is_linux = !s:is_win && !s:is_mac

" Define vimfiles directory
if !has('nvim')
    if s:is_win
        let $DOTVIM = expand('$HOME/vimfiles')
    else
        let $DOTVIM = expand('$HOME/.vim')
    endif
else
    let $DOTVIM = expand('$HOME/.config/nvim')
    if s:is_mac
        " Uncomment this for Neovim HEAD version
        " let g:python3_host_prog = '/usr/local/bin/python3'
    endif
endif
let $DOTFILES = expand('$HOME/git-repos/private/dotfiles/')

" OS specific settings
if s:is_win
    let $CACHE = expand('$DOTVIM/cache/Acer')
    " Note: the following option must set after setting runtimepath. Also note
    " that it breaks the shellescape() function since cmd.exe uses double quotes
    " for command line arguments but shellslash forces single quotes. Hence it
    " also breaks dispatch!
    set shellslash
    " Set menu and messages in English in windows
    language messages en
elseif s:is_mac
    let $CACHE = expand('$DOTVIM/cache/MacBookPro')
else
    let $CACHE = expand('$DOTVIM/cache/Ubuntu')
endif

let g:mapleader = ','    " Default for mappings is now , character instead of /

" }}}
" Plugins {{{

" Auto install dein if it is not installed
if !isdirectory($DOTVIM.'/bundle/repos/github.com/Shougo/dein.vim')
    echon 'Installing dein ...'
    if !executable('git')
        echoerr 'git is not installed or not in your path.'
        finish
    endif
    cd $DOTVIM
    silent call mkdir($DOTVIM.'/bundle/repos/github.com/Shougo/dein.vim','p')
    silent !git clone https://github.com/Shougo/dein.vim
                \ ./bundle/repos/github.com/Shougo/dein.vim
    if v:shell_error
        echoerr 'dein installation has failed!'
        finish
    endif
    echo 'dein was successfully installed.'
endif

" Set runtimepath
if has('vim_starting')
    " set runtimepath=$DOTVIM,$VIMRUNTIME,$DOTVIM/after
    execute 'set runtimepath+=' . expand(
                \ '$DOTVIM/bundle/repos/github.com/Shougo/dein.vim')
endif

" Directory where plugins are placed. The function also disables filetype
" automatically

if dein#load_state(expand('$DOTVIM/bundle/'))
    call dein#begin(expand('$DOTVIM/bundle/'))

    " Normalize plugin names
    let g:dein#enable_name_conversion = 1

    " Plugins we are using
    call dein#add('vim-airline/vim-airline')
    call dein#add('itchyny/calendar.vim', {'on_cmd' : 'Calendar'})
    call dein#add('junegunn/vim-easy-align')
    call dein#add('airblade/vim-gitgutter')
    call dein#add('sjl/gundo.vim', {'on_cmd' : 'GundoToggle'})
    call dein#add('petobens/heraldish', {'frozen' : 1})
    call dein#add('Yggdroot/indentLine')
    call dein#add('vim-scripts/matchit.zip', {'name' : 'matchit'})
    call dein#add('scrooloose/nerdcommenter')
    call dein#add('justinmk/vim-sneak')
    if !s:is_win
        call dein#add('christoomey/vim-tmux-navigator')
    endif
    call dein#add('majutsushi/tagbar', {'on_cmd' : 'TagbarToggle'})
    call dein#add('SirVer/ultisnips')
    call dein#add('lervag/vimtex', {'on_ft' : ['tex', 'bib']})

    " Python
    call dein#add('davidhalter/jedi-vim', {'on_ft' : 'python'})
    call dein#add('tweekmonster/impsort.vim', {'on_ft' : 'python'})
    if has('nvim')
        call dein#add('zchee/deoplete-jedi')
    endif

    " Tim Pope plugins
    call dein#add('tpope/vim-abolish')
    call dein#add('tpope/vim-dispatch')
    call dein#add('tpope/vim-fugitive')
    call dein#add('tommcdo/vim-fubitive')
    call dein#add('tpope/vim-repeat')
    call dein#add('tpope/vim-rhubarb')
    call dein#add('tpope/vim-surround')

    " Shougo plugins
    call dein#add('Shougo/dein.vim')
    call dein#add('Shougo/denite.nvim')
    call dein#add('Shougo/unite.vim')
    call dein#add('Shougo/vimfiler', {'on_path' : '.*'})
    call dein#add('Shougo/vimshell.vim')
    " Note: We need vimproc in neovim for grep source to work
    let s:vimproc_make = 'make -f make_mac.mak'
    if s:is_win
        let s:vimproc_make = 'tools\\update-dll-mingw'
    elseif s:is_linux
        let s:vimproc_make = 'make'
    endif
    call dein#add('Shougo/vimproc.vim', {'build' : s:vimproc_make})
    if !has('nvim')
        call dein#add('Shougo/neocomplete.vim')
    else
        call dein#add('Shougo/deoplete.nvim')
        " call dein#add('Shougo/denite.nvim')
    endif
    " Unite sources
    call dein#add('Shougo/neomru.vim')
    call dein#add('Shougo/neoyank.vim')
    call dein#add('thinca/vim-unite-history')
    call dein#add('osyo-manga/unite-quickfix')
    call dein#add('kopischke/unite-spell-suggest')
    call dein#add('tsukkee/unite-tag')
    " For neocomplete
    call dein#add('Shougo/context_filetype.vim')
    call dein#add('Shougo/echodoc.vim')
    call dein#add('Shougo/neco-vim', {'name' : 'neco-vim'})
    call dein#add('Shougo/neco-syntax')
    call dein#add('Shougo/neoinclude.vim')

    call dein#end()
    call dein#save_state()
endif

" Set file type stuff to on
filetype plugin indent on

" Check if all plugins are installed and ask to install those that are not
" installed
if dein#check_install()
    call dein#install()
endif

" }}}
" Options  {{{

" Backups and undo {{{

" What things Vim saves and restores (sessions)
set viewoptions=cursor,folds,unix,slash
set viewdir=$CACHE/tmp/view
set sessionoptions-=options,tabpages
set sessionoptions+=winpos,resize

function! s:SaveSession()
    let session_dir = $CACHE . '/tmp/session/'
    silent! call s:MakeDirIfNoExists(session_dir)
    execute 'mksession! ' . session_dir . 'vim_session.vim'
endfunction

" Save and load viewoptions and previous session
augroup session
    au!
    au VimLeave * call s:SaveSession()
    au BufWinLeave {*.*,vimrc,pentadactylrc}  mkview
    au BufWinEnter {*.*,vimrc,pentadactylrc}  silent! loadview
augroup END
nnoremap <silent> <Leader>ps :so $CACHE/tmp/session/vim_session.vim<CR>

" Change viminfo directory
if !has('nvim')
    set viminfo+=n$CACHE/tmp/viminfo
endif

" Set how many lines of ":" command and search patterns VIM has to remember
set history=1000

" Use the regular system clipboard for all yank, delete, change and put
" operations and automatically yank visually selected text
if !has('nvim')
    if s:is_win || s:is_mac
        set clipboard=autoselect,unnamed
    elseif s:is_linux && has('unnamedplus')
        " On linux with X11 use the + register (i.e the CLIPBOARD and not the
        " PRIMARY register). On tmux use `xsel -i -b` to be consistent with this.
        set clipboard=autoselectplus,unnamedplus
    endif
else
    set clipboard=unnamed
    " This mimicks autoselect in neovim
    vmap <Esc> "*ygv<C-c>
endif

" Persistent undo (i.e vim remembers undo actions even if file is closed and
" reopened)
set undofile
set undolevels=1000   " Maximum number of changes that can be undone
set undoreload=10000  " Maximum number lines to save for undo on a buffer reload

set undodir=$CACHE/tmp/undo//

set backup          " Enable backups
" set noswapfile
" Always open read-only when a swap file is found
" autocmd vimrc SwapExists * let v:swapchoice = 'o'

" Store swap files and backups in one of these directories
set directory=$CACHE/tmp/swap//
set backupdir=$CACHE/tmp/backup//

" Make those directories (and intermediate ones) if they don't exist
function! s:MakeDirIfNoExists(path)
    if !isdirectory(expand(a:path))
        call mkdir(expand(a:path), 'p')
    endif
endfunction

silent! call s:MakeDirIfNoExists(&undodir)
silent! call s:MakeDirIfNoExists(&directory)
silent! call s:MakeDirIfNoExists(&backupdir)

" }}}
" Color scheme and syntax highlighting {{{

" Enable syntax highlighting
syntax enable

if !has('gui_running')
    if s:is_win
        " ConEmu settings on Windows (for Mac we don't need to set the term
        " variable explicitly since it is read from $TERM env variable)
        set term=xterm
        set t_Co=256
        let &t_AB="\e[48;5;%dm"
        let &t_AF="\e[38;5;%dm"
    else
        " Use guicolors in the terminal (this requires iTerm 2.9 and tmux 2.2)
        set termguicolors
    endif
endif

" Colorscheme
if dein#check_install(['heraldish']) == 0
    colorscheme heraldish
endif

" Reload the colorscheme when we write the color file in order to see changes
augroup color_heraldish
    au!
    au BufWritePost heraldish.vim source $DOTVIM/vimrc
    au BufWritePost heraldish.vim colorscheme heraldish
augroup END

" Highlight todos colons in red
set iskeyword+=:
augroup hl_todos
    au!
    " FIXME: Bib highlight (and sometimes others too) not working?
    " Also note that if I change hl color from heraldish it is not updated.
    au BufNewFile,BufRead *.bib syn match bibTodo "\<\(TODO\|FIXME\):"
    au BufNewFile,BufRead *.py syn match pythonTodo "\<\(TODO\|FIXME\):"
    au BufNewFile,BufRead *.snippets syn match snipTODO "\<\(TODO\|FIXME\):"
    au BufNewFile,BufRead *.tex syn match texTodo "\<\(TODO\|FIXME\):"
    au BufNewFile,BufRead {*.vim,vimrc} syn match vimTodo "\<\(TODO\|FIXME\):"
augroup END

" }}}
" Command line and Vim behaviour {{{

" Make ; work like : to enter command mode (avoids holding shift)
noremap ; :

" Disable modelines (options for a particular file) due to security exploits
set nomodeline

" Show filename and path in window title (even in terminal)
set title

" Show the command being typed
set showcmd

" Make command line two lines high
set cmdheight=2
" Reduce maximum height of the command line window (default is 7)
set cmdwinheight=5

" Don't update the display while executing macros
set lazyredraw
" Improve scrolling and redrawing in terminal
if !has('nvim')
    set ttyfast
endif

" Set visual bell (no beeping on errors)
set visualbell
" Abbreviations of messages and avoid 'hit enter' prompt
set shortmess=aoOtTIc
" Ask for confirmation (instead of aborting an action)
set confirm

" Shorten default to time to update swap files and gutter plugins
set updatetime=500
" Time in milliseconds waited for a mapping to complete
set timeoutlen=550
" Time in milliseconds waited for a key code to complete
set ttimeoutlen=0

" }}}
" Encoding and fileformat {{{

set encoding=utf-8

" Use unix conventions for line endings (even in MS Windows)
set fileformat=unix
set fileformats=unix,dos

" Improve font rendering on Windows
if !has('nvim')
    if s:is_win
        set renderoptions=type:directx,gamma:1.2,level:1,geom:1,renmode:5,taamode:1
    endif
endif

" }}}
" Folding {{{

set foldlevelstart=0          " Start with everything folded
set foldopen+=insert,jump     " Commands that auto-unfold

" Close all folds and open and focus on fold containing current line
nnoremap <Leader>z zMzvzz
" Make zm and zr work as zM and zR respectively
nnoremap zm zM
nnoremap zr zR

" Map to use marker folding
nnoremap <silent> <Leader>mf :set foldmethod=marker<CR>zv

" }}}
" Read and write (buffers) {{{

" Set to auto read when a file is changed from the outside
set autoread

" Save when buffer command takes one to another file and when losing focus
set autowrite
augroup focus_lost
    au!
    au FocusLost * silent! wall
augroup END
" Allow unsaved buffers to be put on the background without saving
set hidden

" }}}
" Search, jumps and matching pairs {{{

if executable('ag')
    set grepprg=ag\ --smart-case\ --line-numbers\ --nocolor\ --nogroup\ --follow
endif

" Use sane (Perl/Python like) regexes (very magic): all characters except
" [0-9a-zA-z_] should be escaped to match them literally
set magic
nnoremap / /\v
vnoremap / /\v
nnoremap ? ?\v
vnoremap ? ?\v

" Case insensitive search (* search remains case sensitive)
set ignorecase
" Case sensitive when upper case present
set smartcase
" Find as you type search phrase
set incsearch
" Highlight search terms
set hlsearch
" Clear the highlighted search register
noremap <silent> <Leader><space> :nohlsearch<cr>:call clearmatches()<cr>

" Set the search scan to wrap lines
set wrapscan
" Apply substitutions on all matches in a line and not just the first one (if g
" flag is added the option is toggled i.e only first match is substituted)
set gdefault

" Don't jump to first match when searching with * and #
nmap * *<C-o>
nmap <kMultiply> <kMultiply><C-o>
nmap # #<C-o>

" Keep search matches and jumps in the middle of the window (zv allows it to
" work with folds)
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-o> <C-o>zz

" Change quote and back tick for easy navigation to marks
noremap ' `
" Delete all marks
nnoremap <Leader>dm :delmarks!<CR>:delmarks A-Z0-9<CR>

" Use <tab> to move between bracket pairs (related to matchit plugin)
map <tab> %
" Show matching brackets/parenthesis and briefly jump to matching pair
set showmatch
" How many tenths of a second to blink when showing matching pair
set matchtime=1

" }}}
" Spelling and abbreviations {{{

" Disable spell checking but have mapping to toggle it
set nospell
nnoremap <silent> <Leader>sc :set spell!<CR>

" Dictionaries
set spelllang=en,es
set spellfile=$DOTVIM/spell/custom-dictionary.utf-8.add
nnoremap <silent> <Leader>ew :e $DOTVIM/spell/custom-dictionary.utf-8.add<CR>

" Spell suggest and spell fix (replaces all words with same spelling mistake)
nnoremap <silent> <Leader>sg :Unite -default-action=replace_all
            \ spell_suggest<CR>
nnoremap <silent> <Leader>sf k$]s :Unite -default-action=replace_all
            \ spell_suggest<CR>

" Edit abbreviations quickly (with abolish plugin)
nnoremap <silent> <Leader>ea :e $DOTVIM/after/plugin/abolish.vim<CR>

" }}}
" Text, tab and indent {{{

" Wrap long lines (i.e break them if they are too long; see also formatoptions)
set  wrap
" Wrap lines at convenient spaces (for instance don't break words)
set linebreak
" Indent wrapped lines at the indentation level of the line itself (i.e soft
" wrapping with proper indentation)
set breakindent

" Set the textwidth to be 80 chars
set textwidth=80

" Highlight column after textwidth
set colorcolumn=+1

" Display as much as possible of the last line
set display=lastline

" Where it makes sense, remove comment leader when joining lines
set formatoptions+=j

" Allow backspacing over everything in insert mode
set backspace=indent,eol,start
" Allow specified keys that move the cursor left/right to move to the
" previous/next line when the cursor is on the first/last character in the line
set whichwrap+=<,>,h,l,[,]

" Wrapped lines goes down/up to next row rather than next line in file
nnoremap j gj
nnoremap k gk

" Don't show invisible characters
set nolist
" Toggle [i]nvisible characters
nnoremap <Leader>i :set list!<cr>
" If shown (it disables linebreak option) use the following symbols for
" tabstops, end of lines, etc
set listchars=tab:▸\ ,eol:¬,trail:.,extends:»,precedes:«,nbsp:.

" Tab settings
set tabstop=4      " A tab is four columns
set shiftwidth=4   " Number of spaces to insert for reindent (e.g <<, >>, ==)
set softtabstop=4  " Tabs in insert mode are 4 columns
set expandtab      " Insert space characters instead of hardtabs
set shiftround     " Round indent to the next multiple of sw (for >,< commands)

" Indentation
set autoindent     " Indent at the same level of the previous line

" }}}
" Wildmenu {{{

set wildmenu                         " Better command-line completion with tab
set wildignorecase                   " Ignore case
set wildmode=full                    " Show a list and complete first full match
" Stuff to ignore when tab completing
set wildignore=*.ini,*~,*.o,*.obj,*.dll,*.dat,*.swp,*.zip,*.exe
set wildignore+=*.DS_Store,*.out,*.toc

" }}}
" Windows, line numbers and cursor {{{

" Resize splits when the Vim window is resized
augroup vim_resized
    au!
    au VimResized * :wincmd =
augroup END

" Put new split window right and below of the current one
set splitright
set splitbelow

" Show number lines (this allow the cursor line to show the absolute line
" number)
set number
" Set line numbering relative to current line (except for the current line)
set relativenumber

" Only show cursorline in the current window
set cursorline
augroup cline
    au!
    au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
    au WinLeave * setlocal nocursorline
augroup END

" When the page starts to scroll, keep the cursor 3 lines from the top and 3
" lines from the bottom
set scrolloff=3
" Toggle 'keep current line in the center of the screen' mode
nnoremap <Leader>C :let &scrolloff=999-&scrolloff<cr>

" Allow the cursor to be positioned anywhere (in block mode) (Note: setting to
" 'all' breaks placeholders position in Ultisnips)
set virtualedit=block,onemore

" }}}

" }}}
" Key (Re)Mappings {{{

" Normal mode {{{

" Movement {{{

" Disable arrow keys (Note: noremap also affects visual/select and operator
" pending modes)
noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>

" Move to the first non-blank character and to the end of line (this overrides
" movement to the first and last line on the window)
noremap H ^
noremap L $

" Move to the middle of the line (overrides movement to the middle of the
" window)
nnoremap <silent> M :execute 'normal! ' . (virtcol('$')/2) . '\|'<CR>

" Use alt to replace the original mappings to move to the top, middle and bottom
" of window
nnoremap <A-t> H
nnoremap <A-m> M
nnoremap <A-b> L

" Move to the end of the line when using G (and open existing fold)
nnoremap <silent> G Gzo$

" }}}
" Word, line and paragraph operations {{{

" Swap current word with previous one (push word to the left)
nnoremap <silent> <A-h> "_yiw?\k\+\%(\k\@!\_.\)\+\%#<CR>
            \:s/\(\%#\k\+\)\(\%(\k\@!\_.\)\+\)\(\k\+\)/\3\2\1/<CR>
            \<c-o><c-l>:noh<CR>
" Swap current word with the next one (push word to the right)
nnoremap <silent> <A-l> "_yiw:s/\(\%#\k\+\)\(\%(\k\@!\_.\)\+\)\(\k\+\)/\3\2\1/
            \<CR><c-o>/\k\+\%(\k\@!\_.\)\+<CR><c-l>:noh<CR>

" Move lines up/down (and reindent afterwards)
nnoremap <silent> <A-j> :<C-U>silent execute 'move+' . v:count1<CR>zO==
nnoremap <silent> <A-k> :<C-U>silent execute 'move--' . v:count1<CR>zO==

" Keep the cursor in place while joining lines
nnoremap J mzJ`z
" Split line (sister to [J]oin lines; S is used by sneak plugin)
nnoremap <silent> <A-s> i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w

" Select the contents of the current line, excluding indentation.
nnoremap vv ^vg_

" Use Q for formatting the current paragraph (and restoring cursor position)
" Note: Q is originally map to enter Ex mode
nnoremap Q gwap

" Sort alphabetically ignoring case
nnoremap <Leader>sa :sort i<CR>

" Upper case inner word (one can toggle a visual selection case with ~)
nnoremap <A-u> mzgUiw`z

" Search and replace
nnoremap <Leader>sr :%s/

" Increment and decrement
nnoremap + <C-a>
nnoremap - <C-x>

" }}}
" Window and buffer manipulation {{{

" Change window easily
nnoremap <C-j> <C-w>j
nnoremap <C-h> <C-w>h
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Increase/decrease size and width (left, down, up and right) using ctrl-alt
nnoremap <C-A-h> <C-w>2<
nnoremap <C-A-j> <C-w>2+
nnoremap <C-A-k> <C-w>2-
nnoremap <C-A-l> <C-w>2>

" Horizontal and vertical splits
nnoremap <silent> <Leader>sp :split<CR>
nnoremap <silent> <Leader>vs :vsplit<CR>

" Close windows easily
nnoremap <C-c> <C-w>c

" Switch windows easily
nnoremap <C-x> <C-w>xzz

" Make current window the only one on screen
nnoremap <A-o> <C-w>ozv

" New buffer in vertical or horizontal split
function! s:NewBuffer()
    let buf_dir = 'vnew'
    if winwidth(0) <= 2 * (&tw ? &tw : 80)
        let buf_dir = 'new'
    endif
    execute buf_dir
endfunction
nnoremap <silent> <Leader>nb :call <SID>NewBuffer()<CR>

" Ask for filename and filetype of a new (D)ocument to be edited in (D)esktop
nnoremap <Leader>dd :e $HOME/Desktop/

" Delete window and buffer
nnoremap <silent> <Leader>wd :bd<CR>
" Delete buffer but preserve window
nnoremap <silent> <Leader>bd :bp\|bd #<CR>
" Switch buffers (we don't use Ctrl + Tab because when working inside a terminal
" this is what is generally used to switch between terminal tabs)
noremap <silent> <C-n> :bn<CR>
noremap <silent> <C-p> :bp<CR>

" Resize window as a 'popup'
nnoremap <silent><Leader>pu :wincmd J<bar>15 wincmd _<CR>

" When following a file open it in a split window
function! s:GoToFileSplit()
    if winwidth(0) <= 2 * (&tw ? &tw : 80)
        wincmd f
    else
        vertical wincmd f
    endif
endfunction
nnoremap <silent> gf :call <SID>GoToFileSplit()<CR>

" }}}
" Write, save and quit {{{

" Kill vim (unless there are unsaved buffers)
nnoremap <silent> <Leader>kv :qall<cr>

" Fast saving
nnoremap <Leader>w :w!<CR>
" Save and close window
nnoremap <Leader>wc :w!<CR><C-w>c
" Save and quit
nnoremap <Leader>wq :w!<CR>:q!<CR>
" No autocommand write
nnoremap <Leader>nw :noautocmd w!<CR>

" Fast editing and reloading of the vimrc file
nnoremap <silent> <Leader>ev :e $DOTFILES/vimrc<CR>
nnoremap <silent> <Leader>rv :so $DOTFILES/vimrc<CR>
nnoremap <silent> <Leader>em :e $DOTFILES/vim/vimrc_min<CR>

" Change working directory to that of the current file (autochdir seems to
" conflict with some plugins)
nnoremap <silent> <Leader>cd :lcd %:h<CR>

" Source current file
nnoremap <Leader>so :update<CR>:so %<CR>

" Fix line endings (carriage return)
nnoremap <silent> <Leader>fl :%s/\r$//<CR>

" Reread (i.e reload) all buffers (useful when git pulling)
nnoremap <silent> <Leader>rr :checktime<CR>

" Execute help
nnoremap <S-k> :execute 'help ' . expand('<cword>')<cr>

" }}}
" Yank, paste and delete {{{

" Delete without saving to register (useful for pasting)
noremap du "_d
noremap duu "_dd
" Make Y consistent with C and D
noremap Y y$
" Ignore end of line character (carriage return, ^M) when yanking with yy
noremap yy mz0y$`z

" Pastetoggle doesn't redraw the screen (thus the status bar doesn't change)
" :set paste! does, so we use that (paste mode disables automatic reindenting)
nnoremap <silent> <F12> :set paste!<cr>

" Visually reselect what was just pasted (gv reselects previous selection)
nnoremap <expr> <Leader>V '`[' . strpart(getregtype(), 0, 1) . '`]'

" Yank error messages to system clipboard
nnoremap <silent> <Leader>ym :redir @*\|messages\|:redir END<CR>

" Yank output of a command
function! s:YankOutput()
    redir @*
    let cmd = input('Enter command whose output will be yanked: ')
    silent execute cmd
    redir END
endfunction
nnoremap <silent> <Leader>yo :call <SID>YankOutput()<CR>

" }}}

" }}}
" Insert mode {{{

" Use jj to exit insert mode
inoremap jj <ESC>

" Disable arrow keys
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Move left and right
inoremap <C-l> <C-o>l
inoremap <C-h> <C-o>h

" Move lines up and down
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi

" Paste system clipboard
inoremap <A-p> <C-R>*

" Change case (it overwrites contents of z mark): use it at end of word
inoremap <A-u> <esc>mzgUiw`za
inoremap <A-l> <esc>mzguiw`za

" }}}
" Visual mode {{{

" Use Q  to format selection (as in normal mode)
vnoremap Q gq
" Visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" Go the last non-blank character in the line (as in normal mode)
vnoremap L g_

" Go the middle of the line (as in normal mode)
vnoremap <silent> M :<c-u>execute 'normal! gv' . (virtcol('$')/2) . '\|'<CR>

" Move lines up and down
vnoremap <A-j> :<C-U>exe '''<,''>move''>+'.v:count1<CR>gv=gv
vnoremap <A-k> :<C-U>exe '''<,''>move--'.v:count1<CR>gv=gv

" Repeat command for each line in selection
vnoremap . :normal .<CR>

" Search and replace
vnoremap <Leader>sr :s/

" Increment and decrement
vnoremap + <C-a>
vnoremap - <C-x>

" Sort alphabetically ignoring case
vnoremap <Leader>sa :sort i<CR>

" Move to the end of the line when using G
vnoremap <silent> G G$

" }}}
" Command mode {{{

" Emacs bindings in command line mode (beginning and end of line)
cnoremap <c-a> <home>
cnoremap <c-e> <end>

" Move left and right
cnoremap <c-h> <left>
cnoremap <c-l> <right>

" Insert the directory of the current buffer in command line mode
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:p:h') . '/' : '%%'

" Paste system clipboard to command line
" Note: to yank a commmand, call Unite history/yank + <C-y> (yank action)
cnoremap <A-p> <C-R>*

" Saving when root privileges are required (use :w!! to sudo and write)
if s:is_mac || s:is_linux
    cnoremap w!! w !sudo tee % >/dev/null
endif

" }}}

" }}}
" Filetype-specific {{{

" Autohotkey / Hammerspoon {{{

augroup ft_ahk_hs
    au!
    au Filetype autohotkey setlocal commentstring=;%s foldmethod=marker
    au BufNewFile,BufRead,BufReadPost init.lua setlocal foldmethod=marker
augroup END

if s:is_mac
    nnoremap <silent> <Leader>eh :e $DOTFILES/hammerspoon/init.lua<CR>
else
    nnoremap <silent> <Leader>eh :e $DOTFILES/autohotkey.ahk<CR>
endif

" }}}
" Bash {{{

augroup ft_bash
    au!
    au BufNewFile,BufReadPost bash_profile set filetype=sh foldmethod=marker
augroup END

" }}}
" Bibtex {{{

augroup ft_bib
    au!
    au Filetype bib setlocal commentstring=%%s foldmethod=marker
    au Filetype bib setlocal spell
    au Filetype bib setlocal shiftwidth=2 tabstop=2 softtabstop=2
augroup END

" }}}
" Crontab {{{

augroup ft_crontab
    au!
    au FileType crontab set nobackup nowritebackup
augroup END

" }}}
" Javascript {{{

augroup ft_js
    au!
    au Filetype javascript setlocal commentstring=//%s
augroup END

" }}}
" (La)TeX {{{

" Note: Most LaTeX settings are in the ftplugin folder
if s:is_win
    set isfname-={,}   " Remove braces to allow jumping to input files with gf
endif

" Tex generic settings
let g:tex_flavor = 'latex'          " Filetype detection
let g:tex_conceal = ''              " Don't replace characters by Unicode glyphs
let g:tex_comment_nospell = 0       " Allow spell checking in comments

" Indent settings (provided by Vim indent file)
let g:tex_indent_items = 1          " Continuation lines have shiftwidth
let g:tex_items = '\\item'          " Redundant since we set indentkeys below
let g:tex_itemize_env = 'itemize\|enumerate\|steps'
let g:tex_indent_brace = 0

augroup ft_tex
    au!
    au FileType tex setlocal iskeyword=@,48-57,_,192-255,:
    au FileType tex setlocal comments+=b:\\item
    " Don't reindent when typing brackets, parenthesis, braces or ampersands:
    au FileType tex setlocal indentkeys=!^F,o,O,0=\\item
    " Highlight dmath environments as equation environments
    au FileType tex call TexNewMathZone("M","dmath",1)
    " Set dictionary in neovim (for deoplete)
    if has('nvim')
        au FileType tex setlocal
                \ dictionary=$DOTVIM/ftplugin/tex/tex_dictionary.dict
    endif
augroup END

" }}}
" Gauss {{{

augroup ft_gauss
    au!
    au BufNewFile,BufReadPost *.{prg,g,gss,src,e} set filetype=gauss
    au Filetype gauss setlocal commentstring=//%s
    au FileType gauss setlocal iskeyword-=:

    " Vimshell interpreter settings
    au FileType int-tgauss setlocal filetype=int-gauss.gauss
    au Filetype int-tgauss syn match gaussIntPrompt "^(gauss)"
    au Filetype int-tgauss hi def link gaussIntPrompt Statement
augroup END

" }}}
" Mail {{{

augroup ft_mail
    au!
    au Filetype mail setlocal formatoptions=ta
    au Filetype mail setlocal textwidth=72
    au Filetype mail setlocal spell
augroup END

" }}}
" Markdown/Html {{{

" Note: Most Markdown settings are in ftplugin folder
augroup ft_markdown
    au!
    au BufNewFile,BufReadPost *.md set filetype=markdown
    au FileType markdown setlocal omnifunc=htmlcomplete#CompleteTags
    au FileType html nnoremap <buffer><silent> <F7> :silent! ! start %<CR>
augroup END

" }}}
" Matlab {{{

" Note: Most Matlab settings are in the ftplugin folder
augroup ft_matlab
    au!
    au Filetype matlab setlocal commentstring=%%s
    au FileType matlab setlocal iskeyword-=:
augroup END

" }}}
" Pentadactyl {{{

augroup ft_pentadactyl
    au!
    au BufNewFile,BufRead *pentadactylrc*,*.penta set filetype=pentadactyl
    au Filetype pentadactyl setlocal commentstring=\"%s comments=:\"
    au FileType pentadactyl setlocal foldmethod=marker
augroup END

nnoremap <silent> <Leader>ep :e $DOTFILES/pentadactylrc<CR>

" }}}
" Python {{{

" Note: Most python settings are in ftplugin folder

" Don't fold docstrings; see ftplugin/python/folding.vim
let g:SimpylFold_fold_docstring = 0

augroup ft_py
    au!
    " Fix else: syntax highlight and comment string
    au FileType python setlocal iskeyword-=:
    au Filetype python setlocal commentstring=#%s
    " Python notebooks are json files
    au BufNewFile,BufReadPost *.ipynb set filetype=json

    " Vimshell python interpreter settings
    " TODO: Open interactive repls as popups (-popup flag doesn't work)
    " Set filetype
    au FileType int-python setlocal filetype=int-python.python
    " Since jedi omnifunc doesn't seem to work with the vimshell interpreter we
    " change the omnifunc
    au FileType int-python.python setlocal omnifunc=python3complete#Complete
    " Syntax groups
    au Filetype int-python.python syn match PyIntInit "\python\_.*information."
    au Filetype int-python.python syn match PyIntPrompt "^>>>"
    au Filetype int-python.python syn match PyIntError "^\w\+Error:\s.\+$"
    " Highlight
    au Filetype int-python.python hi def link PyIntInit Normal
    au Filetype int-python.python hi def link PyIntPrompt Statement
    au Filetype int-python.python hi def link PyIntError Error

    " Highlight all python functions
    au Filetype python syn match pythonAttribute2 /\.\h\w*(/hs=s+1,he=e-1
    au Filetype python hi def link pythonAttribute2 Function
augroup END

" }}}
" QuickFix {{{

" Note: here we also include preview window settings

augroup ft_quickfix
    au!
    au Filetype qf setlocal colorcolumn="" textwidth=0 wincmd J
    au Filetype qf call s:AdjustWindowHeight(1, 15)
    au Filetype qf nnoremap <buffer><silent> q :bdelete<CR>
    au Filetype qf nnoremap <buffer><silent> Q :bdelete<CR>
augroup END

" Automatically adjust window to fit content
function! s:AdjustWindowHeight(minheight, maxheight)
    execute max([min([line('$'), a:maxheight]), a:minheight]) . 'wincmd _'
endfunction

" Maps
nnoremap <silent> <Leader>pc :pclose<cr>
nnoremap <silent> <Leader>qf :copen<cr>
nnoremap <silent> <Leader>qc :cclose<cr>
nnoremap <silent> ]q :<C-U>execute v:count1 . 'cnext'<CR>
nnoremap <silent> [q :<C-U>execute v:count1 . 'cprevious'<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>

" }}}
" R {{{

" Use syntax folding (this is defined in syntax/r.vim)
" let r_syntax_folding = 1

augroup ft_R
    au!
    " Set the .Rprofile to R
    au BufNewFile,BufRead {Rprofile,.Rprofile,*.R} set filetype=r
    " Vimshell R interpreter settings
    au FileType int-R setlocal filetype=int-R.r  " Fix highlighting
    " Syntax groups
    au Filetype int-R.r syn match RIntInit "\R\_.*R."
    au Filetype int-R.r syn match RIntPrompt "^>>>"
    au Filetype int-R.r syn match RIntOut "\[1\]"
    " Highlight
    au Filetype int-R.r hi def link RIntInit Normal
    au Filetype int-R.r hi def link RIntPrompt Statement
    au Filetype int-R.r hi def link RIntOut Identifier
augroup END

" }}}
" Snippets {{{

augroup ft_snippets
    au!
    au FileType snippets setlocal foldmethod=marker foldmarker=**{,**}
    " Use tab instead of spaces because snippets expand to current tab settings
    au FileType snippets setlocal noexpandtab
augroup END

" }}}
" SQL {{{

let g:sql_type_default = 'postgresql'

augroup ft_sql
    au!
    au Filetype sql setlocal commentstring=--%s
    au Filetype sql setlocal shiftwidth=2 tabstop=2 softtabstop=2
    " Add highlighting of some keywords (presto specific)
    au Filetype sql syn keyword sqlKeyword INNER RIGHT LEFT OUTER JOIN OVER
                \ PARTITION
    au Filetype sql syn keyword sqlFunction DATE_PARSE DATE_DIFF DATE_TRUNC
                \ LAG ARBITRARY COUNT_IF LEAD
augroup END

" }}}
" Text {{{

augroup ft_text
    au!
    au Filetype text setlocal spell
    au Filetype text setlocal shiftwidth=2 tabstop=2 softtabstop=2
    " au FileType text setlocal foldmethod=marker
    au Filetype text syn match txtURL "\(http\|www\.\)[^ ]*"
    au Filetype text nnoremap <buffer><silent><Leader>ct
                \ :call <SID>CheckMissingTask('check')<CR>
    au Filetype text nnoremap <buffer><silent><Leader>mt
                \ :call <SID>CheckMissingTask('missing')<CR>
augroup END

function! s:CheckMissingTask(symbol)
    normal! mz
    let check_symbol = 'u2714'
    let cross_symbol = 'u2718'
    " Remove previous symbols and whitespace
    execute 's/\s\+\(\%' . check_symbol. '\|\%' . cross_symbol .'\)//ge'
    if a:symbol ==# 'check'
        execute "normal! 0A\<space>\<C-V>" . check_symbol
    else
        execute "normal! 0A\<space>\<C-V>" . cross_symbol
    endif
    normal! `z
endfunction

" }}}
" Vim {{{

augroup ft_vim
    au!
    " Set fold method
    au FileType vim setlocal foldmethod=marker
    " Don't insert comment leader automatically
    au FileType vim setlocal formatoptions-=ro

    " Help settings
    au FileType help setlocal textwidth=78
    " Place help window at the bottom
    au BufWinEnter *.txt if &ft == 'help' | wincmd J | endif
augroup END

" }}}

" }}}
" Plugin settings {{{

" Airline {{{

" Vim settings
set laststatus=2                " Always show the statusline
set noshowmode                  " Don't show the current mode

" Powerline-like appearance
let g:airline_theme = 'powerline'
let g:airline_powerline_fonts = 1

" Short form mode text
let g:airline_mode_map = {
    \ '__' : '-',
    \ 'n'  : 'N',
    \ 'i'  : 'I',
    \ 'R'  : 'R',
    \ 'c'  : 'C',
    \ 'v'  : 'V',
    \ 'V'  : 'V-L',
    \ '' : 'V-B',
    \ 's'  : 'S',
    \ 'S'  : 'S-L',
    \ '' : 'S-B',
    \ }

if dein#check_install(['airline']) == 0
    " Change spacing of line and column number
    call airline#parts#define_raw('linenr', '%l')
    call airline#parts#define_accent('linenr', 'bold')
    let g:airline_section_z = airline#section#create(['%3p%%  ',
                \ g:airline_symbols.linenr . '  ', 'linenr', ':%c '])
endif

" Check for trailing whitespace and mixed (tabs and spaces) indentation
let g:airline#extensions#whitespace#checks = ['trailing', 'indent']
let g:airline#extensions#whitespace#symbol = 'Ξ'

" Disable word count
let g:airline#extensions#wordcount#enabled = 0

" Tabline (minibufexpl replacement)
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'
let g:airline#extensions#tabline#buffer_min_count = 2
let airline#extensions#tabline#disable_refresh = 1
" Don't show vimshell in the tabline because it flickers (and denite)
let g:airline#extensions#tabline#excludes = ['vimshell', 'denite']

" Show superindex numbers in tabline that allow to select buffer directly
let g:airline#extensions#tabline#buffer_idx_mode = 1
nmap <silent> <Leader>1 <Plug>AirlineSelectTab1
nmap <silent> <Leader>2 <Plug>AirlineSelectTab2
nmap <silent> <Leader>3 <Plug>AirlineSelectTab3
nmap <silent> <Leader>4 <Plug>AirlineSelectTab4
nmap <silent> <Leader>5 <Plug>AirlineSelectTab5
nmap <silent> <Leader>6 <Plug>AirlineSelectTab6
nmap <silent> <Leader>7 <Plug>AirlineSelectTab7
nmap <silent> <Leader>8 <Plug>AirlineSelectTab8
nmap <silent> <Leader>9 <Plug>AirlineSelectTab9

" }}}
" Calendar {{{

" TODO: Sort tasklist alphabetically?
" Improve mappings: create tasklist, move between them, delete task

function! s:RefreshCal()
    let timestamp_dir = g:calendar_cache_directory . '/timestamp'
    let file_list = globpath(timestamp_dir,'*', 0, 1)
    if empty(timestamp_dir)
        return
    endif
    " Delete Google calendar cache if not empty
    for item in file_list
        if exists(':VimProcBang') && s:is_win
            call vimproc#delete_trash(item)
        else
            execute delete(item)
        endif
    endfor
endfunction

let g:calendar_first_day = 'monday'
let g:calendar_date_endian = 'little'
let g:calendar_date_month_name = 1
let g:calendar_date_separator = ' '
let g:calendar_views = ['year', 'month', 'week', 'agenda', 'day_2']
let g:calendar_week_number = 1
let g:calendar_date_full_month_name = 1
let g:calendar_time_zone = '-03:00'
let g:calendar_task_delete = 1
let g:calendar_google_calendar = 1
let g:calendar_google_task = 1
let g:calendar_cache_directory = $CACHE . '/plugins/calendar'

" Maps
nnoremap <silent> <Leader>ca :call <SID>RefreshCal()<CR>:Calendar -task
            \ -split=horizontal -position=below<CR>:wincmd J<bar>50 wincmd _<CR>

augroup ps_calendar
    au!
    au FileType calendar call s:calendar_settings()
augroup END

function! s:calendar_settings()
    " Hide task list and event list with q; exit with Q
    nmap <buffer> q <Plug>(calendar_escape)
    " Change view
    nmap <buffer> H <Plug>(calendar_view_left)
    nmap <buffer> L <Plug>(calendar_view_right)
    " Move events/tasks up and down
    nmap <buffer> <A-j> <Plug>(calendar_move_down)
    nmap <buffer> <A-k> <Plug>(calendar_move_up)
    " Change window
    nmap <buffer> <C-k> <C-w>k
endfunction

" }}}
" Dein {{{

" Note: Unlike neobundle we need to run `Unite dein/log` manually once the
" update finishes

let g:dein#install_log_filename = $CACHE . '/plugins/dein/dein.log'
let g:dein#install_max_processes = 16

" Function to open unite buffer with updates after update finishes
function! s:dein_update()
  call dein#update()
  Unite dein/log:!
endfunction

" Maps
nnoremap <silent> <Leader>ul :execute "edit +" g:dein#install_log_filename<CR>
nnoremap <Leader>bu :call <SID>dein_update()<CR>
nnoremap  <Leader>rp :call dein#recache_runtimepath()<CR>
nnoremap <silent> <Leader>bl :Unite dein<CR>

" }}}
" Denite {{{

" Change default UI
call denite#custom#option('default', 'prompt', '❯')
call denite#custom#option('default', 'prompt_highlight', 'Identifier')
call denite#custom#option('default', 'auto_resize', 1)
call denite#custom#option('default', 'statusline', 1)
call denite#custom#option('default', 'winheight', 15)
call denite#custom#option('default', 'reversed', 1)
call denite#custom#option('default', 'highlight_matched_char', 'Identifier')
call denite#custom#option('default', 'highlight_matched_range', 'Normal')

" Change default matcher and sorter
call denite#custom#source('default', 'matchers', ['matcher_fuzzy',
        \ 'matcher_ignore_globs'])
call denite#custom#source('line', 'matchers', ['matcher_regexp'])
call denite#custom#source('default', 'sorters', ['sorter_sublime'])

" Ignore some files and directories
call denite#custom#filter('matcher_ignore_globs', 'ignore_globs',
        \ ['.git/', '__pycache__/', 'venv/',  'tmp/', 'doc/'])

" Buffer source settings
call denite#custom#var('buffer', 'date_format', '')

" Use ag for file_rec and grep
if executable('ag')
	call denite#custom#var('file_rec', 'command',
        \ ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])
	call denite#custom#var('grep', 'command', ['ag'])
	call denite#custom#var('grep', 'default_opts',
        \ ['--smart-case', '--vimgrep', '--follow', '--ignore', "'.git'"])
	call denite#custom#var('grep', 'recursive_opts', [])
    call denite#custom#var('grep', 'pattern_opt', [])
	call denite#custom#var('grep', 'separator', ['--'])
	call denite#custom#var('grep', 'final_opts', [])
endif

" Mappings
nnoremap <silent> <Leader>dr :Denite -resume<CR>
nnoremap <silent> ]d :<C-U>execute 'Denite -resume -select=+'. v:count1 .
            \ '--immediately'<CR>
nnoremap <silent> [d :<C-U>execute 'Denite -resume -select=-'. v:count1 .
            \ '--immediately'<CR>

" Prompt Mappings
call denite#custom#map('insert', '<ESC>', '<denite:quit>',
    \ 'noremap')
call denite#custom#map('insert', 'jj', '<denite:enter_mode:normal>',
    \ 'noremap')
call denite#custom#map('insert', '<C-j>', '<denite:move_to_next_line>',
    \ 'noremap')
call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>',
    \ 'noremap')
call denite#custom#map('insert', '<C-k>', '<denite:move_to_previous_line>',
    \ 'noremap')
call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>',
    \ 'noremap')
call denite#custom#map('insert', '<C-s>', '<denite:do_action:split>', 'noremap')
call denite#custom#map('insert', '<C-v>', '<denite:do_action:vsplit>',
    \ 'noremap')
call denite#custom#map('insert', '<C-r>', '<denite:redraw>', 'noremap')
call denite#custom#map('insert', '<C-a>', '<denite:choose_action>', 'noremap')
call denite#custom#map('insert', '<C-y>', '<denite:do_action:yank>', 'noremap')
" FIXME: Change mapping to C-Space
call denite#custom#map('insert', '<C-m>', '<denite:toggle_select_up>',
            \ 'noremap')

" }}}
" Dispatch {{{

" Dispatch won't work with shellslash on Windows. We need to wrap commands that
" use Dispatch (such as Gpush) with the following function
function! s:NoShellSlash(command)
    let old_shellslash = &l:shellslash
    setlocal noshellslash
    execute 'silent ' a:command
    let &l:shellslash = old_shellslash
endfunction

" Set dispatch tmux height to the minimum
let g:dispatch_tmux_height = 1

" Mapping to open console in current directory
nnoremap <silent> <Leader>cs :Start<CR>

" }}}
" EasyAlign {{{

" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <CR> <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. <Leader>aip)
nmap <Leader>a <Plug>(EasyAlign)

" Define new delimiters
let g:easy_align_delimiters = {
            \ '\' : {'pattern' : '\\\\'},
            \ '"' : {'pattern' : '"', 'ignore_groups' : ['!Comment'],
                    \ 'ignore_unmatched' : 0}
            \ }

" Maps for common alignments
nmap <silent> <Leader>a<Space> :execute
            \ "silent normal mz\<Plug>(EasyAlign)ip*<Space>`z"<CR>
vmap <silent> <Leader>a<Space> mz:<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*<Space>"<CR>`z
nmap <silent> <Leader>& :execute "silent normal mz\<Plug>(EasyAlign)ip*&`z"<CR>
vmap <silent> <Leader>& :mz<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*&"<CR>`z
nmap <silent> <Leader>= :execute "silent normal mz\<Plug>(EasyAlign)ip*=`z"<CR>
vmap <silent> <Leader>= mz:<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*="<CR>`z
nnoremap <silent> <Leader>: mzvip:<C-U>silent '<,'>EasyAlign*:>l1<CR>`z
vnoremap <silent> <Leader>: mz:<C-U>silent '<,'>EasyAlign*:>l1<CR>`z

" Python and vim comments
nmap <silent> <Leader># :execute "silent normal mz\<Plug>(EasyAlign)ip*#`z"<CR>
vmap <silent> <Leader># :mz<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*#"<CR>`z
nmap <silent> <Leader>" :execute "silent normal mz\<Plug>(EasyAlign)ip*\"`z"<CR>
vmap <silent> <Leader>" mz:<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*\""<CR>`z

" }}}
" Echodoc {{{

" On vim we don't need echodoc for python because we can just use jedi-vim to
" show call signatures? But on Neovim we do need it
if has('nvim')
    let g:echodoc_enable_at_startup = 1
else
    let g:echodoc_enable_at_startup = 0
endif

" Disable echodoc for tex and bib files
function! s:disable_echodoc() abort
  if &filetype ==# 'bib' || &filetype ==# 'tex' || &filetype ==# 'vimshell'
    call echodoc#disable()
  else
    call echodoc#enable()
  endif
endfunction
augroup ps_echodoc
    au! FileType * call s:disable_echodoc()
augroup END

" }}}
" Fugitive {{{

" Note: when we create a new repositiory in Bitbucket we must drop the
" 'petobens@' part from the url in order to be able to open it with Gbrowse

" To merge a single commit (create a new branch with that commit):
" git checkout master
" git checkout -b new_branch_name
" git pull origin master
" git cherry-pick commit_hash
" git push origin new_branch_name
" Then delete the branch both locally and remotely:
" git checkout another_branch
" git branch -D new_branch_name
" git push origin --delete new_branch_name

" Afterwards merge master into local branch

augroup ps_fugitive
    au!
    " Start in insert mode for commits and enable spell checking
    au BufEnter *.git/COMMIT_EDITMSG call s:BufEnterCommit()
    au Filetype gitcommit setlocal spell
    au Filetype gitcommit nmap <silent> <buffer> Q q
    " Open git previous commits unfolded since we use Glog for the current file:
    au Filetype git setlocal foldlevel=1
augroup END

function! s:BufEnterCommit()
    normal! gg0
    if getline('.') ==# ''
        startinsert
    endif
endfunction

" The following command is needed for Gbrowse to work since netrw fails to open
" links when set shellslash is set on Windows and disabling shellslash around
" Gbrowse (for instance using NoShellSlash() function) doesn't work nicely.
if s:is_win
    command! -bar -nargs=1 Browse silent! exe '! start ' escape(<q-args>, '!%#')
endif

" Mappings
nnoremap <silent> <Leader>gi :Unite output:echo\ system("git\ init")<cr>
nnoremap <silent> <Leader>gd :Gdiff<cr>:wincmd x<CR>
nnoremap <silent> <Leader>gs :Gstatus<cr>
nnoremap <silent> <Leader>gw :Gwrite<cr>
nnoremap <silent> <Leader>gb :Gblame<cr>
nnoremap <silent> <Leader>gc :w!<CR>:Gcommit<cr>
nnoremap <Leader>gm :Gmove<space>
nnoremap <silent> <Leader>gr :Gremove<cr>
nnoremap <silent> <Leader>gp :call <SID>NoShellSlash('Gpush')<CR>
nnoremap <silent> <Leader>gP :Gpull<CR>
nnoremap <silent> <Leader>gb :Gbrowse<cr>
vnoremap <silent> <Leader>gb :Gbrowse<cr>
" FIXME: for mac not working as expected
if dein#check_install(['unite']) == 0 &&
            \ !empty(unite#get_all_sources('quickfix'))
    nnoremap <silent> <Leader>gl :Glog -- %<CR>:Unite -no-quit -wrap
                \ -buffer-name=[Quickfix_List] quickfix<CR>
else
    nnoremap <silent> <Leader>gl :Glog -- %<CR>:copen<CR>
endif

" }}}
" GitGutter {{{

" FIXME: Not working on Windows
let g:gitgutter_map_keys = 0           " Disable default mappings
let g:gitgutter_realtime = 0           " Don't update when typing stops
let g:gitgutter_eager = 1              " Update when switching/writing buffers
let g:gitgutter_signs = 0              " Don't show signs (toggle them with map)

" Mappings
nnoremap <silent> <Leader>gg :GitGutterSignsToggle<CR>
nmap ]h <Plug>GitGutterNextHunk<bar>zvzz
nmap [h <Plug>GitGutterPrevHunk<bar>zvzz

" Note:
" We could stage and remove individual hunks with GitGutterStage(Revert)Hunk but
" we can also do this with Gdiff: i) use d[p]ut from working file and d[o]btain
" index file to stage individual hunks, ii) save the index file and iii) commit

" }}}
" Gundo {{{

let g:gundo_width = 60
let g:gundo_preview_height = 15
let g:gundo_help = 0
let g:gundo_tree_statusline = 'Gundo'
let g:gundo_preview_statusline = 'Gundo Preview'
if has('python3')
    let g:gundo_prefer_python3 = 1
endif

nnoremap <silent> <Leader>gu :GundoToggle<CR>

" }}}
" Indentline {{{

let g:indentLine_enabled = 0
let g:indentLine_showFirstIndentLevel = 1

" The following correspond to the `mediumgravel` color in heraldish colorscheme
" (we need to define them here to avoid issues when running in the terminal)
let g:indentLine_color_gui = '#666462'
let g:indentLine_color_term = 241

nnoremap <silent> <leader>I :IndentLinesToggle<cr>

" }}}
" Jedi {{{

if has('python3')
    let g:jedi#force_py_version = 3
endif
" For neocomplete to work
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#max_doc_height = 15
" Open goto in split buffers
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#use_splits_not_buffers = 'winwidth'
" Show call signature in command line instead of a popup window
" let g:jedi#show_call_signatures = 2
let g:jedi#smart_auto_mappings = 0

" Change/disable some mappings
let g:jedi#goto_assignments_command = '<C-]>' " Similar to ,st unite mapping
let g:jedi#goto_command = '<Leader>jd'
let g:jedi#rename_command = '<Leader>rn'
let g:jedi#documentation_command = ''  " We use K mapping in our ftplugin file
let g:jedi#usages_command = '<Leader>ap' " Appearances of word under cursor

augroup ps_jedi
    au!
    " Set jedi completion to work with neocomplete
    " au FileType python setlocal omnifunc=jedi#completions
    au BufRead,BufNewFile *.py setlocal omnifunc=jedi#completions
augroup END

" }}}
" NerdCommenter {{{

let g:NERDSpaceDelims = 1                  " Leave space after comment delimiter
let g:NERDCreateDefaultMappings = 0        " Disable default mappings
let g:NERDCustomDelimiters = {'python': {'left': '#'}}  " Fix python spacing

" Mappings (for both normal and visual mode)
map <Leader>cc <Plug>NERDCommenterComment
map <Leader>cu <Plug>NERDCommenterUncomment
map <Leader>ce <Plug>NERDCommenterToEOL
map <Leader>ac <Plug>NERDCommenterAppend

" }}}
" N(D)eocomplete {{{

" Vim completion settings
set pumheight=15                          " Popup menu max height
set complete=.                            " Scan only the current buffer
set completeopt=menuone,preview

" Use neocomplete in Vim and deoplete in Neovim
if !has('nvim')
    source $DOTVIM/vim-nvim/neocomplete_rc.vim
else
    set completeopt+=noinsert
    source $DOTVIM/vim-nvim/deoplete_rc.vim
    if s:is_mac
        let g:deoplete#sources#jedi#python_path = '/usr/local/bin/python3'
    else
        let g:deoplete#sources#jedi#python_path =
                    \ '/home/ubuntu/.linuxbrew/bin/python3'
    endif
endif

function! s:Edit_Dict()
    if has('nvim')
        let dict_file = &l:dictionary
    else
        let dict_file = get(g:neocomplete#sources#dictionary#dictionaries,
                    \ &filetype)
    endif
    if empty(dict_file)
        echo 'No dictionary file found.'
        return
    endif
    let split_windows = 'vsplit '
    if winwidth(0) <= 2 * (&tw ? &tw : 80)
        let split_windows = 'split '
    endif
    execute split_windows . dict_file
endfunction

" If a snippet is available enter expands it; if not available, it selects
" current candidate and closes the popup menu (i.e it ends completion)
inoremap <silent><expr><CR> pumvisible() ?
    \ (len(keys(UltiSnips#SnippetsInCurrentScope())) > 0 ?
    \ "\<C-y>\<C-R>=UltiSnips#ExpandSnippet()\<CR>" : "\<C-y>") : "\<CR>"
" Move in preview window with tab
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
" Edit dictionary files
nnoremap <silent> <Leader>ed :call <SID>Edit_Dict()<CR>

" }}}
" Sneak {{{

" Note: z text-object motion deletes up to (till) the match"
" Repeat Sneak with s or S (or f,F,t,T; moving the cursor resets this)
let g:sneak#s_next = 1
" Easymotion/Pentadactyl like behaviour with more than 2 screen matches
" let g:sneak#streak = 1
" Only use front row keys for labels (use tab for additonal matches)
let g:sneak#target_labels = 'asdfghjkl;'

" Vim mappings: use Alt-n  to replace the original ';' mapping (i.e next f,F,
" t or T match) and Alt-p to replace ',' (previous match)
nnoremap <A-n> ;
nnoremap <A-p> ,
" Make Sneak behaviour consistent with previous mappings
nmap <A-n> <Plug>SneakNext
nmap <A-p> <Plug>SneakPrevious

" Enhanced f,F,t and T motions (move vertically and highlight matches)
nmap f <Plug>Sneak_f
nmap F <Plug>Sneak_F
xmap f <Plug>Sneak_f
xmap F <Plug>Sneak_F
omap f <Plug>Sneak_f
omap F <Plug>Sneak_F
nmap t <Plug>Sneak_t
nmap T <Plug>Sneak_T
xmap t <Plug>Sneak_t
xmap T <Plug>Sneak_T
omap t <Plug>Sneak_t
omap T <Plug>Sneak_T

" }}}
" Tagbar {{{

" Note: we use universal-ctags which supersedes exuberant ctags and compile with
" `mingw32-make -f mk_mingw.mak`

let g:tagbar_left = 1
let g:tagbar_width = 45
let g:tagbar_autofocus = 1                 " Keep focus on tagbar window
let g:tagbar_sort = 1                      " Sort tags alphabetically
let g:tagbar_compact = 1
let g:tagbar_indent = 1
let g:tagbar_foldlevel = 2                 " Folds with higher level are closed
let g:tagbar_show_linenumbers = 2          " Relative line numbers
let g:tagbar_autopreview = 0               " Don't autopreview, enable it with P
let g:tagbar_previewwin_pos = 'belowright'

let g:tagbar_iconchars = ['▸', '▾']

let g:tagbar_type_tex = {
    \ 'sort' : 1,
    \ 'kinds' : [
        \ 'i:includes:1:0',
        \ 'l:labels:0:0'
    \ ]
\ }

let g:tagbar_type_bib = {
    \ 'ctagstype' : 'bibtex',
    \ 'kinds' : [
        \ 'c:cite-keys',
        \ 't:titles'
    \ ]
\ }

let g:tagbar_type_markdown = {
    \ 'ctagstype' : 'markdown',
    \ 'kinds' : [
        \ 'h:Heading_L1',
        \ 'i:Heading_L2',
        \ 'k:Heading_L3'
    \ ]
\ }

let g:tagbar_type_r = {
    \ 'ctagstype' : 'r',
    \ 'kinds'     : [
        \ 'l:Libraries',
        \ 's:Sources',
        \ 'f:Functions',
        \ 'g:Global Variables',
        \ 'v:Function Variables',
    \ ]
\ }

let g:tagbar_type_python = {
    \ 'kinds' : [
        \ 'i:modules:1:0',
        \ 'c:classes',
        \ 'f:functions',
        \ 'm:members',
        \ 'v:variables:0:0',
        \ 'x:unknowns',
    \ ],
\ }

nnoremap <silent> <Leader>tb :TagbarToggle<CR>

" }}}
" Ultisnips {{{

" FIXME: Ultisnips sometimes stops working and must press Winkey to reactivate?
let g:UltiSnipsSnippetDirectories = [$DOTVIM . '/mysnippets']
let g:UltiSnipsSnippetsDir = $DOTVIM . '/mysnippets'
let g:UltiSnipsEditSplit = 'context'
let g:UltiSnipsEnableSnipMate = 0
if has('python3')
    let g:UltiSnipsUsePythonVersion = 3
endif

" Automatically insert header when creating new files (Note: the header snippet
" is defined in all.snippets file) or when we opening a blank file (if we only
" want this for new file use BufNew event instead)
augroup ps_ultisnips
    au!
    au BufNewFile,BufRead *.{bib,py,snippets,tex,txt,vim,m,R,r,src,js,sh,yaml}
                \ call s:ExpandHeader()
augroup END
function! s:ExpandHeader()
    " Don't try to expand a header from a Gdiff (when file path includes .git)
    if expand('%:p') =~# "/\\.git/"
        return
    endif
    if line('$') == 1 && getline(1) ==# ''
        startinsert
        call feedkeys("hea\<C-s>")
    endif
endfunction

" Mappings
let g:UltiSnipsExpandTrigger = '<C-s>'
nnoremap <Leader>es :UltiSnipsEdit<CR>
" Snippet explorer with Unite
nnoremap <silent> <Leader>se :Unite output:call\ UltiSnips#ListSnippets()<CR>

" FIXME: Solve problems with anon snippets or use delimitMate; See #248; NO FIX?
" Maybe use neosnippet
" Anonymous snippets:
inoremap <silent> dq dq<C-R>=UltiSnips#Anon('"${1:${VISUAL}}"', 'dq',
            \ '', 'i')<cr>
inoremap <silent> sq sq<C-R>=UltiSnips#Anon("\'${1:${VISUAL}}\'", 'sq',
            \ '', 'i')<cr>
inoremap <silent> {{ {{<C-R>=UltiSnips#Anon('{${1:${VISUAL}}\}', '{{',
            \ '', 'i')<cr>
inoremap <silent> (( ((<C-R>=UltiSnips#Anon('(${1:${VISUAL}})', '((',
            \ '', 'i')<cr>
inoremap <silent> [[ [[<C-R>=UltiSnips#Anon('[${1:${VISUAL}}]', '[[',
            \ '', 'i')<cr>

" }}}
" Unite {{{

if dein#check_install(['unite']) == 0
    " Default appearance options
    call unite#custom#profile('default', 'context', {
                \ 'silent' : 1, 'update_time' : 200,
                \ 'prompt' : '❯ ', 'start_insert' : 1, 'prompt_focus' : 1,
                \ 'winheight' : 15, 'auto_resize' : 1,
                \ 'direction' : 'botright', 'prompt_direction': 'top',
                \ })
    " Use no-quit in grep and vimgrep sources
    " call unite#custom#profile('source/grep, source/vimgrep',
                " \ 'context', {'no_quit' : 1}
                " \ )
    " Use the fuzzy matcher
    call unite#filters#matcher_default#use(['matcher_fuzzy'])
    " Use the rank sorter
    call unite#filters#sorter_default#use(['sorter_rank'])

    " Ignore some type of files
    call unite#custom#source('file_rec, file_rec/async, file_rec/neovim, file' .
                \ ',buffer', 'ignore_pattern', join(['\.git\/', 'tmp\/'], '\|')
                \ )
    call unite#custom#source('file_mru',
                \ 'ignore_pattern', join(['\.git\/', 'tmp\/', 'doc\/'], '\|')
                \ )

    " Sort bookmarks alphabetically (ignoring case?)
    call unite#custom#source('bookmark', 'sorters', 'sorter_word')
    " Show relative path in buffer source
    call unite#custom#source('buffer', 'converters',
                \ ['converter_uniq_word', 'converter_word_abbr'])
    " Sort candidates in buffer source by word
    call unite#custom#source('buffer', 'sorters',
                \ ['converter_word', 'sorter_word'])
    " Quickfix highlighting
    call unite#custom_source('quickfix', 'converters',
                \ 'converter_quickfix_default')
endif

let g:unite_data_directory = $CACHE . '/plugins/unite'
let g:unite_force_overwrite_statusline = 0        " Avoid conflicts with Airline
let g:unite_enable_auto_select = 0                " Don't skip first line

" MRU settings (neomru is a separate source now)
let g:neomru#file_mru_limit = 750
let g:neomru#time_format = ''
let g:neomru#file_mru_path = $CACHE . '/plugins/unite/mru/file'
let g:neomru#directory_mru_path = $CACHE . '/plugins/unite/mru/directory'

" Yank settings
let g:neoyank#file = g:unite_data_directory . '/yank/history_yank'

" Buffer settings (don't show time)
let g:unite_source_buffer_time_format = ''

" Quickfix (we use it for instance with Glog)
let unite_quickfix_filename_is_pathshorten = 0
let g:unite_quickfix_is_multiline = 0
let g:unite#filters#converter_quickfix_highlight#enable_bold_for_message = 0

" Async recursive file search and grep settings (if ag is not available a good
" alternative is the platinium searcher, pt)
" Note: on Windows we install ag through msys2 pacman
if executable('ag')
    let g:unite_source_rec_async_command = ['ag', '--follow',  '--nocolor',
                \ '--nogroup', '--hidden', '-g', '']
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts =
      \ '--smart-case --vimgrep --hidden --follow --ignore ''.git'''
    let g:unite_source_grep_recursive_opt = ''
endif

" Mappings (sources):
if executable('ag')
    if !has('nvim')
        nnoremap <silent> <Leader>ls :Unite
                    \ -buffer-name=fuzzy-search file_rec/async<CR>
    else
        " FIXME: We need to press space for candidates to appear
        nnoremap <silent> <Leader>ls :Unite
                    \ -buffer-name=fuzzy-search file_rec/neovim<CR>
    endif
else
    nnoremap <silent> <Leader>ls :Unite -buffer-name=fuzzy-search file_rec<CR>
endif
nnoremap <silent> <Leader>sd :UniteWithInputDirectory -buffer-name=fuzzy-search
            \ file_rec/async<CR>
nnoremap <silent> <Leader>rd :Unite -buffer-name=mru-files neomru/file<CR>
nnoremap <silent> <Leader>bm :Unite -profile-name=bookmark -default-action=rec
            \ -buffer-name=my-directories bookmark<CR>
nnoremap <silent> <Leader>be :Unite -default-action=switch buffer<CR>
nnoremap <silent> <Leader>me :Unite mapping<CR>
" nnoremap <silent> <Leader>ce :Unite command<CR>
nnoremap <silent> <Leader>uf :Unite function<CR>
nnoremap <silent> <Leader>yh :Unite history/yank<CR>
nnoremap <silent> <Leader>ch :Unite history/command<CR>
nnoremap <silent> <Leader>sh :Unite history/search<CR>
nnoremap <silent> <Leader>us :Unite -buffer-name=search line:forward<CR>
nnoremap <silent> <Leader>uw :UniteWithCursorWord -auto-preview
            \ -buffer-name=search line<CR>
nnoremap <silent> <Leader>tl :Unite -auto-highlight -buffer-name=task-list
            \ vimgrep:%:\\CTODO\:\\<bar>FIXME\:<CR>
nnoremap <silent> <Leader>ag :Unite -buffer-name=ag grep<CR>
nnoremap <silent> <Leader>ur :UniteResume -force-redraw -immediately<CR>
nnoremap <silent> <Leader>sm :Unite output:messages<CR>
" FIXME: UniteNext and UnitePrevious don't work with qf source
nnoremap <silent> <Leader>uq :Unite -no-quit -wrap -auto-highlight
            \ -buffer-name=[Quickfix_List][-] quickfix<CR>
" NeoInclude and Unite tag
nnoremap <silent> <Leader>te :NeoIncludeMakeCache<CR>:Unite
            \ tag/include<CR>
augroup ps_unite_tag
    au!
    au BufNewFile,BufRead *.{vim,tex,bib,r,R} nnoremap <buffer> <silent> <C-]>
                \ :NeoIncludeMakeCache<CR>
                \ :UniteWithCursorWord -immediately -sync
                \ -default-action=context_split tag/include<CR>
augroup END
" Unite Next/Last (similar to cnext and cprev):
nnoremap <silent> ]u :<C-U>execute v:count1 . 'UniteNext'<CR>
nnoremap <silent> [u :<C-U>execute v:count1 . 'UnitePrevious'<CR>
nnoremap <silent> [U :UniteFirst<CR>
nnoremap <silent> ]U :UniteLast<CR>
nnoremap <silent> <Leader>uc :UniteClose<CR>

" Filetype settings
augroup ps_unite
    au!
    au FileType unite call s:unite_settings()
augroup END

function! s:unite_settings()
    " Exit unite with escape key
    nmap <buffer> <ESC> <Plug>(unite_exit)
    imap <buffer> <ESC> <Plug>(unite_exit)
    " Enable navigation with control-j and control-k in insert mode (and tab)
    imap <buffer> <C-j>   <Plug>(unite_select_next_line)
    imap <buffer> <C-k>   <Plug>(unite_select_previous_line)
    imap <buffer> <TAB>   <Plug>(unite_select_next_line)
    imap <buffer> <S-TAB>  <Plug>(unite_select_previous_line)
    " Opening in splits
    inoremap <silent><buffer><expr> <C-s> unite#do_action('split')
    inoremap <silent><buffer><expr> <C-v> unite#do_action('vsplit')
    " Change directory and open vimfiler
    " inoremap <silent><buffer><expr> <C-c> unite#do_action('cd')
    inoremap <silent><buffer><expr> <C-f> unite#do_action('vimfiler')
    " Choose action
     imap <silent><buffer> <C-a> <Plug>(unite_choose_action)
     " Mark candidates
     imap <buffer> <C-SPACE> <Plug>(unite_toggle_mark_current_candidate)
    " Redraw screen
    imap <silent><buffer> <C-r> <Plug>(unite_redraw)
    " Change window and redraw screen
    nmap <buffer> <C-j> <C-w>j
    nmap <buffer> <C-h> <C-w>h
    nmap <buffer> <C-k> <C-w>k
    nmap <buffer> <C-l> <C-w>l
    " Toggle matcher/converter (to filter ctags by kind)
    inoremap <silent><buffer><expr> <C-c> unite#mappings#set_current_matchers(
            \ empty(unite#mappings#get_current_matchers()) ?
            \ ['converter_abbr_word', 'matcher_default'] : [])
endfunction

" Custom split action
let s:my_split = {'is_selectable': 1}
function! s:my_split.func(candidate)
    let split_action = 'vsplit'
    if winwidth(winnr('#')) <= 2 * (&tw ? &tw : 80)
        let split_action = 'split'
    endif
    call unite#take_action(split_action, a:candidate)
endfunction
if dein#check_install(['unite']) == 0
    call unite#custom_action('openable', 'context_split', s:my_split)
endif
unlet s:my_split

" }}}
" Vimfiler {{{

" Note: on Mac to delete files to the trash install rmtrash

if dein#check_install(['vimfiler']) == 0
    function! VimfilerHookOpts() abort
        call vimfiler#custom#profile('default', 'context', {
                    \ 'direction' : 'topleft',
                    \ 'split': 1,
                    \ 'winwidth' : 40,
                    \ 'force_quit': 1,
                    \ 'status' : 1,
                    \ 'columns' : 'size',
                    \ 'safe': 0
                    \ })

        " Open certain filetypes with external programs
        let g:vimfiler_execute_file_list = {}
        if s:is_win
            call vimfiler#set_execute_file('pdf,PDF', 'SumatraPDF')
            call vimfiler#set_execute_file('xlsx,xls,xlsm',
                \ 'C:\Program Files\Microsoft Office\root\Office16\EXCEL.exe')
            call vimfiler#set_execute_file('docx,doc',
                \ 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.exe')
        elseif s:is_mac
            call vimfiler#set_execute_file('pdf,PDF,doc,docx,xls,xlsx,xlsm,png',
                \ 'open')
        endif
    endfunction
    call dein#set_hook('vimfiler', 'hook_source', function('VimfilerHookOpts'))
endif

" Disable netrw.vim and use vimfiler as default explorer
let g:loaded_netrwPlugin = 1
let g:vimfiler_as_default_explorer = 1

" Nerdtree-like appeareance
let g:vimfiler_tree_opened_icon = '▾'
let g:vimfiler_tree_closed_icon = '▸'
let g:vimfiler_tree_leaf_icon = ''
let g:vimfiler_marked_file_icon = '✓'
let g:vimfiler_tree_indentation = 3

" Ignore certain files and folders (pattern is not case sensitive)
" Note that we can write this as a list rather than a (long) string
let g:vimfiler_ignore_pattern = '\%(\.sys\|\.bat\|\.bak\)$\|'.
            \ '^\%(\.git\|\.DS_Store\)$'

" Cache directory
let g:vimfiler_data_directory = $CACHE . '/plugins/vimfiler'

" Set next variable to 0 if there are conflicts with Airline
let g:vimfiler_force_overwrite_statusline = 1

" Maps
nnoremap <silent> <Leader>fe :VimFilerBufferDir<CR>
nnoremap <silent> <Leader>fb :VimFiler bookmark:<CR>
nnoremap <silent> <Leader>df :VimFilerBufferDir -double<CR>
nnoremap <silent> <Leader>ff :lcd %:h<CR>:VimFiler -find<CR>

" Filetype settings
augroup ps_vimfiler
    au!
    au FileType vimfiler call s:vimfiler_settings()
augroup END

function! s:vimfiler_settings()
    " Exit with escape key and q, Q; hide with <C-c>
    nmap <buffer> <ESC> <Plug>(vimfiler_exit)
    nmap <buffer> q <Plug>(vimfiler_exit)
    nmap <buffer> Q <Plug>(vimfiler_exit)
    nmap <buffer> <C-c> <Plug>(vimfiler_hide)
    " Expand tree and edit files with e
    nmap  <buffer><expr> e vimfiler#smart_cursor_map(
        \ "\<Plug>(vimfiler_expand_tree)", "\<Plug>(vimfiler_edit_file)")
    " Open files with external programs (such as a PDF viewer)
    nmap <buffer> o <Plug>(vimfiler_execute_vimfiler_associated)
    " Open and close tree with fold commands
    nmap <buffer> zo <Plug>(vimfiler_expand_tree)
    nmap <buffer> zc <Plug>(vimfiler_expand_tree)
    nmap <buffer> zm <Plug>(vimfiler_expand_tree_recursive)
    nmap <buffer> zr <Plug>(vimfiler_expand_tree_recursive)
    " Open files in splits
    nnoremap <buffer><expr><silent> s vimfiler#do_switch_action('split')
    nnoremap <buffer><expr><silent> v vimfiler#do_switch_action('vsplit')
    " Copy, move, paste and delete mappings (paste executes move or copy
    " operations i.e first move and then paste to move)
    nmap <buffer> c
    \ <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_clipboard_copy_file)
    nmap <buffer> m
    \ <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_clipboard_move_file)
    nmap <buffer> p <Plug>(vimfiler_clipboard_paste)
    nmap <buffer> d
    \ <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_delete_file)
    " New file and directory
    nmap <buffer> F <Plug>(vimfiler_new_file)
    nmap <buffer> D <Plug>(vimfiler_make_directory)
    " Move up a directory
    nmap <buffer> u <Plug>(vimfiler_switch_to_parent_directory)
    " Change window and redraw screen
    nmap <buffer> <C-j> <C-w>j
    nmap <buffer> <C-h> <C-w>h
    nmap <buffer> <C-k> <C-w>k
    nmap <buffer> <C-l> <C-w>l
    nmap <buffer> <C-r> <Plug>(vimfiler_redraw_screen)
    " Open external filer at current direction
    nmap <buffer> ge
    \ <Plug>(vimfiler_cd_vim_current_dir)<Plug>(vimfiler_execute_external_filer)
    " Bookmarks (reuses vimfiler buffer)
    nmap <buffer>b <Plug>(vimfiler_cd_input_directory)<C-u>bookmark:/<CR>
endfunction

" }}}
" Vimtex {{{

" TOC and labels
let g:vimtex_index_split_width = 45
let g:vimtex_toc_fold = 1
let g:vimtex_toc_fold_levels = 1
let g:vimtex_index_show_help = 0
let g:vimtex_index_resize = 0
let g:vimtex_toc_show_preamble = 0
let g:vimtex_toc_secnumdepth = 1
let g:vimtex_index_hide_line_numbers = 0

" Folding
let g:vimtex_fold_enabled = 0

" Indendation
let g:vimtex_indent_enabled = 0

" Bib and image completion
let g:vimtex_complete_close_braces = 1
let g:vimtex_complete_recursive_bib = 1
let g:vimtex_complete_img_use_tail = 1

" Compilation
let g:vimtex_view_enabled = 0
let g:vimtex_latexmk_enabled = 0
let g:vimtex_quickfix_ignore_all_warnings = 0
let g:vimtex_quickfix_ignored_warnings = ['refsection', 'pop empty color',
            \ 'multiple pdfs', 'font warning', 'contains only floats',
            \ 'PDF inclus']

" Disable insert mode mappings
let g:vimtex_imaps_enabled = 0

" Mappings
augroup ps_vimlatex
    au!
    au Filetype tex nmap <silent> <buffer> <Leader>tc
                \ <Plug>(vimtex-toc-open)
    au Filetype tex nnoremap <silent> <buffer> <Leader>ll :Unite
                \ -auto-preview vimtex_labels<CR>
    " Note the following can be called directly with cse, tse and tsd
    au Filetype tex nmap <silent> <buffer> <Leader>ce <Plug>(vimtex-env-change)
    au Filetype tex nmap <silent> <buffer> <Leader>ts
                \ <Plug>(vimtex-env-toggle-star)
    au Filetype tex nmap <silent> <buffer> <Leader>lr
                \ <Plug>(vimtex-delim-toggle-modifier)
    " End environment or delimiter in insert mode
    au Filetype tex imap <silent> <buffer> }ee <Plug>(vimtex-delim-close)
augroup END

" }}}
" Vimshell {{{

" Set prompt to show working directory
let g:vimshell_prompt_expr =
    \ 'escape(fnamemodify(getcwd(), ":~").">", "\\[]()?! ")." "'
let g:vimshell_prompt_pattern = '^\%(\f\|\\.\)\+> '
" Change cache directory
let g:vimshell_data_directory = $CACHE . '/plugins/vimshell'

" To run :VimShellExecute directly on a python file
let g:vimshell_execute_file_list = {}
let g:vimshell_execute_file_list['py'] = 'python'

" Use ipython for python files
if !exists('g:vimshell_interactive_interpreter_commands')
    let g:vimshell_interactive_interpreter_commands = {}
endif
let g:vimshell_interactive_interpreter_commands.python = 'ipython3'

" Maps
nnoremap <silent> <Leader>vt :VimShellBufferDir -popup<CR>
vnoremap <silent> <Leader>ei :VimShellSendString<CR>
nmap <silent> <Leader>vc mz:VimShell<CR><bar><Plug>(vimshell_exit)`z

augroup ps_vimshell
    au!
    " Vimshell
    au FileType vimshell call s:vimshell_settings()
    " Interpreter
	au FileType int-* call s:interactive_settings()
augroup END

function! s:vimshell_settings()
    " Options
    setlocal textwidth=0

    " Alias
    call vimshell#set_alias('up', 'cdup')

    " Mappings
    " Exit with escape key and q, Q
    nmap <buffer> <ESC> <Plug>(vimshell_exit)
    nmap <buffer> q <Plug>(vimshell_exit)
    nmap <buffer> Q <Plug>(vimshell_exit)
    " Map <CR> properly
    imap <buffer><expr><CR> pumvisible() ?
        \ (len(keys(UltiSnips#SnippetsInCurrentScope())) > 0 ?
        \ neocomplete#close_popup()."\<C-R>=UltiSnips#ExpandSnippet()\<CR>" :
        \ neocomplete#close_popup()) : "\<Plug>(vimshell_enter)"
    " Change window and redraw screen
    nmap <buffer> <C-j> <C-w>j
    nmap <buffer> <C-h> <C-w>h
    nmap <buffer> <C-k> <C-w>k
    nmap <buffer> <C-l> <C-w>l
    " Since we remap key to redraw/clear vimshell we map it again
    nmap <buffer> <C-r>	<Plug>(vimshell_clear)
endfunction

function! s:interactive_settings()
    " Options
     setlocal textwidth=0

    " Mappings
    " Also exit with Q besides q
    nmap <buffer> Q <Plug>(vimshell_int_exit)
    " Map <CR> properly
    imap <buffer><expr><CR> pumvisible() ?
        \ (len(keys(UltiSnips#SnippetsInCurrentScope())) > 0 ?
        \ neocomplete#close_popup()."\<C-R>=UltiSnips#ExpandSnippet()\<CR>" :
        \ neocomplete#close_popup()) : "\<Plug>(vimshell_int_execute_line)"
    " Move as in insert mode
    imap <buffer><C-l> <C-o>l
    imap <buffer><C-h> <C-o>h
    " Show history with unite
    imap <buffer><C-u> <Plug>(vimshell_int_history_unite)
    " Redraw/clear
    imap <buffer> <C-r> <ESC><Plug>(vimshell_int_clear)
endfunction

" }}}

" }}}
" GUI and Terminal {{{

if has('gui_running')
    " GUI Settings
    " Patched font with fancy Unicode glyphs
    set guifont=Sauce\ Code\ Powerline:h11
    " Options (remove toolbar, menu, scrollbars; auto-copy visual selection and
    " use console dialogs)
    set guioptions=ac
    " Disable cursor blinking in all modes
    set guicursor+=a:blinkon0

    " Macvim specific
    if has('gui_macvim')
        set fuoptions=maxvert,maxhorz
        set guifont=Sauce\ Code\ Powerline:h15
        set macmeta  " Allows alt mappings to work
    elseif s:is_win
        " Maximize screen size
        augroup max_vim_window
            au!
            au GUIEnter * simalt ~x
        augroup END
    endif
else
    " Terminal settings
    set mouse=a        " Enable the mouse

    " Enable cursorshape on neovim
    if has('nvim')
        let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 1
    endif

    " Make cursor shape mode dependent (note: we need double quotes!)
    if exists('$TMUX')
        " Vertical bar in insert mode, underscore in replace mode and block in
        " normal mode
        let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>[6 q\<Esc>\\"
        let &t_SR = "\<Esc>Ptmux;\<Esc>\<Esc>[4 q\<Esc>\\"
        let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>[2 q\<Esc>\\"
    else
        " If we don't use tmux but use an xterm terminal:
        let &t_SI = "\<Esc>[6 q"
        let &t_SR = "\<Esc>[4 q"
        let &t_EI = "\<Esc>[2 q"
    endif
endif

" }}}
" Functions {{{

" Last modified {{{

" If a buffer is modified, update any 'Last modified: ' in the first 7 lines
" (with up to 5 characters before it) and restore cursor and window position
function! s:Subst(start, end, pattern, replacement)
    let lineno = a:start
    while lineno <= a:end
        let curline = getline(lineno)
        if match(curline, a:pattern) != -1
            let newline = substitute(curline, a:pattern, a:replacement, '')
            if newline != curline
                keepjumps call setline(lineno, newline)
            endif
        endif
        let lineno = lineno + 1
    endwhile
endfunction

function! s:LastModified()
    if &modified == 1
        let pattern = '^\(.\{,5}Last Modified:\s\).*'
        let replacement = '\1' . strftime('%d %b %Y')
        call s:Subst(1, 7, pattern, replacement)
    endif
endfunction

augroup LastMod
    au!
    au BufWritePre {*.*,vimrc,pentadactylrc,bash_profile} call s:LastModified()
augroup END

" }}}
" Create non-existing parent directory on save {{{

function! s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file !~# '\v^\w+\:\/'
        let dir = fnamemodify(a:file, ':h')
        call s:MakeDirIfNoExists(dir)
    endif
endfunction

augroup BWCCreateDir
    au!
    au BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

" }}}
" Delete trailing white space {{{

function! s:Preserve(command)
    " Save last search and cursor position
    let _s=@/
    let l = line('.')
    let c = col('.')
    " Do the business
    execute a:command
    " Restore previous search history and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

function! s:DeleteTrailingWhitespace()
    let trailing = search('\s$', 'nw')
    if trailing != 0
        call s:Preserve("%s/\\s\\+$//e")
    endif
endfunction

augroup Delete_Trailing
    au!
    au BufWritePre * :call s:DeleteTrailingWhitespace()
augroup END
nnoremap <Leader>dt :call <SID>DeleteTrailingWhitespace()<CR>

" }}}
" Mark windows and then swap them {{{

function! s:MarkWindowSwap()
    let g:markedWinNum = winnr()
endfunction

function! s:DoWindowSwap()
    " Mark destination
    let curNum = winnr()
    let curBuf = bufnr('%')
    execute g:markedWinNum . 'wincmd w'
    " Switch to source and shuffle dest->source
    let markedBuf = bufnr('%')
    " Hide and open so that we aren't prompted and keep history
    execute 'hide buf' curBuf
    " Switch to dest and shuffle source->dest
    execute curNum . 'wincmd w'
    " Hide and open so that we aren't prompted and keep history
    execute 'hide buf' markedBuf
endfunction

nnoremap <silent> <Leader>mw :call <SID>MarkWindowSwap()<CR>
nnoremap <silent> <Leader>sw :call <SID>DoWindowSwap()<CR>

" }}}
" Highlight word {{{

" From Steve Losh's vimrc: Use <Leader>N (number from 1-6) to highlight the
" current word in a specific color.

function! s:HiInterestingWord(n)
    " Save location.
    normal! mz
    " Yank the current word into the z register.
    normal! "zyiw
    " Calculate an arbitrary match ID.  Hopefully nothing else is using it.
    let mid = 86750 + a:n
    " Clear existing matches, but don't worry if they don't exist.
    silent! call matchdelete(mid)
    " Construct a literal pattern that has to match at boundaries.
    let pat = '\V\<' . escape(@z, '\') . '\>'
    " Actually match the words.
    call matchadd('InterestingWord' . a:n, pat, 1, mid)
    " Move back to our original location.
    normal! `z
endfunction

" Mappings
nnoremap <silent> <Leader>h1 :call <SID>HiInterestingWord(1)<cr>
nnoremap <silent> <Leader>h2 :call <SID>HiInterestingWord(2)<cr>
nnoremap <silent> <Leader>h3 :call <SID>HiInterestingWord(3)<cr>
nnoremap <silent> <Leader>h4 :call <SID>HiInterestingWord(4)<cr>
nnoremap <silent> <Leader>h5 :call <SID>HiInterestingWord(5)<cr>
nnoremap <silent> <Leader>h6 :call <SID>HiInterestingWord(6)<cr>

" }}}
" Next and last motions {{{

" From Steve Losh's Vimrc
" Motion for next/last object. Last here means previous, not final
" example: cin( to change inner next parenthesis

function! s:NextTextObject(motion, dir)
    let c = nr2char(getchar())
    let d = ''

    if c ==# 'b' || c ==# '(' || c ==# ')'
        let c = '('
    elseif c ==# 'B' || c ==# '{' || c ==# '}'
        let c = '{'
    elseif c ==# 'r' || c ==# '[' || c ==# ']'
        let c = '['
    elseif c ==# "'"
        let c = "'"
    elseif c ==# '"'
        let c = '"'
    else
        return
    endif

" Find the next opening-whatever.
    execute 'normal! ' . a:dir . c . "\<cr>"

    if a:motion ==# 'a'
" If we're doing an 'around' method, we just need to select around it
" and we can bail out to Vim.
        execute 'normal! va' . c
    else
" Otherwise we're looking at an 'inside' motion. Unfortunately these
" get tricky when you're dealing with an empty set of delimiters because
" Vim does the wrong thing when you say vi(.

        let open = ''
        let close = ''

        if c ==# '('
            let open = '('
            let close = ')'
        elseif c ==# '{'
            let open = '{'
            let close = '}'
        elseif c ==# '['
            let open = "\\["
            let close = "\\]"
        elseif c ==# "'"
            let open = "'"
            let close = "'"
        elseif c ==# '"'
            let open = '"'
            let close = '"'
        endif

" We'll start at the current delimiter.
        let start_pos = getpos('.')
        let start_l = start_pos[1]
        let start_c = start_pos[2]

" Then we'll find it's matching end delimiter.
        if c ==# "'" || c ==# '"'
" searchpairpos() doesn't work for quotes, because fuck me.
            let end_pos = searchpos(open)
        else
            let end_pos = searchpairpos(open, '', close)
        endif

        let end_l = end_pos[0]
        let end_c = end_pos[1]

        call setpos('.', start_pos)

        if start_l == end_l && start_c == (end_c - 1)
" We're in an empty set of delimiters. We'll append an "x"
" character and select that so most Vim commands will do something
" sane. v is gonna be weird, and so is y. Oh well.
            execute "normal! ax\<esc>\<left>"
            execute 'normal! vi' . c
        elseif start_l == end_l && start_c == (end_c - 2)
" We're on a set of delimiters that contain a single, non-newline
" character. We can just select that and we're done.
            execute 'normal! vi' . c
        else
" Otherwise these delimiters contain something. But we're still not
" sure Vim's gonna work, because if they contain nothing but
" newlines Vim still does the wrong thing. So we'll manually select
" the guts ourselves.
            let whichwrap = &whichwrap
            set whichwrap+=h,l

            execute 'normal! va' . c . 'hol'

            let &whichwrap = whichwrap
        endif
    endif
endfunction

" Mappings
onoremap an :<c-u>call <SID>NextTextObject('a', '/')<cr>
xnoremap an :<c-u>call <SID>NextTextObject('a', '/')<cr>
onoremap in :<c-u>call <SID>NextTextObject('i', '/')<cr>
xnoremap in :<c-u>call <SID>NextTextObject('i', '/')<cr>

onoremap al :<c-u>call <SID>NextTextObject('a', '?')<cr>
xnoremap al :<c-u>call <SID>NextTextObject('a', '?')<cr>
onoremap il :<c-u>call <SID>NextTextObject('i', '?')<cr>
xnoremap il :<c-u>call <SID>NextTextObject('i', '?')<cr>

" }}}
" Open web links {{{

function! s:OpenLink()
    let line = getline ('.')
    let url = matchstr(line, '\(http\|www\.\)[^ ]*')
    let url = escape(url, '#!?&;|%')
    let open_command = 'open '
    if s:is_win
        let open_command = 'start '
    endif
    execute 'silent! !' .  open_command . url
    redraw!
endfunction

nnoremap <silent> <Leader>ol :call <SID>OpenLink()<CR>

" }}}
" Visual search {{{

function! s:VSetSearch(cmdtype)
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
    let @s = temp
endfunction

xnoremap * :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR><C-o>
xnoremap <kMultiply> :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR><C-o>
xnoremap # :<C-u>call <SID>VSetSearch('?')<CR>?<C-R>=@/<CR><CR><C-o>

" }}}
" Select indent block {{{

function! s:SelectIndent()
    let indet_cur_line = indent(line('.'))
    while indent(line('.') - 1) >= indet_cur_line
        execute 'normal k'
    endwhile
    execute 'normal V'
    while indent(line('.') + 1) >= indet_cur_line
        execute 'normal j'
    endwhile
endfunction

nnoremap <silent> <Leader>si :call <SID>SelectIndent()<CR>

" }}}

" }}}
