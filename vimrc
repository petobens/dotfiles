" TODOs:
" Try the job feature: skywind3000/asyncrun.vim or neomake to replace dispatch?
" Filter to convert markdown to html, useful for mails
" Try dash or investigate for doc searching

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
    " Set python3 host (i.e executable)
    if s:is_mac
        let g:python3_host_prog = '/usr/local/bin/python3'
    elseif s:is_linux
        let g:python3_host_prog = '/mnt/.linuxbrew/bin/python3'
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
    execute 'set runtimepath+=' . expand(
                \ '$DOTVIM/bundle/repos/github.com/Shougo/dein.vim')
endif

" Directory where plugins (with normalized names) are placed. The function also
" disables filetype automatically
let g:dein#enable_name_conversion = 1
if dein#load_state(expand('$DOTVIM/bundle/'))
    call dein#begin(expand('$DOTVIM/bundle/'))

    " Plugins we are using
    call dein#add('vim-airline/vim-airline')
    call dein#add('junegunn/vim-easy-align')
    if s:is_mac
        " We installed fzf with Brew
        call dein#add('/usr/local/opt/fzf')
    endif
    call dein#add('junegunn/fzf.vim')
    call dein#add('airblade/vim-gitgutter')
    call dein#add('Yggdroot/indentLine')
    call dein#add('vim-scripts/matchit.zip', {'name' : 'matchit'})
    call dein#add('simnalamburt/vim-mundo', {'on_cmd' : 'MundoToggle'})
    call dein#add('neomake/neomake')
    if exists(':tnoremap')
        call dein#add('kassio/neoterm')
    endif
    call dein#add('scrooloose/nerdcommenter')
    call dein#add('justinmk/vim-sneak')
    if exists('$TMUX')
        call dein#add('christoomey/vim-tmux-navigator')
        call dein#add('wellle/tmux-complete.vim')
        call dein#add('tmux-plugins/vim-tmux-focus-events')
    endif
    call dein#add('majutsushi/tagbar', {'on_cmd' : 'TagbarToggle'})
    call dein#add('SirVer/ultisnips')
    call dein#add('lervag/vimtex', {'on_ft' : ['tex', 'bib']})

    " (my) Colorschemes
    call dein#add('petobens/colorish', {'frozen': 1})

    " Python
    call dein#add('davidhalter/jedi-vim', {'on_ft' : 'python'})
    " call dein#add('tweekmonster/impsort.vim', {'on_ft' : 'python'})
    call dein#add('tweekmonster/impsort.vim')
    if has('nvim')
        call dein#add('zchee/deoplete-jedi')
    endif
    call dein#add('tmhedberg/SimpylFold', {'on_ft' : 'python'})
    call dein#add('vim-python/python-syntax', {'on_ft' : 'python'})

    " R
    call dein#add('jalvesaq/Nvim-R')

    " Javascript
    call dein#add('pangloss/vim-javascript', {'on_ft' : 'javascript'})
    call dein#add('carlitux/deoplete-ternjs', {'on_ft' : 'javascript'})
    call dein#add('ternjs/tern_for_vim',
                \ {'on_ft' : 'javascript', 'build': 'npm install'})
    call dein#add('chrisbra/Colorizer', {'on_cmd': 'ColorToggle'})

    " Git
    call dein#add('junegunn/gv.vim')
    call dein#add('tpope/vim-fugitive')
    call dein#add('idanarye/vim-merginal')

    " SQL (and database related)
    call dein#add('joereynolds/SQHell.vim', {'on_ft' : 'sql'})
    call dein#add('chrisbra/csv.vim', {'on_ft': 'csv'})

    " Tim Pope plugins
    call dein#add('tpope/vim-abolish')
    call dein#add('tpope/vim-dadbod')
    call dein#add('tpope/vim-dispatch')
    call dein#add('tommcdo/vim-fubitive')
    call dein#add('shumphrey/fugitive-gitlab.vim')
    call dein#add('tpope/vim-repeat')
    call dein#add('tpope/vim-rhubarb')
    call dein#add('tpope/vim-surround')

    " Shougo plugins
    call dein#add('Shougo/dein.vim')
    call dein#add('Shougo/denite.nvim')
    call dein#add('Shougo/unite.vim')
    call dein#add('Shougo/vimfiler', {'on_path' : '.*'})
    " Note: We need vimproc in neovim for grep source to work
    let s:vimproc_make = 'make -f make_mac.mak'
    if s:is_win
        let s:vimproc_make = 'tools\\update-dll-mingw'
    elseif s:is_linux
        let s:vimproc_make = 'make'
    endif
    call dein#add('Shougo/vimproc.vim', {'build' : s:vimproc_make})
    call dein#add('Shougo/deoplete.nvim')
    " Unite/denite sources
    call dein#add('chemzqm/denite-extra')
    call dein#add('Shougo/neomru.vim')
    call dein#add('Shougo/neoyank.vim')
    call dein#add('kopischke/unite-spell-suggest')
    call dein#add('tsukkee/unite-tag')
    " For deoplete
    call dein#add('Shougo/context_filetype.vim')
    call dein#add('Shougo/echodoc.vim')
    call dein#add('Shougo/neco-vim', {'name' : 'neco-vim'})
    call dein#add('Shougo/neco-syntax')
    call dein#add('Shougo/neoinclude.vim')

    " Devicons (load this last!)
    call dein#add('ryanoasis/vim-devicons')

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
set viewoptions=cursor,folds,unix,slash,curdir
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
    au BufWinLeave {*.*,vimrc}  mkview
    au BufWinEnter {*.*,vimrc}  silent! loadview
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
" Syntax highlighting {{{

" Enable syntax highlighting
syntax enable

" Use guicolors in terminal (we seem to need to place this here)
set termguicolors

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

" Show the effect of substitute incrementally
if has('nvim')
    set inccommand=nosplit
endif

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
" Complete longest common string first and then show full alternatives
set wildmode=longest:full,full
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

" Toggle (Upper)casing inner word
nnoremap <A-u> mzg~iw`z

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

" Diff in split window
function! s:DiffFileSplit()
    let win_id = win_getid()
    let other_file = input('Input file for diffing: ', '', 'file')
    if other_file == ''
        return
    endif
    if winwidth(0) <= 2 * (&tw ? &tw : 80)
        let diff_cmd = 'diffsplit '
    else
        let diff_cmd = 'vert diffsplit '
    endif
    execute diff_cmd . other_file
    call win_gotoid(win_id)
    normal! gg]c
endfunction
nnoremap <silent> <Leader>ds :call <SID>DiffFileSplit()<CR>
nnoremap <silent> <Leader>de :diffoff!<CR>
nnoremap <silent> <Leader>du :diffupdate<CR>
" Use [h and ]h for jumping between hunks (changes)
nnoremap <expr> ]h &diff ? ']c' : ']h'
nnoremap <expr> [h &diff ? '[c' : '[h'

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
" Terminal mode {{{

if exists(':tnoremap')
    " Exit terminal mode and return to vim normal mode (essentially the terminal
    " now becomes a regular vim buffer)
    tnoremap <Esc> <C-\><C-n>
    tnoremap kj <C-\><C-n>
    " Window movement
    tnoremap <c-k> <C-\><C-n><C-w>k
    tnoremap <c-h> <C-\><C-n><C-w>h
    tnoremap <c-l> <C-\><C-n><C-w>l
    tnoremap <c-j> <C-\><C-n><C-w>j
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
" Html {{{

augroup ft_html
    au!
    au Filetype html setlocal shiftwidth=2 tabstop=2 softtabstop=2
    " au FileType html nnoremap <buffer><silent> <F7> :silent! ! start %<CR>
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
augroup END

" }}}
" Mail (and mutt) {{{

augroup ft_mail
    au!
    au Filetype mail setlocal formatoptions=ta
    au Filetype mail setlocal textwidth=72
    au Filetype mail setlocal spell
    au Filetype muttrc setlocal commentstring=#%s
augroup END

" }}}
" Markdown {{{

" Note: Most Markdown settings are in ftplugin folder
augroup ft_markdown
    au!
    au BufNewFile,BufReadPost *.md set filetype=markdown
    au FileType markdown setlocal omnifunc=htmlcomplete#CompleteTags
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
" Python {{{

" Note: Most python settings are in ftplugin folder

" Don't fold docstrings; see https://github.com/tmhedberg/SimpylFold
let g:SimpylFold_fold_docstring = 0
" Better highlighting; see https://github.com/vim-python/python-syntax
let g:python_highlight_all = 1

augroup ft_py
    au!
    " Fix else: syntax highlight and comment string
    au FileType python setlocal iskeyword-=:
    au Filetype python setlocal commentstring=#%s
    " Python notebooks are json files
    au BufNewFile,BufReadPost *.ipynb set filetype=json

    " Highlight all python functions
    au Filetype python syn match pythonAttribute2 /\.\h\w*(/hs=s+1,he=e-1
    au Filetype python hi def link pythonAttribute2 Function
augroup END

" }}}
" QuickFix {{{

" Note: here we also include preview window settings

augroup ft_quickfix
    au!
    au Filetype qf setlocal colorcolumn="" textwidth=0
    au Filetype qf call s:AdjustWindowHeight(1, 15)
    au Filetype qf nnoremap <buffer><silent> q :bdelete<CR>
    au Filetype qf nnoremap <buffer><silent> Q :bdelete<CR>
    " Automatically close corresponding loclist when quitting a window
    au QuitPre,BufDelete * if &filetype != 'qf' | silent! lclose | endif
augroup END

" Set window to the bottom and automatically adjust window to fit content
function! s:AdjustWindowHeight(minheight, maxheight)
    execute 'wincmd J|' . max([min([line('$'), a:maxheight]), a:minheight]) .
                \ 'wincmd _'
endfunction

" Maps (for both quickfix and location list)
nnoremap <silent> <Leader>pc :pclose<cr>
nnoremap <silent> <Leader>qf :copen<cr>
nnoremap <silent> <Leader>ll :lopen<cr>
nnoremap <silent> <Leader>qc :cclose<cr>
nnoremap <silent> <Leader>lc :lclose<cr>
nnoremap <silent> ]q :<C-U>execute v:count1 . 'cnext'<CR>
nnoremap <silent> [q :<C-U>execute v:count1 . 'cprevious'<CR>
nnoremap <silent> ]l :<C-U>execute v:count1 . 'lnext'<CR>
nnoremap <silent> [l :<C-U>execute v:count1 . 'lprevious'<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>

" }}}
" R {{{

augroup ft_R
    au!
    " Set the .Rprofile to R
    au BufNewFile,BufRead {Rprofile,.Rprofile,*.R} set filetype=r
    au FileType r foldmethod=syntax
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
                \ LAG ARBITRARY COUNT_IF LEAD JSON_EXTRACT
augroup END

" }}}
" Text {{{

augroup ft_text
    au!
    au Filetype text setlocal spell
    au Filetype text setlocal shiftwidth=2 tabstop=2 softtabstop=2
    " au FileType text setlocal foldmethod=marker
    au Filetype text syn match txtURL "\(http\|www\.\)[^ ]*"
augroup END

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

" Powerline-like appearance (we set the theme when setting the colorscheme)
let g:airline_powerline_fonts = 1
" Rounded right sep
let g:airline_right_sep = '' " U+E0B6

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

if dein#tap('airline') == 1
    " Change spacing of line and column number
    call airline#parts#define_raw('linenr', '%l')
    call airline#parts#define_accent('linenr', 'bold')
    let g:airline_section_z = airline#section#create(['%3p%%  ',
                \ '␤ ', 'linenr', ':%c '])
endif

" Check for trailing whitespace and mixed (tabs and spaces) indentation
let g:airline#extensions#whitespace#checks = ['trailing', 'indent']
let g:airline#extensions#whitespace#symbol = 'Ξ'

" Disable some extensions
let g:airline#extensions#wordcount#enabled = 0
let g:airline#extensions#cursormode#enabled = 0

" Tabline (minibufexpl replacement)
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'
let g:airline#extensions#tabline#buffer_min_count = 2
let airline#extensions#tabline#disable_refresh = 1
let g:airline#extensions#tabline#show_tab_type = 1
" Don't show some filetypes in the tabline
let g:airline#extensions#tabline#excludes = ['denite']

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
" Colorizer {{{

let g:colorizer_auto_filetype='css,html'
nnoremap <silent> <Leader>cz :ColorToggle<CR>

" }}}
" Colorscheme {{{

" Always use dark background
set background=dark

" Reload the colorscheme when we write the color file in order to see changes
augroup color_heraldish
    au!
    if has('nvim')
        au BufWritePost {heraldish.vim,onedarkish.vim} silent
                    \ call dein#recache_runtimepath()
    else
        au BufWritePost {heraldish.vim, onedarkish.vim} source $DOTVIM/vimrc
    endif
    au BufWritePost heraldish.vim colorscheme heraldish | AirlineRefresh
    au BufWritePost onedarkish.vim colorscheme onedarkish | AirlineRefresh
augroup END

" Actually set the colorscheme and airline theme
let g:one_allow_italics = 1  " use italics with onedarkish theme
colorscheme onedarkish  " alternatives are heraldish and onedarkish
let g:airline_theme = g:colors_name

" }}}
" Csv {{{

augroup ps_csv
    au!
    " Raw csv on and off (note: this disables syntax hl in all buffers)
    au Filetype csv nnoremap <silent> <buffer> <Leader>rc :
        \ if exists('g:syntax_on') <Bar>
        \   syntax off <Bar>
        \ else <Bar>
        \   syntax enable <Bar>
        \ endif <CR>
augroup END

" }}}
" Dadbod {{{

" let g:db = 'mysql://blah'

" }}}
" Dein {{{

let g:dein#install_log_filename = expand('$HOME/.cache/dein/dein.log')
let g:dein#install_max_processes = 16

" Function to open denite buffer with updates as updates finish
function! s:dein_update()
  call dein#update()
  Denite -no-quit -mode=normal dein_log:!
endfunction

" Maps
nnoremap <silent> <Leader>ul :execute "edit +" g:dein#install_log_filename<CR>
nnoremap <Leader>bu :call <SID>dein_update()<CR>
nnoremap  <Leader>rp :call dein#recache_runtimepath()<CR>
nnoremap <silent> <Leader>bl :Denite dein<CR>

" }}}
" Denite {{{

" Change default UI settings and highlighting
call denite#custom#option('default', {
            \ 'auto_resize': 1,
            \ 'auto_resume': 1,
            \ 'statusline': 0,
            \ 'winheight': 15,
            \ 'updatetime': 100,
            \ 'reversed': 1,
            \ 'prompt': '❯',
            \ 'prompt_highlight': 'Function',
            \ 'highlight_matched_char': 'Operator',
            \ 'highlight_matched_range': 'None',
            \ 'highlight_mode_insert': 'WildMenu'
            \ })

" Change some hl groups
hi default link deniteSource_grepFile Directory

" Change default matcher and sorter
call denite#custom#source('default', 'matchers', ['matcher/fuzzy',
        \ 'matcher/ignore_globs'])
call denite#custom#source('line', 'matchers', ['matcher/regexp'])
call denite#custom#source('default', 'sorters', ['sorter/rank'])

" Ignore some files and directories
" FIXME: This is not quite working
call denite#custom#filter('matcher/ignore_globs', 'ignore_globs',
        \ ['.git/', '__pycache__/', 'venv/',  'tmp/', 'doc/'])

" Buffer source settings
" TODO: Use converter_uniq_word
call denite#custom#var('buffer', 'date_format', '')

" Neomru
let g:neomru#file_mru_limit = 750
let g:neomru#time_format = ''

" Use ag for file_rec and grep
if executable('ag')
	call denite#custom#var('file/rec', 'command',
        \ ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])
	call denite#custom#var('grep', 'command', ['ag'])
	call denite#custom#var('grep', 'default_opts',
        \ ['--smart-case', '--vimgrep'])
	call denite#custom#var('grep', 'recursive_opts', [])
    call denite#custom#var('grep', 'pattern_opt', [])
	call denite#custom#var('grep', 'separator', ['--'])
	call denite#custom#var('grep', 'final_opts', [])
endif

" Functions
function! s:DeniteScanDir()
    let narrow_dir = input('Input narrowing directory: ', '', 'file')
    if narrow_dir == ''
        return
    endif
    call denite#start([{'name': 'file/rec', 'args': [narrow_dir]}])
endfunction
function! s:DeniteGrep()
    let narrow_dir = input('Target: ', '.', 'file')
    if narrow_dir == ''
        return
    endif
    let filetype = input('Filetype: ', '')
    if filetype == ''
        let ft_filter = '--all-types'
    else
        let ft_filter = '--' . filetype
    endif
    call denite#start([{'name': 'grep', 'args': [narrow_dir, ft_filter]}])
endfunction
function! s:DeniteTasklist()
    call denite#start([{'name': 'grep',
                \ 'args': [expand('%'), '','TODO:\s|FIXME:\s']}])
endfunction

" Mappings
nnoremap <silent> <Leader>ls :Denite file/rec<CR>
nnoremap <silent> <Leader>sd :call <SID>DeniteScanDir()<CR>
nnoremap <silent> <Leader>rd :Denite file_mru<CR>
nnoremap <silent> <Leader>be :Denite -default-action=context_split buffer<CR>
nnoremap <silent> <Leader>tl :call <SID>DeniteTasklist()<CR>
nnoremap <silent> <Leader>ag :call <SID>DeniteGrep()<CR>
nnoremap <silent> <Leader>dg :DeniteCursorWord grep<CR>
nnoremap <silent> <Leader>he :Denite help<CR>
nnoremap <silent> <Leader>yh :Denite neoyank<CR>
nnoremap <silent> <Leader>sh :Denite history:search<CR>
nnoremap <silent> <Leader>ch :Denite history:cmd<CR>
nnoremap <silent> <Leader>sm :Denite output:messages<CR>
nnoremap <silent> <Leader>dl :Denite line:forward<CR>
nnoremap <silent> <Leader>dw :DeniteCursorWord -auto-preview -vertical-preview
            \ line:forward<CR>
nnoremap <silent> <Leader>dq :Denite -no-quit quickfix<CR>
nnoremap <silent> <Leader>do :Denite -auto-preview -vertical-preview outline<CR>
nnoremap <silent> <Leader>dr :Denite -resume<CR>
nnoremap <silent> ]d :<C-U>execute 'Denite -resume  -immediately ' .
            \ -cursor-pos=+'. v:count1<CR>
nnoremap <silent> [d :<C-U>execute 'Denite -resume -immediately ' .
            \ -cursor-pos=-'. v:count1<CR>
nnoremap ]D :<C-u>Denite -resume -cursor-pos=$<CR>
nnoremap [D :<C-u>Denite -resume -cursor-pos=0<CR>
" NeoInclude and Denite tag
nnoremap <silent> <Leader>dte :NeoIncludeMakeCache<CR>:Denite
            \ tag:include<CR>
" FIXME: This should be improved
augroup ps_denite_tag
    au!
    au BufNewFile,BufRead *.{vim,tex,bib,r,R} nnoremap <buffer> <silent> <C-]>
                \ :NeoIncludeMakeCache<CR>
                \ :DeniteCursorWord -immediately
                \ -default-action=context_split tag:include<CR>
augroup END

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
call denite#custom#map('insert', '<C-d>', '<denite:scroll_window_downwards>',
            \ 'noremap')
call denite#custom#map('insert', '<C-u>', '<denite:scroll_window_upwards>',
            \ 'noremap')
call denite#custom#map('insert', '<C-h>', '<denite:move_caret_to_left>',
            \ 'noremap')
call denite#custom#map('insert', '<C-l>', '<denite:move_caret_to_right>',
            \ 'noremap')
call denite#custom#map('insert', '<C-s>', '<denite:do_action:split>', 'noremap')
call denite#custom#map('insert', '<C-v>', '<denite:do_action:vsplit>',
    \ 'noremap')
call denite#custom#map('insert', '<C-r>', '<denite:redraw>', 'noremap')
call denite#custom#map('insert', '<C-a>', '<denite:choose_action>', 'noremap')
call denite#custom#map('insert', '<C-y>', '<denite:do_action:yank>', 'noremap')
call denite#custom#map('insert', '<C-q>', '<denite:do_action:quickfix>',
            \ 'noremap')
call denite#custom#map('insert', '<C-Space>', '<denite:toggle_select_up>',
            \ 'noremap')
call denite#custom#map('insert', '<C-e>', '<denite:do_action:feedkeys>',
            \ 'noremap')
call denite#custom#map('normal', '<C-k>', '<denite:wincmd:k>', 'noremap')

" Custom split action
function! s:my_split(context)
    let split_action = 'vsplit'
    if winwidth(winnr('#')) <= 2 * (&tw ? &tw : 80)
        let split_action = 'split'
    endif
    call denite#do_action(a:context, split_action, a:context['targets'])
endfunction
call denite#custom#action('buffer,directory,file', 'context_split',
            \ function('s:my_split'))

" }}}
" Devicons {{{

" Add or override individual additional filetypes
if !exists('g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols')
    let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {}
endif
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {'tex': '',
            \ 'bib':'', 'gitcommit': ''}

" Add or override individual specific files
if !exists('g:WebDevIconsUnicodeDecorateFileNodesExactSymbols')
    let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {}
endif
let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {'.gitconfig': '',
            \ '.gitignore': '', 'bashrc': '', '.bashrc': '',
            \ 'bash_profile': '', '.bash_profile': ''}

" Disable denite integration (because it makes denite really slow)
let g:webdevicons_enable_denite = 0

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
    let g:echodoc#enable_at_startup = 1
else
    let g:echodoc#enable_at_startup = 0
endif

" Disable echodoc for tex and bib files
function! s:disable_echodoc() abort
  if &filetype ==# 'bib' || &filetype ==# 'tex'
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

augroup ps_fugitive
    au!
    " Start in insert mode for commits and enable spell checking
    au BufEnter *.git/COMMIT_EDITMSG call s:BufEnterCommit()
    au Filetype gitcommit setlocal spell
    au Filetype gitcommit nmap <silent> <buffer> Q q
    " Open git previous commits unfolded since we use Glog for the current file:
    au Filetype git setlocal foldlevel=1
    " Use rhubarb omnifunc in git commit messages
    au Filetype gitcommit setlocal omnifunc=rhubarb#omnifunc
    au BufEnter *.{git/COMMIT_EDITMSG,gitcommit}
                \ setlocal omnifunc=rhubarb#omnifunc
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
nnoremap <silent> <Leader>gi :Denite output:echo\ system("git\ init")<cr>
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
if dein#tap('denite') == 1
    nnoremap <silent> <Leader>gl :Glog -- %<CR>:Denite quickfix<CR>
    nnoremap <silent> <Leader>gL :Glog --<CR>:Denite quickfix<CR>
else
    nnoremap <silent> <Leader>gl :Glog -- %<CR>:copen<CR>
    nnoremap <silent> <Leader>gL :Glog --<CR>:copen<CR>
endif

" Commit explorer/browser (from gv.vim plugin)
nnoremap <silent> <Leader>cb :GV<cr>

" Merginal
let g:merginal_splitType = ''
let g:merginal_windowSize = 15

" }}}
" Fzf {{{

" Colors
let g:fzf_colors =
\ {'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Identifier'],
  \ 'fg+':     ['fg', 'CursorLine', 'Normal', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'Normal'],
  \ 'hl+':     ['fg', 'Identifier'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'prompt':  ['fg', 'Identifier'],
  \ 'pointer': ['fg', 'Keyword'],
  \ 'marker':  ['fg', 'CursorLineNr'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment']}

" Statusline
 " let g:fzf_nvim_statusline = 0
function! s:fzf_statusline()
  highlight default fzf1 guifg=#f8f6f2 guibg=#303030
  setlocal statusline=%#fzf1#fzf
endfunction
autocmd! User FzfStatusLine call <SID>fzf_statusline()

" Layout
if has('nvim')
  let $FZF_DEFAULT_OPTS .= ' --inline-info'
endif
let g:fzf_layout = {'down': '~30%'}

" Jump to the existing window if possible
let g:fzf_buffers_jump = 1

" Mappings
let g:fzf_action = {'ctrl-s': 'split', 'ctrl-v': 'vsplit'}

" }}}
" GitGutter {{{

" FIXME: Not working on Windows?
let g:gitgutter_map_keys = 0           " Disable default mappings
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
" G(M)undo {{{

" We are now using a fork called Mundo
let g:mundo_width = 60
let g:mundo_preview_height = 15
let g:mundo_help = 0
let g:mundo_tree_statusline = 'Mundo'
let g:mundo_preview_statusline = 'Mundo Preview'
if has('python3')
    let g:mundo_prefer_python3 = 1
endif

nnoremap <silent> <Leader>gu :MundoToggle<CR>

" }}}
" Indentline {{{

let g:indentLine_enabled = 0
let g:indentLine_showFirstIndentLevel = 1

" We need to define them here to avoid issues when running in the terminal
if g:colors_name ==# 'heraldish'
    let g:indentLine_color_gui = '#666462' " mediumgravel
    let g:indentLine_color_term = 241
elseif g:colors_name ==# 'onedarkish'
    let g:indentLine_color_gui = '#5c6370' " comment_grey
    let g:indentLine_color_term = 59
endif

nnoremap <silent> <leader>I :IndentLinesToggle<cr>

" }}}
" Jedi {{{

if has('python3')
    let g:jedi#force_py_version = 3
endif
" For deoplete to work
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
    " Set jedi completion to work with deoplete
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
set completeopt=menuone,preview,noinsert

" Autoclose preview when completion is finished
augroup ps_deoplete
    au!
    au CompleteDone * silent! pclose!
augroup END

" Always use deoplete (it is async)
let g:deoplete#enable_at_startup = 1
if s:is_mac
    let g:deoplete#sources#jedi#python_path = '/usr/local/bin/python3'
else
    let g:deoplete#sources#jedi#python_path =
                \ '/mnt/.linuxbrew/bin/python3'
endif

" Options
call deoplete#custom#option({
    \ 'smart_case': v:true,
    \ 'max_list': 150,
    \ 'refresh_always': v:true,
    \ 'auto_complete_delay': 5,
    \ 'sources': {
        \ 'bib': ['ultisnips'],
        \ 'snippets': ['ultisnips'],
        \ 'tex' : ['buffer', 'dictionary', 'ultisnips', 'file', 'omni'],
        \ 'r' : ['buffer', 'ultisnips', 'file', 'omni']
    \ },
\ })

" Source specific
" Use auto delimiter and autoparen (not in omni source)
call deoplete#custom#source('_', 'converters',
    \ ['converter_auto_delimiter', 'remove_overlap'])
" Show ultisnips first and activate completion after 1 character
call deoplete#custom#source('ultisnips', 'rank', 1000)
call deoplete#custom#source('ultisnips', 'min_pattern_length', 1)
" Extend max candidate width in popup menu for buffer source
call deoplete#custom#source('buffer', 'max_menu_width', 90)
" Complete dictionary after one character, rank dict completion first and set
" some keyword_patterns (via python3 regex)
call deoplete#custom#source('dictionary', 'min_pattern_length', 1)
call deoplete#custom#source('dictionary', 'rank', 1000)
call deoplete#custom#source('dictionary', 'keyword_patterns', {
            \ 'tex' : '\\?[a-zA-Z_]\w*',
\})
" Omni completion (for tex it requires vimtex plugin; to add commmand completion
" include '|\w*' in the regex)
call deoplete#custom#var('omni', 'input_patterns', {
        \ 'tex' : '\\(?:'
            \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
            \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
            \ . '|(?:include(?:only)?|input)\s*\{[^}]*'
            \ . '|usepackage(\s*\[[^]]*\])?\s*\{[^}]*'
            \ . '|documentclass(\s*\[[^]]*\])?\s*\{[^}]*'
            \ .')',
        \ 'gitcommit' : '((?:F|f)ix(?:es)?\s|'
            \ . '(?:C|c)lose(?:s)?\s|(?:R|r)esolve(?:s)?\s|(?:S|s)ee\s)\S*',
        \ 'javascript' : ['[^. *\t]\.\w*', '[A-Za-z]+'],
    \ }
\)

" External sources
let deoplete#sources#jedi#show_docstring = 0
if exists('$TMUX')
    " Tmux completion (with tmux-complete plugin)
    let g:tmuxcomplete#trigger = ''
endif

" Mappings
" Close popup and delete backward character
inoremap <expr><BS> deoplete#smart_close_popup()."\<BS>"
" Undo completion i.e remove whole completed word (default plugin mapping)
inoremap <expr> <C-g> deoplete#undo_completion()
" If a snippet is available enter expands it; if not available, it selects
" current candidate and closes the popup menu (i.e it ends completion)
inoremap <silent><expr><CR> pumvisible() ?
    \ (len(keys(UltiSnips#SnippetsInCurrentScope())) > 0 ?
    \ "\<C-y>\<C-R>=UltiSnips#ExpandSnippet()\<CR>" : "\<C-y>") : "\<CR>"
" Move in preview window with tab
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"

" Edit dictionary files
function! s:Edit_Dict()
    let dict_file = &l:dictionary
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
nnoremap <silent> <Leader>ed :call <SID>Edit_Dict()<CR>

" }}}
" Neomake {{{

let g:neomake_open_list = 2  " Open qf and preserve cusor position
let g:neomake_echo_current_error = 0 " Don't echo error for cusor line
let g:neomake_place_signs = 0  " Don't place signs
let g:neomake_highlight_columns = 0 " Don't hl columns with the error
let g:airline#extensions#neomake#enabled = 0 " Don't show on Airline
" call neomake#quickfix#enable()  " enable experimental quickfix formatting

" Python
let g:neomake_python_enabled_makers = ['flake8', 'mypy']
let g:neomake_python_flake8_args = ['--ignore=E402,W503']
let g:neomake_python_mypy_args = ['--ignore-missing-imports',
            \ '--follow-imports=skip', '--python-version', '3.6']

" Javascript
let g:neomake_javascript_enabled_makers = ['eslint']
let g:neomake_javascript_eslint_args = ['--no-color', '--format', 'compact',
            \ '--config', expand($HOME . '/.eslintrc.yaml'), '--fix']
let g:neomake_javascript_eslint_errorformat = ''.
        \ '%E%f: line %l\, col %c\, Error - %m,' .
        \ '%W%f: line %l\, col %c\, Warning - %m, %-G%.%#'
" Html
let g:neomake_html_enabled_makers = ['htmlhint']
let g:neomake_html_htmlhint_args = ['--format', 'unix', '--config',
            \ expand($HOME . '/.htmlhintrc')]
" Bash
let g:neomake_sh_enabled_makers = ['shellcheck']

" Run neomake after saving for files were we only have linter settings (i.e no
" other specific filetype settings in ftplugin folder)
augroup pl_neomake
    au!
    au BufWritePost *.{vim,yaml} silent Neomake
augroup END

" }}}
" Neoterm {{{

let g:neoterm_autoinsert = 1
let g:neoterm_automap_keys = ''
let g:neoterm_keep_term_open = 0
let g:neoterm_autoscroll = 1
let g:neoterm_default_mod = 'botright'
let g:neoterm_fixedsize = 1
if executable('ipython3')
    let g:neoterm_repl_python = 'ipython3'
else
    let g:neoterm_repl_python = 'python3'
endif

" Functions
function! s:OpenNeotermSplit(position)
    let old_size = g:neoterm_size
    let g:neoterm_size = 10
    if a:position ==# 'vertical'
        let g:neoterm_size = ''
        vertical Topen
    else
        botright Topen
    endif
    let g:neoterm_size = old_size
endfunction

function! s:RunLineREPL()
    let old_size = g:neoterm_size
    let old_autoinsert = g:neoterm_autoinsert
    let g:neoterm_size = 10
    let g:neoterm_autoinsert = 0
    TREPLSendLine
    stopinsert
    let g:neoterm_size = old_size
    let g:neoterm_autoinsert = old_autoinsert
endfunction

" Mappings
nnoremap <silent> <Leader>st :call <SID>OpenNeotermSplit('horizontal')<CR>
nnoremap <silent> <Leader>vt :call <SID>OpenNeotermSplit('vertical')<CR>
nnoremap <silent> <Leader>tc :Tclose<CR>
nnoremap <silent> <Leader>ri :call <SID>RunLineREPL()<CR>

augroup term_au
    au!
    " Get into insert mode whenever we enter a terminal buffer
    au BufEnter * if &buftype == 'terminal' | startinsert | endif
augroup END

" }}}
" Nvim-R {{{

" Console settings (using tmux)
let R_args = ['--no-save', '--quiet']
let R_in_buffer = 0
let R_source = '$DOTFILES/vim/bundle/repos/github.com/jalvesaq/Nvim-R/' .
            \  'R/tmux_split.vim'
let R_tmux_title = 'automatic'
let R_rconsole_width = 0  " Always use horizontal split
let R_rconsole_height = 12

let R_assign = 0  " Disable _ conversion
let r_syntax_folding = 1
let Rout_more_colors = 1
let rout_follow_colorscheme = 1

" Object browser
let R_objbr_place = 'LEFT'
let R_objbr_w = 30

function! s:RunR(mode)
    if g:rplugin_nvimcom_port == 0
        call StartR("R")
        while g:rplugin_nvimcom_port == 0
            sleep 300m
        endwhile
    endif
    if a:mode == 'file'
        call SendFileToR("silent")
    elseif a:mode == 'visual'
        call SendSelectionToR("silent", "down")
    endif
endfunction

augroup plugin_R
    au!
    au FileType r nmap <Leader>rs <Plug>RStart
    au FileType r nmap <Leader>rq <Plug>RClose
    au FileType r nmap <Leader>rr <Plug>RClearAll
    au FileType r nmap <Leader>rc <Plug>RClearConsole
    au FileType r nmap <Leader>rf :call <SID>RunR('file')<CR>
    au FileType r vmap <Leader>rf <Esc>:call <SID>RunR('visual')<CR>
    au FileType r nmap <Leader>ro <Plug>RUpdateObjBrowser
    au FileType r nmap <Leader>rv <Plug>RViewDF
    " Object browser mappings
    au FileType rbrowser nmap q <Plug>RUpdateObjBrowser
    au FileType rbrowser nmap zm :call RBrOpenCloseLs(0)<CR>
    au FileType rbrowser nmap zc :call RBrOpenCloseLs(0)<CR>
    au FileType rbrowser nmap zo :call RBrOpenCloseLs(1)<CR>
    au FileType rbrowser nmap zr :call RBrOpenCloseLs(1)<CR>
augroup END

" }}}
" SQHell {{{

" Load dict with connection details
if filereadable(expand('$HOME/sqh_connections.vim'))
    source $HOME/sqh_connections.vim
endif

let g:sqh_results_output = 'smart'

augroup ps_sqhell
    au!
    au Filetype sql nnoremap <silent> <buffer> <F7> :SQHExecute<CR>
    au Filetype sql vnoremap <silent> <buffer> <F7> :SQHExecute<CR>
augroup END

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

" Note: we use universal-ctags which supersedes exuberant ctags and compile it
" (on Windows) with `mingw32-make -f mk_mingw.mak`

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

" Settings
let g:tagbar_map_openfold = ['zo', 'l']
let g:tagbar_map_closeallfolds = 'zm'
let g:tagbar_map_openallfolds = 'zr'

" Mappings
nnoremap <silent> <Leader>tb :TagbarToggle<CR>

" }}}
" Tern {{{

" Use deoplete
let g:tern_request_timeout = 1
let g:tern_show_signature_in_pum = 0

" Use tern_for_vim
let g:tern#command = ['tern']
let g:tern#arguments = ['--persistent']

augroup ps_tern
    au!
    au Filetype javascript nmap <silent> <buffer> <Leader>jd :TernDef<CR>
    au Filetype javascript nmap <silent> <buffer> <Leader>rn :TernRename<CR>
    au Filetype javascript nmap <silent> <buffer> K :TernDoc<CR>
    au Filetype javascript nmap <silent> <buffer> <Leader>ap :TernRefs<CR>
    au BufRead,BufNewFile *.{javascript,js} setlocal omnifunc=tern#Complete
augroup END

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
" augroup ps_ultisnips
    " au!
    " au BufNewFile,BufRead *.{bib,py,snippets,tex,txt,vim,m,R,r,src,js,sh,yaml}
                " \ call s:ExpandHeader()
" augroup END
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
nnoremap <silent> <Leader>se :Denite output:call\ UltiSnips#ListSnippets()<CR>

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

if dein#tap('unite') == 1
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
endif

let g:unite_data_directory = $CACHE . '/plugins/unite'
let g:unite_force_overwrite_statusline = 0        " Avoid conflicts with Airline
let g:unite_enable_auto_select = 0                " Don't skip first line

" Buffer settings (don't show time)
let g:unite_source_buffer_time_format = ''

" Mappings (sources):
nnoremap <silent> <Leader>bm :Unite -profile-name=bookmark -default-action=rec
            \ -buffer-name=my-directories bookmark<CR>
nnoremap <silent> <Leader>ube :Unite -default-action=switch buffer<CR>
nnoremap <silent> <Leader>me :Unite mapping<CR>
nnoremap <silent> <Leader>uf :Unite function<CR>
nnoremap <silent> <Leader>ur :UniteResume -force-redraw -immediately<CR>
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
if dein#tap('unite') == 1
    call unite#custom_action('openable', 'context_split', s:my_split)
endif
unlet s:my_split

" }}}
" Vimfiler {{{

" Note: on Mac to delete files to the trash install rmtrash

if dein#tap('vimfiler') == 1
    function! VimfilerHookOpts() abort
        call vimfiler#custom#profile('default', 'context', {
                    \ 'direction' : 'topleft',
                    \ 'split': 1,
                    \ 'winwidth' : 40,
                    \ 'force_quit': 1,
                    \ 'status' : 1,
                    \ 'columns' : 'devicons:size',
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
    " Home directory
    nmap <buffer> h <Plug>(vimfiler_switch_to_home_directory)
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
let g:vimtex_compiler_enabled = 0
let g:vimtex_quickfix_enabled = 0
" Minted syntax highlight
let g:vimtex_syntax_minted = [
    \ {'lang' : 'python'},
    \ {'lang' : 'ipython', 'syntax' : 'python'},
    \ {'lang' : 'pycon', 'syntax' : 'python'}
    \ ]
" Disable insert mode mappings
let g:vimtex_imaps_enabled = 0

" Mappings
augroup ps_vimlatex
    au!
    au Filetype tex nmap <silent> <buffer> <Leader>tc
                \ <Plug>(vimtex-toc-open)
    au Filetype tex nnoremap <silent> <buffer> <Leader>ll :Denite
                \ -auto-preview -vertical-preview vimtex_labels<CR>
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

" }}}
" GUI and Terminal {{{

if has('gui_running') || has('nvim')
    " If there are no guicursor settings, use bar in insert mode and underscore
    " in replace mode
    if &guicursor ==# ''
        set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20
    endif
    " Disable cursor blinking in all modes (the blinking setting must go last)
    set guicursor+=a:blinkon0
endif

if has('gui_running')
    " GUI Settings
    " Patched font with fancy Unicode glyphs
    set guifont=Sauce\ Code\ Powerline:h11
    " Options (remove toolbar, menu, scrollbars; auto-copy visual selection and
    " use console dialogs)
    set guioptions=ac

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
    au BufWritePre {*.*,vimrc,bash_profile,bashrc,muttrc} call
                \ s:LastModified()
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
" Google it {{{

function! s:goog(pat, lucky)
  let q = '"'.substitute(a:pat, '["\n]', ' ', 'g').'"'
  let q = substitute(q, '[[:punct:] ]',
       \ '\=printf("%%%02X", char2nr(submatch(0)))', 'g')
  call system(printf('open "https://www.google.com/search?%sq=%s"',
                   \ a:lucky ? 'btnI&' : '', q))
endfunction

nnoremap <leader>? :call <SID>goog(expand("<cWORD>"), 0)<cr>
nnoremap <leader>! :call <SID>goog(expand("<cWORD>"), 1)<cr>

" }}}

" }}}
