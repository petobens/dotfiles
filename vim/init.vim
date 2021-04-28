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
        let g:python3_host_prog = '/usr/bin/python'
    endif
endif

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
    let $CACHE = expand('$DOTVIM/cache/Arch')
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

    " General coding/editing
    call dein#add('vim-airline/vim-airline')
    call dein#add('gioele/vim-autoswap')
    call dein#add('junegunn/vim-easy-align')
    call dein#add('jamessan/vim-gnupg', {'rev': 'main'})
    call dein#add('machakann/vim-highlightedyank')
    call dein#add('Yggdroot/indentLine')
    call dein#add('simnalamburt/vim-mundo', {'on_cmd' : 'MundoToggle'})
    call dein#add('neomake/neomake')
    if exists(':tnoremap')
        call dein#add('kassio/neoterm')
    endif
    call dein#add('preservim/nerdcommenter')
    call dein#add('justinmk/vim-sneak')
    call dein#add('aymericbeaumet/vim-symlink')
    call dein#add('preservim/tagbar')
    call dein#add('liuchengxu/vista.vim')
    call dein#add('SirVer/ultisnips')
    call dein#add('dhruvasagar/vim-zoom')

    " Colorschemes
    call dein#add('petobens/colorish', {'frozen': 1})

    " Tim Pope editing/coding plugins
    call dein#add('tpope/vim-abolish')
    call dein#add('tpope/vim-dispatch')
    call dein#add('tpope/vim-repeat')
    call dein#add('tpope/vim-rhubarb')
    call dein#add('tpope/vim-scriptease')
    call dein#add('tpope/vim-surround')

    " Git
    call dein#add('airblade/vim-gitgutter')
    call dein#add('junegunn/gv.vim')
    call dein#add('tpope/vim-fugitive')
    call dein#add('tommcdo/vim-fubitive')
    call dein#add('shumphrey/fugitive-gitlab.vim')
    call dein#add('rhysd/git-messenger.vim', {'on_cmd' : 'GitMessenger',
        \ 'on_map' : '<Plug>(git-messenger)'})

    " i3
    if executable('i3')
        call dein#add('mboughaba/i3config.vim')
    endif

    " Javascript and html
    call dein#add('pangloss/vim-javascript', {'on_ft' : 'javascript'})
    call dein#add('carlitux/deoplete-ternjs', {'on_ft' : 'javascript'})
    call dein#add('ternjs/tern_for_vim',
                \ {'on_ft' : 'javascript', 'build': 'npm install'})
    call dein#add('chrisbra/Colorizer', {'on_cmd': 'ColorToggle'})
    call dein#add('Glench/Vim-Jinja2-Syntax')

    " Latex
    call dein#add('lervag/vimtex', {'on_ft' : ['tex', 'bib']})

    " Markdown
    call dein#add('plasticboy/vim-markdown', {'on_ft' : 'markdown'})

    " Python
    call dein#add('davidhalter/jedi-vim', {'on_ft' : 'python'})
    call dein#add('jeetsukumaran/vim-pythonsense', {'on_ft' : 'python'})
    if has('nvim')
        " call dein#add('numirias/semshi')
        call dein#add('blueyed/semshi', {'rev': 'rm-mark_selected-from-_update_step'})
    endif
    call dein#add('tmhedberg/SimpylFold', {'on_ft' : 'python'})
    call dein#add('vim-python/python-syntax', {'on_ft' : 'python'})
    call dein#add('petobens/poet-v')  " won't work if loaded on_ft

    " R
    call dein#add('jalvesaq/Nvim-R')

    " SQL (and database related)
    call dein#add('chrisbra/csv.vim', {'on_ft': 'csv'})
    call dein#add('kristijanhusak/vim-dadbod', {'rev': 'async-query'})
    call dein#add('kristijanhusak/vim-dadbod-ui')
    call dein#add('kristijanhusak/vim-dadbod-completion')

    " TOML
    call dein#add('cespare/vim-toml', {'on_ft': 'toml'})

    " Shougo plugins
    call dein#add('Shougo/dein.vim')
    " Denite
    call dein#add('Shougo/denite.nvim')
    call dein#add('neoclide/denite-extra')
    call dein#add('raghur/fruzzy')
    call dein#add('neoclide/denite-git')
    call dein#add('Shougo/neomru.vim')
    call dein#add('Shougo/neoyank.vim')
    call dein#add('rafi/vim-denite-z')
    call dein#add('kmnk/denite-dirmark')
    " Deoplete
    call dein#add('Shougo/deoplete.nvim')
    call dein#add('Shougo/context_filetype.vim')
    call dein#add('Shougo/echodoc.vim')
    call dein#add('deoplete-plugins/deoplete-docker')
    if has('nvim')
        call dein#add('deoplete-plugins/deoplete-jedi')
        call dein#add('ncm2/float-preview.nvim')
    endif
    call dein#add('Shougo/neco-vim', {'name' : 'neco-vim'})
    call dein#add('Shougo/neco-syntax')
    call dein#add('Shougo/neoinclude.vim')
    " call dein#add('tbodt/deoplete-tabnine', {'build': './install.sh'})
    " Defx
    call dein#add('Shougo/defx.nvim')
    call dein#add('kristijanhusak/defx-icons')
    call dein#add('kristijanhusak/defx-git')

    " Tmux
    if !empty('$TMUX')
        call dein#add('christoomey/vim-tmux-navigator')
        call dein#add('wellle/tmux-complete.vim')
        call dein#add('ericpruitt/tmux.vim')
    endif

    " Workarounds
     if has('nvim')
        if s:is_linux
            " This allows to write without sudo
            " See: https://github.com/neovim/neovim/issues/1716
            call dein#add('lambdalisue/suda.vim')
        endif
        " This basically fixes visual block pasting
        " https://github.com/neovim/neovim/issues/1822#issuecomment-233152833
        call dein#add('bfredl/nvim-miniyank')
        map p <Plug>(miniyank-autoput)
        map P <Plug>(miniyank-autoPut)
     endif

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
set viewoptions=cursor,folds,curdir
set viewdir=$CACHE/tmp/view
set sessionoptions-=options,tabpages
set sessionoptions+=winpos,resize

function! s:SessionFileName()
    let session_dir = $CACHE . '/tmp/session/'
    silent! call s:MakeDirIfNoExists(session_dir)
    let session_file = 'vim_session'
    if !empty('$TMUX')
        let tmux_session = trim(system("tmux display-message -p '#S'"))
        let session_file .= '_' . tmux_session
    endif
    let session_file .= '.vim'
    return session_dir . session_file
endfunction
function! s:SaveSession()
    let session_file = s:SessionFileName()
    execute 'mksession! ' . session_file
endfunction
function! s:LoadSession()
    let session_file = s:SessionFileName()
    silent! execute 'source ' . session_file
endfunction

" Save and load viewoptions and previous session
augroup session
    au!
    au VimLeavePre * call s:SaveSession()
    au BufWinLeave {*.*,vimrc,vimrc_min,bashrc,config}
        \ if &previewwindow != 1 | mkview | endif
    au BufWinEnter {*.*,vimrc,vimrc_min,bashrc,config}
        \ if &previewwindow != 1 | silent! loadview | endif
augroup END
nnoremap <silent><Leader>ps :call <SID>LoadSession()<CR>

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
    set clipboard+=unnamedplus
    " This mimicks autoselect in neovim
    vmap <Esc> "+ygv<C-c>
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

" Make command line two lines high (don't set it to 1 if we get the
" `press ENTER` message when saving)
set cmdheight=1
" Reduce maximum height of the command line window (default is 7)
set cmdwinheight=4

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
" Folding and signs {{{

set foldlevelstart=0          " Start with everything folded
set foldopen+=insert,jump     " Commands that auto-unfold

" Close all folds and open and focus on fold containing current line
nnoremap <Leader>z zMzvzz
" Make zm and zr work as zM and zR respectively
nnoremap zm zM
nnoremap zr zR

" Map to use marker folding
nnoremap <silent> <Leader>mf :set foldmethod=marker<CR>zv

" Show signs in number column
set signcolumn=number

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

" Disable readonly warning
augroup no_ro_warn
    au!
    au FileChangedRO * set noreadonly
augroup END

" Diff algorithm
set diffopt=internal,filler,indent-heuristic,algorithm:histogram

" }}}
" Search, jumps and matching pairs {{{

if executable('rg')
    set grepprg=rg\ --smart-case\ --vimgrep\ --no-heading
    set grepformat=%f:%l:%c:%m,%f:%l:%m
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
nmap <silent> * :let @/ = '\<'.expand('<cword>').'\>'\|set hlsearch<CR>
nmap <kMultiply> *
nmap <silent> g* :let @/ = expand('<cword>')\|set hlsearch<CR>
nmap # #``

" Keep search matches and jumps in the middle of the window (zv allows it to
" work with folds)
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-o> <C-o>zvzz

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
" with denite
nnoremap <silent> <Leader>sg :Denite -no-start-filter spell_suggest<CR>
nnoremap <silent> <Leader>sf 0]s :Denite --no-start-filter
            \ -default-action=replace_misspelled_all spell_suggest<CR>

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
nnoremap <Leader>ic :set list!<cr>
" If shown (it disables linebreak option) use the following symbols for
" tabstops, end of lines, etc
set listchars=tab:▸\ ,eol:¬,trail:•,extends:»,precedes:«,nbsp:␣

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
" Use popmenu instead of horizontal statusline for wildmenu completion
set wildoptions=pum
" Stuff to ignore when tab completing
set wildignore=*~,*.o,*.obj,*.dll,*.dat,*.swp,*.zip,*.exe
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
augroup cline
    au!
    au WinLeave * if &filetype !=# 'denite' | setlocal nocursorline | endif
    au VimEnter,WinEnter,BufWinEnter *
                \ if &filetype !=# 'denite-filter' | setlocal cursorline | endif
augroup END

" When the page starts to scroll, keep the cursor 3 lines from the top and 3
" lines from the bottom
set scrolloff=3
" Toggle 'keep current line in the center of the screen' mode
nnoremap <Leader>C :let &scrolloff=999-&scrolloff<cr>

" Allow the cursor to be positioned anywhere (in block mode) (Note: setting to
" 'all' breaks placeholders position in Ultisnips)
set virtualedit=block,onemore

" Move the cursor to the first non-blank of the line
set startofline

" Add transparency for floating windows
if has('nvim')
    set winblend=7
endif

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

" Use alt to replace the original mappings to move to the top , middle and
" bottom of the screen
nnoremap <A-0> H
nnoremap <A-m> M
nnoremap <A-b> L

" Open folds when using G
nnoremap <silent> G :<C-U>silent! execute 'normal! ' . v:count . 'Gzo'<CR>

" }}}
" Word, line and paragraph operations {{{

" Swap current word with previous one (push word to the left)
nnoremap <silent> <A-h> :execute "silent normal! ms"<CR>
            \"_yiw?\k\+\%(\k\@!\_.\)\+\%#<CR>
            \:s/\(\%#\k\+\)\(\%(\k\@!\_.\)\+\)\(\k\+\)/\3\2\1/<CR><c-l>:noh<CR>
            \:execute "silent normal! `s"<CR>
" Swap current word with the next one (push word to the right)
nnoremap <silent> <A-l> :execute "silent normal! ms"<CR>
            \"_yiw:s/\(\%#\k\+\)\(\%(\k\@!\_.\)\+\)\(\k\+\)/\3\2\1/
            \<CR>/\k\+\%(\k\@!\_.\)\+<CR><c-l>:noh<CR>
            \:execute "silent normal! `s"<CR>

" Move lines up/down (and reindent afterwards)
nnoremap <silent> <A-j> :<C-U>silent execute 'move+' . v:count1<CR>zO==
nnoremap <silent> <A-k> :<C-U>silent execute 'move--' . v:count1<CR>zO==

" Keep the cursor in place while joining lines
nnoremap J mzJ`z
" Split line (sister to [J]oin lines; S is used by sneak plugin)
nnoremap <silent> <A-s> i<cr><esc>^mwgk:silent! s/\v +$//<cr>:noh<cr>`w

" Select until last character when starting visual mode linewise (i.e don't
" select extra blank character even when using `virtualedit=onemore`)
nnoremap vV 0vg_
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

" Quickfix replace with cdo (i.e for every file in quickfix)
nnoremap <Leader>qr :cdo %s/

" Increment and decrement
nnoremap + <C-a>
nnoremap - <C-x>

" Change map to start macro recording
noremap <Leader>mr q
map q <Nop>

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
    if winwidth(0) <= 2 * (&textwidth ? &textwidth : 80)
        let buf_dir = 'new'
    endif
    execute buf_dir
endfunction
nnoremap <silent> <Leader>nb :call <SID>NewBuffer()<CR>

" Ask for filename and filetype of a new (D)ocument to be edited in (D)esktop
nnoremap <Leader>dd :e $HOME/Desktop/
" Scratch buffer
nnoremap <expr> <Leader>sb ':edit ' . expand('%:p:h') . '/scratch/'

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
    if winwidth(0) <= 2 * (&textwidth ? &textwidth : 80)
        wincmd f
    else
        vertical wincmd f
    endif
endfunction
nnoremap <silent> gf :call <SID>GoToFileSplit()<CR>

" Diff in split window
function! s:DiffFileSplit()
    let l:save_pwd = getcwd()
    lcd %:p:h
    let win_id = win_getid()
    let other_file = input('Input file for diffing: ', '', 'file')
    if other_file ==# ''
        return
    endif
    if winwidth(0) <= 2 * (&textwidth ? &textwidth : 80)
        let diff_cmd = 'diffsplit '
    else
        let diff_cmd = 'vert diffsplit '
    endif
    execute diff_cmd . other_file
    call win_gotoid(win_id)
    normal! gg]c
    execute 'lcd ' . l:save_pwd
endfunction
nnoremap <silent> <Leader>ds :call <SID>DiffFileSplit()<CR>
nnoremap <silent> <Leader>de :diffoff!<CR>
nnoremap <silent> <Leader>du :diffupdate<CR>
" Use [h and ]h for jumping between hunks (changes)
nnoremap <expr> ]h &diff ? ']c' : ']h'
nnoremap <expr> [h &diff ? '[c' : '[h'

" Make horizontal window vertical and viceversa
nnoremap <silent> <Leader>hv <C-W>H<C-W>x
nnoremap <silent> <Leader>vh <C-W>K

" Jump to newer entry in jumplist (C-o jumps to older one)
nnoremap <silent> <C-y> <C-i>

" }}}
" Write, save and quit {{{

" Kill vim (unless there are unsaved buffers)
nnoremap <silent> <Leader>kv :qall<cr>

" Fast saving
nnoremap <silent><Leader>w :w!<CR>
" Save and close window
nnoremap <silent> <Leader>wc :w!<CR>:silent close<CR>
" Save and quit
nnoremap <Leader>wq :w!<CR>:q!<CR>
" No autocommand write
nnoremap <Leader>nw :noautocmd w!<CR>
" Saving when root privileges are required
if s:is_mac
    nnoremap <Leader>sw :w !sudo tee % >/dev/null<CR>
elseif s:is_linux && has('nvim') && dein#tap('suda') == 1
    nnoremap <Leader>sw :SudaWrite<CR>
    nnoremap <Leader>se :SudaRead<space>
endif

" Fast editing and reloading of the vimrc file
nnoremap <silent> <Leader>ev :e <C-r>=resolve(expand("$DOTVIM/init.vim"))<CR><CR>
nnoremap <silent> <Leader>rv :so $DOTVIM/init.vim<CR>
nnoremap <silent> <Leader>em :e <C-r>=resolve(expand("$DOTVIM/vimrc_min"))<CR><CR>

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
" Put (paste) text after or before current line
noremap <silent> <Leader>p :put<CR>
noremap <silent> <Leader>P :put!<CR>

" Pastetoggle doesn't redraw the screen (thus the status bar doesn't change)
" :set paste! does, so we use that (paste mode disables automatic reindenting)
nnoremap <silent> <F12> :set paste!<cr>

" Visually reselect what was just pasted (gv reselects previous selection)
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

" Yank error messages to system clipboard
nnoremap <silent> <Leader>ym :redir @*\|messages\|:redir END<CR>

" Yank output of a command
function! s:YankOutput()
    if s:is_win || s:is_mac
        redir @*
    else
        redir @+
    endif
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

" Emacs/readline bindings (similar to rsi.vim)
inoremap <C-a> <C-o>^
inoremap <expr><C-e> pumvisible() ? "\<C-e>" : "\<C-o>$"
inoremap <C-h> <C-o>h
inoremap <C-l> <C-o>l
inoremap <A-f> <C-o>w
inoremap <A-b> <C-o>b
inoremap <A-x> <C-W>

" Move lines up and down
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi

" Paste system clipboard
inoremap <A-p> <C-R>"

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

" Emacs/readline bindings (similar to rsi.vim)
cnoremap <C-a> <home>
cnoremap <C-e> <end>
cnoremap <C-h> <left>
cnoremap <C-l> <right>
cnoremap <A-f> <S-Right>
cnoremap <A-b> <S-Left>
cnoremap <A-x> <C-W>
cnoremap <C-x> <C-U>

" Insert the directory of the current buffer in command line mode
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:p:h') . '/' : '%%'

" Paste system clipboard to command line
cnoremap <A-p> <C-R>"

" }}}
" Terminal mode {{{

if exists(':tnoremap')
    " Exit terminal mode and return to vim normal mode (essentially the terminal
    " now becomes a regular vim buffer)
    " Note: we don't want to do this with <ESC> because when using vi mode most
    " readline programs actually use ESC to enter normal mode; since we
    " might also use jj to get into normal mode from within the readline program
    " we also avoid remapping it here and prefer kj instead
    " tnoremap <Esc> <C-\><C-n>
    tnoremap kj <C-\><C-n>
    " Window movement
    tnoremap <c-k> <C-\><C-n><C-w>k
    tnoremap <c-h> <C-\><C-n><C-w>h
    tnoremap <c-l> <C-\><C-n><C-w>l
    tnoremap <c-j> <C-\><C-n><C-w>j
    " Move between buffers
    tnoremap <C-A-p> <C-\><C-n>:bp<CR>
    tnoremap <C-A-n> <C-\><C-n>:bn<CR>
    " Jump to previous prompt
    tnoremap <silent> <C-[> <C-\><C-n>:normal! 0<CR>:call search(' ', 'b')<CR>
endif

" }}}

" }}}
" Filetype-specific {{{

" Autohotkey / Hammerspoon / i3 {{{

augroup ft_ahk_hs_i3
    au!
    au Filetype autohotkey setlocal commentstring=;%s foldmethod=marker
    au BufNewFile,BufRead,BufReadPost init.lua setlocal foldmethod=marker
    au BufNewFile,BufReadPost *i3/config set ft=i3config foldmethod=marker
augroup END

if s:is_mac
    nnoremap <silent> <Leader>eh :e
        \ <C-r>=resolve(expand("$HOME/.config/hammerspoon/init.lua"))<CR><CR>
elseif s:is_win
    nnoremap <silent> <Leader>eh :e
        \ <C-r>=resolve(expand("$HOME/autohotkey.ahk"))<CR><CR>
else
    nnoremap <silent> <Leader>eh :e
        \ <C-r>=resolve(expand("$HOME/.config/i3/config"))<CR><CR>
endif

" }}}
" Bash {{{

nnoremap <silent> <Leader>eb :e <C-r>=resolve(expand("$HOME/.bashrc"))<CR><CR>

augroup ft_bash
    au!
    au BufNewFile,BufReadPost {bash_profile,bashrc,fzf_bash.sh} set filetype=sh
        \ foldmethod=marker
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
" Config/Ini {{{

augroup ft_config
    au!
    au BufNewFile,BufReadPost *polybar/config,*rofi/config,dunstrc,*.dirs,
                \zathurarc,*mpv/*.conf,*onedrive/config,*fdignore,*vimivrc,
                \*pylintrc,*flake8,*ripgreprc,matplotlibrc
                \ set filetype=config foldmethod=marker
    au BufNewFile,BufReadPost vimiv.conf set filetype=dosini
    au BufNewFile,BufReadPost */.ssh/config,*/ssh/config set filetype=sshconfig
    au BufNewFile,BufReadPost tmux.conf set filetype=tmux
augroup END

" }}}
" Crontab {{{

augroup ft_crontab
    au!
    au FileType crontab set nobackup nowritebackup
augroup END

" }}}
" Html and CSS {{{

augroup ft_html
    au!
    au Filetype html setlocal shiftwidth=2 tabstop=2 softtabstop=2
    au BufNewFile,BufReadPost *.rasi set filetype=css
augroup END

" }}}
" Javascript {{{

augroup ft_js
    au!
    au Filetype javascript setlocal commentstring=//%s
augroup END

" }}}
" Json {{{

augroup ft_json
    au!
    au FileType json setlocal foldmethod=syntax
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
    au Filetype markdown setlocal textwidth=90 nolinebreak spell
augroup END

" Fast editing of todos files
nnoremap <silent> <Leader>etm :e $HOME/OneDrive/varios/todos_mutt.md<CR>
nnoremap <silent> <Leader>ets :e $HOME/OneDrive/varios/todos_coding_setup.md<CR>

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
    " pdbrc is a python file and python notebooks and Pipfile.lock json files
    au BufNewFile,BufReadPost pdbrc set filetype=python
    au BufNewFile,BufReadPost *.ipynb,Pipfile.lock set filetype=json
augroup END

" }}}
" QuickFix {{{

" Note: here we also include preview window settings

augroup ft_quickfix
    au!
    au Filetype qf setlocal colorcolumn="" textwidth=0 nospell
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

function! s:CloseAllLocation()
    let win_id = win_getid()
    noautocmd windo if &buftype == 'quickfix' | lclose | endif
    call win_gotoid(win_id)
endfunction

" Maps (for both quickfix and location list)
nnoremap <silent> <Leader>pc :pclose<cr>
nnoremap <silent> <Leader>qf :copen<cr>
nnoremap <silent> <Leader>ll :lopen<cr>
nnoremap <silent> <Leader>qc :cclose<cr>
nnoremap <silent> <Leader>lc :call <SID>CloseAllLocation()<CR>
nnoremap <silent> <Leader>lC :lclose<cr>
nnoremap <silent> ]q :<C-U>execute v:count1 . 'cnext'<CR>
nnoremap <silent> [q :<C-U>execute v:count1 . 'cprevious'<CR>
nnoremap <silent> ]l :<C-U>execute v:count1 . 'lnext'<CR>
nnoremap <silent> [l :<C-U>execute v:count1 . 'lprevious'<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>
nnoremap <expr><A-w>  &previewwindow ? "\<C-w>p" : "\<A-w>"

" }}}
" R {{{

augroup ft_R
    au!
    " Set the .Rprofile to R
    au BufNewFile,BufRead Rprofile,.Rprofile,*.R,
        \radian_profile,.radian_profile set filetype=r
    au FileType r setlocal foldmethod=syntax
augroup END

" }}}
" Ruby {{{

augroup ft_ruby
    au!
    " Vagrant files are ruby files
    au BufNewFile,BufRead Vagrantfile set filetype=ruby
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
    au BufNewFile,BufReadPost sqlplus_login set filetype=sql
    au BufNewFile,BufRead *.{pgsql,mssql,mysql} set filetype=sql
    " Add highlighting of some keywords
    au BufNewFile,BufRead *.sql set syntax=sql_jinja
    au Filetype sql syn keyword sqlKeyword INNER RIGHT LEFT OUTER JOIN OVER
                \ PARTITION
    au Filetype sql syn keyword sqlFunction DATE_PARSE DATE_DIFF DATE_TRUNC
                \ LAG ARBITRARY COUNT_IF LEAD JSON_EXTRACT
    au Filetype sql syn keyword sqlType INT TEXT
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
" TOML {{{

augroup ft_toml
    au!
    au BufNewFile,BufReadPost Pipfile,poetry.lock set filetype=toml
augroup END

" }}}
" Vim {{{

augroup ft_vim
    au!
    " Set fold method
    au FileType vim setlocal foldmethod=marker
    " Don't insert comment leader automatically
    au FileType vim setlocal formatoptions-=ro

    " Help/man settings
    au FileType help setlocal textwidth=78 relativenumber
    au FileType man setlocal iskeyword+=-
    " Place help window at the bottom
    au BufWinEnter *.txt if &ft == 'help' | wincmd J | endif
    au BufWinEnter *.txt if &ft == 'help' | 20 wincmd _ | endif
    " Mappings
    au FileType help nmap <buffer><silent>q :bd<CR>
    au Filetype help,man nmap <buffer><silent><Leader>tc gO
    au Filetype help,man nmap <buffer><silent><Leader>tC
                \ :execute 'normal gO' <bar> bd<CR>
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
" Change some symbols
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.readonly = ''
let g:airline_symbols.spell = ''
" Don't draw separators in empty sections (such as warning/errors)
let g:airline_skip_empty_sections = 1

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
    \ 't'  : 'T',
    \ 'ic' : 'IC',
    \ 'ix' : 'IC',
    \ 'ni' : '(I)',
    \ 'no' : 'O-P',
    \ }

if dein#tap('airline') == 1
    " Change spacing of line and column number
    call airline#parts#define_raw('linenr', '%l')
    call airline#parts#define_accent('linenr', 'bold')
    let g:airline_section_z = airline#section#create(['%3p%%  ',
                \ ' ', 'linenr', ':%c '])
endif

" Check for trailing whitespace and mixed (tabs and spaces) indentation
let g:airline#extensions#whitespace#checks = ['trailing', 'indent']
let g:airline#extensions#whitespace#symbol = 'Ξ'

" Disable some extensions
let g:airline#extensions#wordcount#enabled = 0
let g:airline#extensions#cursormode#enabled = 0
let g:airline#extensions#vista#enabled = 0

" Enable some extensions
let g:airline#extensions#tagbar#enabled = 1
let g:airline#extensions#neomake#enabled = 1
let airline#extensions#neomake#error_symbol = ' '
let airline#extensions#neomake#warning_symbol = ' '
let g:airline#extensions#poetv#enabled = 1

" Git branch/remote
let g:airline#extensions#branch#vcs_checks = ['untracked']
let g:airline_symbols.branch = ''
let g:airline_symbols.dirty = ''
let g:airline#extensions#branch#format = 'BranchWithRemote'
function! BranchWithRemote(name)
    let branch_icon = ''
    let remote = fugitive#repo().config('remote.origin.url')
    if remote =~# 'github'
        let branch_icon = ' '
    elseif remote =~# 'gitlab'
        let branch_icon = ' '
    elseif remote =~# 'bitbucket'
        let branch_icon = ' '
    endif
    return branch_icon . ' ' . a:name
endfunction

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
let g:airline#extensions#tabline#ignore_bufadd_pat =
            \ 'gundo|undotree|tagbar|^\[defx\]|^\[denite\]'

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

" Find color (syntax highlighting) group under the cursor
function! s:ColorGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun
nnoremap <silent><Leader>cg :call <SID>ColorGroup()<CR>

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

" Dadbod-UI
let g:db_ui_winwidth = 40
let g:db_ui_use_nerd_fonts = 1
let g:db_ui_show_database_icon = 1
let g:db_ui_show_help = 0
let g:db_ui_auto_execute_table_helpers = 1
let g:db_ui_execute_on_save = 0
let g:db_async = 1

let g:db_ui_icons = {
    \ 'expanded': '',
    \ 'collapsed': '',
\ }

function! s:ReadEnvVars(filepath)
    if !filereadable(expand(a:filepath))
        echoerr a:filepath . 'not found!'
        return
    endif
    let connections = readfile(expand(a:filepath))
    let conn_dict = {}
    for i in connections
        let split_str = split(i, '=')
        " Ignore comments
        if match(split_str[0], '^#.*') != -1
            continue
        endif
        let conn_dict[split_str[0]] = split_str[1]
    endfor
    return conn_dict
endfunction
if filereadable(expand('$HOME/.db-conns/.conns'))
    let g:dbs = s:ReadEnvVars(expand('$HOME/.db-conns/.conns'))
endif

" Mappings
nnoremap <silent> <Leader>db :DBUIToggle<CR>
augroup ps_dadbodui
    au!
    au Filetype dbui nmap <silent><buffer> <CR> <Plug>(DBUI_SelectLine)
    au Filetype dbui nmap <silent><buffer> zo <Plug>(DBUI_SelectLine)
    au Filetype dbui nmap <silent><buffer> zc <Plug>(DBUI_SelectLine)
    au Filetype dbui nmap <silent><buffer> <C-r> <Plug>(DBUI_Redraw)
    au Filetype sql nmap <silent><buffer> <Leader>rf <Plug>(DBUI_ExecuteQuery)
    au Filetype sql nmap <silent><buffer> <F7> <Plug>(DBUI_ExecuteQuery)
    au Filetype sql nmap <buffer> <Leader>rq :DBUIRenameBuffer<CR>
    au Filetype sql nmap <buffer> <Leader>fq :DBUIFindBuffer<CR>
augroup END

" }}}
" Defx {{{

call defx#custom#option('_', {
            \ 'show_ignored_files': 1,
            \ 'winwidth': 43,
            \ 'split': 'vertical',
            \ 'direction': 'topleft',
            \ 'columns': 'mark:indent:icon:filename:icons:size:git',
            \ 'root_marker': '﬌ ',
            \ 'floating_preview': 1,
            \ 'vertical_preview': 1,
            \ 'preview_width': 80,
            \ 'preview_height': 15
            \ })
call defx#custom#column('mark', {
            \ 'readonly_icon': '',
            \ 'selected_icon': '',
            \ })
call defx#custom#column('indent', { 'indent': '  '})
call defx#custom#column('icon', {
            \ 'root_icon': ' ',
            \ 'directory_icon': '',
            \ 'opened_icon': '',
            \ })
call defx#custom#column('filename', {
            \ 'min_width': 23,
            \ 'max_width_percent': 55,
            \ })
call defx#custom#column('time', {'format': '%Y%m%d %H:%M'})

" Shown only current directory in root
function! Root(path) abort
    return fnamemodify(a:path, ':t') . '/'
endfunction
call defx#custom#source('file', {'root': 'Root'})

" Maps
nnoremap <silent> <Leader>fe :Defx<CR>
nnoremap <silent> <Leader>ff :Defx `expand('%:p:h')`
            \ -search=`expand('%:p')`<CR>
nnoremap <silent> <Leader>df :Defx `expand('%:p:h') ` -search=`expand('%:p')`<CR>
            \ :execute 'Defx -new -split=horizontal -direction= '
            \ . b:defx.paths[0]<CR>:wincmd p<CR>
            \ :execute float2nr(&lines /2) . 'wincmd _ '<CR>
nnoremap <silent> <Leader>fb :Defx<CR>:Denite defx/dirmark<CR>
nnoremap <silent> <Leader>fr :Defx -resume<CR>
nnoremap <silent> <Leader>fm :execute 'lcd' . b:defx.paths[0]<CR>
            \ :call <SID>TmuxSplitCmd('ranger', '')<CR>

" Devicons
let g:defx_icons_enable_syntax_highlight = 0
let g:defx_icons_extensions = {
            \ 'tex': {'icon': ''},
            \ 'bib': {'icon': ''},
            \ 'gitcommit': {'icon': ''},
            \ 'pdf': {'icon': ''},
            \ 'r': {'icon': 'ﳒ'},
            \ 'R': {'icon': 'ﳒ'},
            \ }
let g:defx_icons_exact_matches = {
            \ '.gitconfig': {'icon': ''},
            \ '.gitignore': {'icon':''},
            \ 'bashrc': {'icon': ''},
            \ '.bashrc': {'icon': ''},
            \ 'bash_profile': {'icon':''},
            \ '.bash_profile': {'icon':''},
            \ }
let g:defx_icon_exact_dir_matches = {
            \ '.git'     : {'icon': ''},
            \ 'Desktop'  : {'icon': ''},
            \ 'Documents': {'icon': ''},
            \ 'Downloads': {'icon': ''},
            \ 'Dropbox'  : {'icon': ''},
            \ 'Music'    : {'icon': ''},
            \ 'Pictures' : {'icon': ''},
            \ 'Public'   : {'icon': ''},
            \ 'Templates': {'icon': ''},
            \ 'Videos'   : {'icon': ''},
            \ }

" Git
call defx#custom#column('git', 'indicators', {
  \ 'Modified'  : '✚',
  \ 'Staged'    : '●',
  \ 'Untracked' : '?',
  \ 'Renamed'   : '➜',
  \ 'Unmerged'  : 'שּׁ',
  \ 'Deleted'   : '✖',
  \ 'Unknown'   : '?'
  \ })

function! s:QuitAllDefx(context) abort
    let buffers = filter(range(1, bufnr('$')),
                \ 'getbufvar(v:val, "&filetype") ==# "defx"')
    let win_id = -1
    for i in buffers
        call defx#call_action('quit')
        if win_id == -1
            let win_id = win_getid()
            wincmd p
        endif
    endfor
    call win_gotoid(win_id)
endfunction

function! s:DefxUpdatePreview(dir, lines) abort
    execute 'normal! ' . a:lines . a:dir
    for nr in range(1, winnr('$'))
        if getwinvar(nr, '&previewwindow') == 1
            call defx#call_action('preview')
            break
        endif
    endfor
endfunction

" Filetype settings
augroup ps_defx
    au!
    au FileType defx call s:defx_settings()
    au FileType defx setlocal relativenumber
    au User defx-preview setlocal number winblend=4
augroup END


function! s:defx_settings()
    " Move updating preview
    nnoremap <silent><buffer> j :<C-u>call <SID>DefxUpdatePreview('j', v:count1)<CR>
    nnoremap <silent><buffer> k :<C-u>call <SID>DefxUpdatePreview('k', v:count1)<CR>
    " Exit with escape key and q, Q
    nnoremap <silent><buffer><expr> <ESC> defx#do_action('quit')
    nnoremap <silent><buffer><expr> q defx#do_action('quit')
    nnoremap <silent><buffer><expr> Q defx#do_action('call', '<SID>QuitAllDefx')
    " Edit and open with external program
    nnoremap <silent><buffer><expr> <CR>
        \ defx#is_directory() ? defx#do_action('open') :
        \ defx#is_binary() ? defx#do_action('execute_system') :
        \ defx#do_action('multi', ['drop', 'quit'])
    nnoremap <silent><buffer><expr> l
        \ defx#is_directory() ? defx#do_action('open') :
        \ defx#is_binary() ? defx#do_action('execute_system') :
        \ defx#do_action('multi', ['drop', 'quit'])
    nnoremap <silent><buffer><expr> o defx#do_action('execute_system')
   " Tree editing, opening and closing
   nnoremap <silent><buffer><expr> e
        \ defx#is_directory() ? defx#do_action('open_tree', 'toggle') :
        \ defx#do_action('multi', ['drop', 'quit'])
    nnoremap <silent><buffer><expr> zo defx#do_action('open_tree', 'toggle')
    nnoremap <silent><buffer><expr> zc defx#do_action('close_tree')
    nnoremap <silent><buffer><expr> zr defx#do_action('open_tree', 'recursive:3')
    " Open files in splits
    nnoremap <silent><buffer><expr> s
        \ defx#do_action('multi', [['drop', 'split'], 'quit'])
    nnoremap <silent><buffer><expr> v
        \ defx#do_action('multi', [['drop', 'vsplit'], 'quit'])
    " Copy, move, paste and remove
    nnoremap <silent><buffer><expr> c defx#do_action('copy')
    nnoremap <silent><buffer><expr> m defx#do_action('move')
    nnoremap <silent><buffer><expr> p defx#do_action('paste')
    nnoremap <silent><buffer><expr> d defx#do_action('remove_trash')
    " Yank and rename
    nnoremap <silent><buffer><expr> y defx#do_action('yank_path')
    nnoremap <silent><buffer><expr> r defx#do_action('rename')
    " New file and directory
    nnoremap <silent><buffer><expr> F defx#do_action('new_file')
    nnoremap <silent><buffer><expr> D defx#do_action('new_directory')
    " Move up a directory
    nnoremap <silent><buffer><expr> u defx#do_action('cd', ['..'])
    nnoremap <silent><buffer><expr> 2u defx#do_action('cd', ['../..'])
    nnoremap <silent><buffer><expr> 3u defx#do_action('cd', ['../../..'])
    nnoremap <silent><buffer><expr> 4u defx#do_action('cd', ['../../../..'])
    " Home directory
    nnoremap <silent><buffer><expr> h defx#do_action('cd')
    " Mark a file
    nnoremap <silent><buffer><expr> <Space>
        \ defx#do_action('toggle_select') . 'j'
    " Toggle hidden files
    nnoremap <silent><buffer><expr> <Leader>th
        \ defx#do_action('toggle_ignored_files')
    " Preview
    nnoremap <silent><buffer><expr> <A-v> defx#do_action('preview')
    nnoremap <silent><buffer> <A-w> <C-w>P
    " Redraw
    nnoremap <silent><buffer><expr> <C-r> defx#do_action('redraw')
    " Toggle sorting from filename to time (with last modified first)
    nnoremap <silent><buffer><expr> S defx#do_action('toggle_sort', 'Time')
    " Toggle columns to show time
	nnoremap <silent><buffer><expr> T defx#do_action('toggle_columns',
        \ 'icons:filename:time')
    " Open new defx buffer
    nnoremap <silent><buffer> <Leader>sp :execute
        \ 'Defx -new -split=horizontal -direction= ' . b:defx.paths[0]<CR>
        \ :wincmd p<CR>:execute float2nr(&lines /2) . 'wincmd _ '<CR>
    " change local window working dir to current dir
    nnoremap <silent><buffer> <Leader>cd :execute 'lcd' . b:defx.paths[0]<CR>
    " History source
    nnoremap <silent><buffer> <C-h> :Denite defx/history<CR>
    " Bookmarks source
    nnoremap <silent><buffer> b :Denite defx/dirmark<CR>

    " Resize window (increasing truncated filename)
    nnoremap <silent><buffer><expr> <C-A-l> defx#do_action('resize',
        \ defx#get_context().winwidth + 5)
    nnoremap <silent><buffer><expr> <C-A-h> defx#do_action('resize',
        \ defx#get_context().winwidth - 5)

    " Custom actions
    function! s:GetDefxBaseDir(candidate) abort
        if line('.') == 1
            let path_mod  = 'h'
        else
            let path_mod = isdirectory(a:candidate) ? 'h:h' : 'h'
        endif
        return fnamemodify(a:candidate, ':p:' . path_mod)
    endfunction
    function! s:denite_rec(context) abort
        let narrow_dir = s:GetDefxBaseDir(a:context.targets[0])
        execute 'Denite -default-action=defx ' .
                    \ 'file/rec:' . narrow_dir
    endfunction
    function! s:denite_rec_no_ignore(context) abort
        let narrow_dir = s:GetDefxBaseDir(a:context.targets[0])
        execute 'Denite -default-action=defx ' .
                    \ 'file/rec/noignore:' . narrow_dir
    endfunction
    function! s:denite_dir_rec(context) abort
        let narrow_dir = s:GetDefxBaseDir(a:context.targets[0])
        execute 'Denite -default-action=defx ' .
                    \ 'directory_rec:' . narrow_dir
    endfunction
    function! s:denite_dir_rec_no_ignore(context) abort
        let narrow_dir = s:GetDefxBaseDir(a:context.targets[0])
        execute 'Denite -default-action=defx ' .
                    \ 'directory_rec/noignore:' . narrow_dir
    endfunction
    function! s:denite_z(context) abort
        execute 'Denite -default-action=defx z'
    endfunction
    function! s:denite_parents_dirs(context) abort
        let narrow_dir = s:GetDefxBaseDir(a:context.targets[0])
        execute 'Denite -default-action=defx ' .
                    \ 'parent_dirs:' . narrow_dir
    endfunction
    function! s:defx_ranger(context) abort
        let narrow_dir = s:GetDefxBaseDir(a:context.targets[0])
        call s:TmuxSplitCmd('ranger', narrow_dir)
    endfunction
    nnoremap <silent><buffer><expr> <C-t>
                \ defx#do_action('call', '<SID>denite_rec')
    nnoremap <silent><buffer><expr> <A-t>
                \ defx#do_action('call', '<SID>denite_rec_no_ignore')
    nnoremap <silent><buffer><expr> <A-c>
                \ defx#do_action('call', '<SID>denite_dir_rec')
    nnoremap <silent><buffer><expr> <A-d>
                \ defx#do_action('call', '<SID>denite_dir_rec_no_ignore')
    nnoremap <silent><buffer><expr> <A-z>
                \ defx#do_action('call', '<SID>denite_z')
    nnoremap <silent><buffer><expr> <A-p>
                \ defx#do_action('call', '<SID>denite_parents_dirs')
    nnoremap <silent><buffer><expr> ge
                \ defx#do_action('call', '<SID>defx_ranger')
    nnoremap <silent><buffer><expr> od
                \ defx#do_action('execute_command', ['dragon-drag-and-drop -a -x *', 'async'])
    nnoremap <silent><buffer><expr> <A-j>
                \ defx#do_action('call', '<SID>scroll_preview_down')
    nnoremap <silent><buffer><expr> <A-k>
                \ defx#do_action('call', '<SID>scroll_preview_up')
endfunction

" }}}
" Dein {{{

let g:dein#install_log_filename = expand('$HOME/.cache/dein/dein.log')
let g:dein#install_max_processes = 16

" Function to open denite buffer with updates as updates finish
function! s:dein_update()
  call dein#update()
  Denite -no-start-filter -post-action=open dein/log:!
endfunction

" Maps
nnoremap <silent> <Leader>ul :execute "edit +" g:dein#install_log_filename<CR>
nnoremap <Leader>bu :call <SID>dein_update()<CR>
nnoremap <Leader>rp :call dein#recache_runtimepath()<CR>
nnoremap <silent> <Leader>bl :Denite dein<CR>

" }}}
" Denite {{{

" Change default UI settings and highlighting
call denite#custom#option('default', {
            \ 'auto_resize': 1,
            \ 'statusline': 0,
            \ 'winheight': 15,
            \ 'winminheight': -1,
            \ 'reversed': 1,
            \ 'prompt': '❯',
            \ 'match_highlight': 1,
            \ 'highlight_prompt': 'Function',
            \ 'highlight_matched_char': 'Operator',
            \ 'highlight_matched_range': 'None',
            \ 'start_filter': 1,
            \ 'filter_updatetime': 30,
            \ 'vertical_preview': 1,
            \ 'floating_preview': 1,
            \ 'preview_width': float2nr(&columns / 2.3),
            \ 'preview_height': 15,
            \ })

" Set cursorline hl
augroup ps_denite_cursorline
    au!
    au WinEnter * if &filetype ==# 'denite'
        \ |   highlight CursorLineDenite guibg=#282c34 gui=bold
        \ |   highlight! link CursorLine CursorLineDenite
        \ | endif
augroup END

" Fruzzy matcher
let g:fruzzy#usenative = 0
let g:fruzzy#sortonempty = 0
call denite#custom#source('_', 'matchers', ['matcher/fruzzy',
        \ 'matcher/ignore_globs'])

" Other matcher and sorting options
call denite#custom#source('line', 'matchers', ['matcher/regexp'])
call denite#custom#source('default', 'sorters', ['sorter/rank'])
call denite#custom#source('z', 'sorters', ['sorter_z'])

" Devicon converter
call denite#custom#source('file/rec,file/rec/noignore,buffer,fast_file_mru,'
            \ .'directory_rec,directory_rec/noignore,parent_dirs,grep,z',
            \ 'converters', ['converter/devicons'])

" Ignore some files and directories
call denite#custom#filter('matcher/ignore_globs', 'ignore_globs',
        \ ['.git/', '__pycache__/', 'venv/',  'tmp/', 'doc/', 'man://*'])

" Buffer source settings
call denite#custom#var('buffer', 'date_format', '')

" Neomru
let g:neomru#file_mru_limit = 750
let g:neomru#time_format = ''
let g:neomru#do_validate = 1
let g:neomru#update_interval = 300

" Use fd for file_rec and ripgrep for grep
if executable('fd')
    call denite#custom#var('file/rec', 'command',
        \ ['fd', '--type', 'f', '--follow', '--hidden', '--exclude', '.git',
        \ ''])
    call denite#custom#var('directory_rec', 'command',
        \ ['fd', '--type', 'd', '--follow', '--hidden', '--exclude', '.git',
        \ ''])
    " Define alias that don't ignore vcs files
    call denite#custom#alias('source', 'file/rec/noignore', 'file/rec')
    call denite#custom#var('file/rec/noignore', 'command',
        \ ['fd', '--type', 'f', '--follow', '--hidden', '--exclude', '.git',
        \ '--no-ignore-vcs', ''])
    call denite#custom#alias('source', 'directory_rec/noignore',
        \ 'directory_rec')
    call denite#custom#var('directory_rec/noignore', 'command',
        \ ['fd', '--type', 'd', '--follow', '--hidden', '--exclude', '.git',
        \ '--no-ignore-vcs', ''])
endif
if executable('rg')
    call denite#custom#var('grep', 'command', ['rg'])
    call denite#custom#var('grep', 'default_opts',
            \ ['--smart-case', '--vimgrep', '--no-heading'])
    call denite#custom#var('grep', 'recursive_opts', [])
    call denite#custom#var('grep', 'pattern_opt', [])
    call denite#custom#var('grep', 'separator', ['--'])
    call denite#custom#var('grep', 'final_opts', [])
endif

" Bookmarks source (dirmark)
call g:dirmark#set_data_directory_path($CACHE .
            \ '/plugins/denite/denite-dirmark')

" Functions
function! s:DeniteScanDir(...)
    let narrow_dir = input('Input narrowing directory: ', '', 'file')
    if narrow_dir ==# ''
        return
    endif
    let git_ignore = get(a:, 1, 1)
    let source = git_ignore == 1 ? 'file/rec' : 'file/rec/noignore'
    call denite#start([{'name': source, 'args': [narrow_dir]}])
endfunction
function! s:DeniteGrep(...)
    if !executable('rg')
        echoerr 'ripgrep is not installed or not in  your path.'
        return
    endif
    let l:save_pwd = getcwd()
    lcd %:p:h
    let narrow_dir = input('Target: ', '.', 'file')
    if narrow_dir ==# ''
        return
    endif
    " Don't search gitignored files by default
    let extra_args = ''
    let git_ignore = get(a:, 1, 1)
    if git_ignore == 0
        let extra_args = '--no-ignore-vcs '
    endif
    let filetype = input('Filetype: ', '')
    if filetype ==# ''
        let ft_filter = ''
    else
        let ft_filter = '--type ' . filetype
    endif
    " Allow to run in interactive mode (or require an input pattern)
    let grep_args = [narrow_dir, extra_args . ft_filter]
    let interactive = get(a:, 2, 0)
    if interactive == 1
        call add (grep_args, '!')
    endif
    execute 'lcd ' . l:save_pwd
    call denite#start([{'name': 'grep', 'args': grep_args}],
                \ {'start_filter': interactive})
endfunction
function! s:DeniteTasklist(...)
    if a:0 >=1 && a:1 ==# '.'
        let target = a:1
    else
        let target = expand('%')
    endif
    call denite#start([{'name': 'grep',
                \ 'args': [target, '','TODO:\s|FIXME:\s']}])
endfunction
function! s:DeniteVisualSearch(direction)
    let temp = @s
    norm! gv"sy
    let visual_selection = @s
    let visual_selection = escape(visual_selection, '$+%\.{*|@^')
    let @s = temp
    call denite#start([{'name': 'line', 'args': [a:direction]}],
                \ {'input': visual_selection})
endfunction
function! s:DeniteBookmarkAddFunc(path)
    execute 'Denite dirmark/add -default-action=add -immediately-1 -path=' .
                \ expand(a:path)
endfunction
" Note: we need to pass the parent dir of the candidate we want to bookmark
command -nargs=1 -complete=file DeniteBookmarkAdd
            \ call s:DeniteBookmarkAddFunc(<q-args>)

" Mappings
nnoremap <silent> <C-t> :DeniteBufferDir file/rec<CR>
nnoremap <silent> <A-t> :DeniteBufferDir file/rec/noignore<CR>
nnoremap <silent> <Leader>ls :DeniteBufferDir file/rec<CR>
nnoremap <silent> <Leader>lS :DeniteBufferDir file/rec/noignore<CR>
nnoremap <silent> <Leader>lu :execute 'Denite file/rec:' . expand('%:p:h:h')<CR>
nnoremap <silent> <Leader>lU :execute 'Denite file/rec/noignore:' .
            \ expand('%:p:h:h')<CR>
nnoremap <silent> <Leader>sd :call <SID>DeniteScanDir()<CR>
nnoremap <silent> <Leader>sD :call <SID>DeniteScanDir(0)<CR>
nnoremap <silent> <A-z> :Denite z<CR>
nnoremap <silent> <A-c> :DeniteBufferDir directory_rec<CR>
nnoremap <silent> <A-d> :DeniteBufferDir directory_rec/noignore<CR>
nnoremap <silent> <A-p> :DeniteBufferDir -no-start-filter parent_dirs<CR>
nnoremap <silent> <Leader>rd :Denite fast_file_mru<CR>
nnoremap <silent> <Leader>be :Denite buffer<CR>
nnoremap <silent> <Leader>tl :call <SID>DeniteTasklist()<CR>
nnoremap <silent> <Leader>tL :call <SID>DeniteTasklist('.')<CR>
nnoremap <silent> <Leader>rg :lcd %:p:h<CR>:call <SID>DeniteGrep(1)<CR>
nnoremap <silent> <Leader>rG :lcd %:p:h<CR>:call <SID>DeniteGrep(0)<CR>
nnoremap <silent> <Leader>ig :lcd %:p:h<CR>:call <SID>DeniteGrep(1, 1)<CR>
nnoremap <silent> <Leader>iG :lcd %:p:h<CR>:call <SID>DeniteGrep(0, 1)<CR>
nnoremap <silent> <Leader>dg :lcd %:p:h<CR>:DeniteCursorWord -no-start-filter
            \ grep<CR>
nnoremap <silent> <Leader>he :Denite help<CR>
nnoremap <silent> <Leader>yh :Denite neoyank<CR>
nnoremap <silent> <Leader>sh :Denite history:search<CR>
nnoremap <silent> <Leader>ch :Denite command_history<CR>
nnoremap <silent> <Leader>sm :Denite output:messages<CR>
nnoremap <silent> <Leader>me :Denite output:map<CR>
nnoremap <silent> <Leader>uf :Denite output:function<CR>
nnoremap <silent> <Leader>dl :Denite line:forward<CR>
nnoremap <silent> <Leader>dw :DeniteCursorWord line:forward<CR>
vnoremap <silent> <Leader>dw :call <SID>DeniteVisualSearch('forward')<CR>
nnoremap <silent> <Leader>dq :Denite -post-action=suspend quickfix<CR>
nnoremap <silent> <Leader>gl :Denite gitlog:all<CR>
nnoremap <silent> <Leader>gL :Denite gitlog<CR>
nnoremap <silent> <Leader>bm :Denite dirmark<CR>
nnoremap <silent> <Leader>dr :Denite -resume<CR>
nnoremap <silent> <Leader>dR :Denite -resume -no-start-filter<CR>
nnoremap <silent> ]d :Denite -resume -immediately -cursor-pos=+1<CR>
nnoremap <silent> [d :Denite -resume -immediately -cursor-pos=-1<CR>
nnoremap ]D :<C-u>Denite -resume -cursor-pos=$<CR>
nnoremap [D :<C-u>Denite -resume -cursor-pos=0<CR>
nnoremap <silent> <Leader>te :Denite outline<CR>
nnoremap <silent> <Leader>tE :NeoIncludeMakeCache<CR>:Denite tag:include<CR>
" FIXME: This should be improved
augroup ps_denite_tag
    au!
    au BufNewFile,BufRead *.{vim,tex,bib,r,R} nnoremap <buffer> <silent> <C-]>
                \ :NeoIncludeMakeCache<CR>
                \ :DeniteCursorWord -immediately
                \ -default-action=context_split tag:include<CR>
augroup END

augroup ps_denite_setup
    au!
    au FileType denite call s:denite_mappings()
    au FileType denite setlocal signcolumn=no
    au FileType denite-filter call s:denite_filter_mappings()
    au FileType denite-filter
       \ call deoplete#custom#buffer_option('auto_complete', v:false)
    au FileType denite-filter setlocal nocursorline
    au User denite-preview setlocal number winblend=0
augroup END

" Buffer mappings (note that the denite buffer only has normal mode)
function! s:denite_mappings() abort
    " Denite buffer
    nnoremap <silent><buffer><expr> <ESC> denite#do_map('quit')
    nnoremap <silent><buffer><expr> <C-c> denite#do_map('quit')
    nnoremap <silent><buffer><expr> q denite#do_map('quit')
    nnoremap <silent><buffer><expr> i denite#do_map('open_filter_buffer')
    " Actions
    nnoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
    nnoremap <silent><buffer> j :<C-u>call
        \ <SID>DeniteMoveCursorCandidateWindow('j', v:count1, 'normal')<CR>
    nnoremap <silent><buffer> <C-n> :<C-u>call
        \ <SID>DeniteMoveCursorCandidateWindow('j', v:count1, 'normal')<CR>
    nnoremap <silent><buffer> k :<C-u>call
        \ <SID>DeniteMoveCursorCandidateWindow('k', v:count1, 'normal')<CR>
    nnoremap <silent><buffer> <C-p> :<C-u>call
        \ <SID>DeniteMoveCursorCandidateWindow('k', v:count1, 'normal')<CR>
    nnoremap <silent><buffer><expr> <C-v> denite#do_map('do_action', 'vsplit')
    nnoremap <silent><buffer><expr> <C-s> denite#do_map('do_action', 'split')
    nnoremap <silent><buffer><expr> <C-r> denite#do_map('redraw')
    nnoremap <silent><buffer><expr> <C-x> denite#do_map('choose_action')
    nnoremap <silent><buffer><expr> <C-y> denite#do_map('do_action', 'yank')
    nnoremap <silent><buffer> <Tab> :call <SID>denite_tab_action()<CR>
    nnoremap <silent><buffer><expr> <Space> denite#do_map('toggle_select') . 'k'
    nnoremap <silent><buffer><expr> <C-Space> denite#do_map('toggle_select') . 'k'
    nnoremap <silent><buffer><expr> <A-v> denite#do_map('do_action', 'preview')
    nnoremap <silent><buffer> <A-w> <C-w>P
    nnoremap <silent><buffer><expr> <A-u> denite#do_map('restore_sources')
    nnoremap <silent><buffer><expr> <C-q> denite#do_map('do_action', 'quickfix')
    nnoremap <silent><buffer> <A-q> :call <SID>denite_quickfix_all()<CR>
    " Custom actions
    nnoremap <silent><buffer><expr> <A-j> denite#do_map('do_action',
                \ 'scroll_preview_down')
    nnoremap <silent><buffer><expr> <A-k> denite#do_map('do_action',
                \ 'scroll_preview_up')
    nnoremap <silent><buffer><expr> <A-f> denite#do_map('do_action', 'defx')
    nnoremap <silent><buffer><expr> <C-t> denite#do_map('do_action',
                \ 'candidate_file_rec')
    nnoremap <silent><buffer><expr> <A-c> denite#do_map('do_action',
                \ 'candidate_directory_rec')
    nnoremap <silent><buffer><expr> <A-p> denite#do_map('do_action',
                \ 'candidate_parent_dir')
endfunction

function! s:DeniteMoveCursorCandidateWindow(dir, lines, mode) abort
    " noautocmd is needed to preserve proper cursorline highlight
    if a:mode ==# 'filter'
        noautocmd call win_gotoid(win_findbuf(g:denite#_filter_parent)[0])
    endif
    execute 'normal! ' . a:lines . a:dir
    for nr in range(1, winnr('$'))
        if getwinvar(nr, '&previewwindow') == 1
            call denite#call_map('do_action', 'preview')
            break
        endif
    endfor
    if a:mode ==# 'filter'
        noautocmd call win_gotoid(g:denite#_filter_winid)
        startinsert!
    endif
endfunction

function! s:denite_filter_mappings() abort
    " Denite filter buffer
    inoremap <silent><buffer><expr> <C-c> denite#do_map('quit')
    inoremap <silent><buffer><expr> <ESC> denite#do_map('quit')
    nnoremap <silent><buffer><expr> <C-c> denite#do_map('quit')
    nnoremap <silent><buffer><expr> <ESC> denite#do_map('quit')
    nnoremap <silent><buffer><expr> q denite#do_map('quit')
    " Quit filter buffer if line is empty
    imap <buffer> <C-e> <Plug>(denite_filter_backspace)
    imap <buffer> <C-h> <C-o>h
    " Prevent backspace to move cursor from filter to buffer window
    iunmap <buffer> <BS>
    " Actions
    inoremap <silent><buffer> <C-j>
        \ <Esc>:call <SID>DeniteMoveCursorCandidateWindow('j', 1, 'filter')<CR>
    inoremap <silent><buffer> <C-n>
        \ <Esc>:call <SID>DeniteMoveCursorCandidateWindow('j', 1, 'filter')<CR>
    inoremap <silent><buffer> <C-k>
        \ <Esc>:call <SID>DeniteMoveCursorCandidateWindow('k', 1, 'filter')<CR>
    inoremap <silent><buffer> <C-p>
        \ <Esc>:call <SID>DeniteMoveCursorCandidateWindow('k', 1, 'filter')<CR>
    inoremap <silent><buffer> <C-u>
        \ <Esc>:call <SID>DeniteMoveCursorCandidateWindow('k', 12, 'filter')<CR>
    inoremap <silent><buffer> <C-d>
        \ <Esc>:call <SID>DeniteMoveCursorCandidateWindow('j', 12, 'filter')<CR>
    inoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
    nnoremap <silent><buffer><expr> <CR> denite#do_map('do_action')
    inoremap <silent><buffer><expr> <C-v> denite#do_map('do_action', 'vsplit')
    inoremap <silent><buffer><expr> <C-s> denite#do_map('do_action', 'split')
    inoremap <silent><buffer><expr> <C-r> denite#do_map('redraw')
    inoremap <silent><buffer><expr> <C-x> denite#do_map('choose_action')
    inoremap <silent><buffer><expr> <C-y> denite#do_map('do_action', 'yank')
    inoremap <silent><buffer> <Tab> <ESC>:call <SID>denite_tab_action()<CR>
    inoremap <silent><buffer> <C-Space>
        \ <ESC>:call denite#call_map('toggle_select')<CR><C-w>p
        \ :call cursor(line('.')-1, 0)<CR><C-w>pA
    inoremap <silent><buffer><expr> <A-v> denite#do_map('do_action', 'preview')
    nnoremap <silent><buffer><expr> <A-v> denite#do_map('do_action', 'preview')
    inoremap <silent><buffer> <A-w> <Esc><C-w>P
    inoremap <silent><buffer><expr> <A-u> denite#do_map('restore_sources')
    inoremap <silent><buffer><expr> <C-q> denite#do_map('do_action', 'quickfix')
    inoremap <silent><buffer> <A-q> <ESC>:call <SID>denite_quickfix_all()<CR>
    " Custom actions
    inoremap <silent><buffer><expr> <A-j> denite#do_map('do_action',
                \ 'scroll_preview_down')
    inoremap <silent><buffer><expr> <A-k> denite#do_map('do_action',
                \ 'scroll_preview_up')
    inoremap <silent><buffer><expr> <A-f> denite#do_map('do_action', 'defx')
    inoremap <silent><buffer><expr> <C-t> denite#do_map('do_action',
                \ 'candidate_file_rec')
    inoremap <silent><buffer><expr> <A-c> denite#do_map('do_action',
                \ 'candidate_directory_rec')
    inoremap <silent><buffer><expr> <A-p> denite#do_map('do_action',
                \ 'candidate_parent_dir')
endfunction

" Custom actions
function! s:my_split(context)
    let split_action = 'vsplit'
    if winwidth(winnr('#')) <= 2 * (&textwidth ? &textwidth : 80)
        let split_action = 'split'
    endif
    call denite#do_action(a:context, split_action, a:context['targets'])
endfunction
function! s:defx_open(context)
    let path = a:context['targets'][0]['action__path']
    let file = fnamemodify(path, ':p')
    let file_search = filereadable(expand(file)) ? ' -search=' . file : ''
    let dir = denite#util#path2directory(path)
    if &filetype ==# 'defx'
      call defx#call_action('cd', [dir])
      call defx#call_action('search', [file])
    else
        execute('Defx ' . dir . file_search)
    endif
endfunction
function! s:defx_preview(context)
    let path = a:context['targets'][0]['action__path']
    let dir = denite#util#path2directory(path)
    let file = fnamemodify(path, ':p')
    let file_search = filereadable(expand(file)) ? ' -search=' . file : ''

    let has_preview_win = 0
    let defx_path = 0
    for nr in range(1, winnr('$'))
        if getwinvar(nr, '&previewwindow') == 1
            let has_preview_win = 1
            let defx_var = getbufvar(winbufnr(nr), 'defx')
            let defx_path =  defx_var.paths[0]
        endif
    endfor
    if has_preview_win == 1 && defx_path ==# (dir . '/')
        call defx#custom#column('filename', {'min_width': 23, 'max_width': -55})
        pclose!
        return
    endif

    let pos = win_screenpos(win_getid())
    let win_row = pos[0] - 1
    let win_col = (pos[1] - 1) + winwidth(0) - a:context.preview_width

    execute 'silent rightbelow vertical pedit! defx_tmp'
    wincmd P
    silent! setlocal nobuflisted
    call nvim_win_set_config(win_getid(), {
        \ 'relative': 'editor',
        \ 'row': win_row,
        \ 'col': win_col,
        \ 'width': a:context.preview_width,
        \ 'height': a:context.preview_height,
        \ })
    let fn_width = 45
    call defx#custom#column('filename',
        \ {'min_width': fn_width, 'max_width': fn_width })
    execute 'Defx -no-show-ignored-files -new -split=no ' .
                \ '-ignored-files=.*,__pycache__ ' .
                \ '-auto-recursive-level=1 ' .  dir . file_search
    call defx#call_action('open_tree', 'toggle')
    silent! setlocal norelativenumber nonumber
    doautocmd User denite-preview
    wincmd p
endfunction
function! s:candidate_file_rec(context)
    let path = a:context['targets'][0]['action__path']
    let narrow_dir = denite#util#path2directory(path)
    let sources_queue = a:context['sources_queue'] + [[
            \ {'name': 'file/rec/noignore', 'args': [narrow_dir]},
            \ ]]
    return {'sources_queue': sources_queue}
endfunction
function! s:candidate_directory_rec(context)
    let path = a:context['targets'][0]['action__path']
    let narrow_dir = denite#util#path2directory(path)
    let sources_queue = a:context['sources_queue'] + [[
            \ {'name': 'directory_rec/noignore', 'args': [narrow_dir]},
            \ ]]
    return {'sources_queue': sources_queue}
endfunction
function! s:candidate_parent_dir(context)
    let path = a:context['targets'][0]['action__path']
    let narrow_dir = denite#util#path2directory(path)
    let sources_queue = a:context['sources_queue'] + [[
            \ {'name': 'parent_dirs', 'args': [narrow_dir]},
            \ ]]
    return {'sources_queue': sources_queue}
endfunction
function! s:scroll_preview_down(context)
    wincmd P
    execute 'normal! 10j'
    wincmd p
endfunction
function! s:scroll_preview_up(context)
    wincmd P
    execute 'normal! 10k'
    wincmd p
endfunction
function! s:yank_commit(context)
    let candidate = a:context['targets'][0]['word']
    let commit_hash = matchstr(candidate, '*\s\+\zs\w*\ze\s-')
    call setreg('+', commit_hash)
endfunction
function! s:denite_quickfix_all()
    call denite#call_map('toggle_select_all')
    call denite#call_map('do_action', 'quickfix')
endfunction
function! s:denite_tab_action()
    let source_name = b:denite_statusline.sources
    if match(source_name, '^history') != -1
        " Edit action in history search source is called feedkeys
        call denite#call_map('do_action', 'feedkeys')
    else
        call denite#call_map('do_action', 'edit')
    endif
endfunction
call denite#custom#action('buffer,directory,file', 'context_split',
        \ function('s:my_split'))
call denite#custom#action('buffer,directory,file,openable,dirmark', 'defx',
        \ function('s:defx_open'))
call denite#custom#action('directory,directory_rec,directory_rec/noignore,' .
        \'dirmark', 'preview', function('s:defx_preview'), {'is_quit': 0})
call denite#custom#action('buffer,directory,file,openable,dirmark',
        \ 'candidate_file_rec', function('s:candidate_file_rec'))
call denite#custom#action('buffer,directory,file,openable,dirmark',
        \ 'candidate_directory_rec', function('s:candidate_directory_rec'))
call denite#custom#action('buffer,directory,file,openable,dirmark',
        \ 'candidate_parent_dir', function('s:candidate_parent_dir'))
call denite#custom#action('file', 'narrow',
        \ {context -> denite#do_action(context, 'open', context['targets'])})
call denite#custom#action('buffer,directory,file,openable,dirmark,gitlog',
        \ 'scroll_preview_down', function('s:scroll_preview_down'),
        \ {'is_quit': 0})
call denite#custom#action('buffer,directory,file,openable,dirmark,gitlog',
        \ 'scroll_preview_up', function('s:scroll_preview_up'),
        \ {'is_quit': 0})
call denite#custom#action('gitlog', 'yank', function('s:yank_commit'))

" Define default actions (don't do this in mapping definitions because it will
" overwrite any other override)
call denite#custom#source('directory_rec,directory_rec/noignore,parent_dirs,' .
        \ 'z,dirmark', 'default_action', 'candidate_file_rec')
call denite#custom#source('dein', 'default_action', 'defx')

" }}}
" Deoplete {{{

" Vim completion settings
set pumheight=15                          " Popup menu max height
if has('nvim')
    set pumblend=7                       " Popup menu transparency
endif
set complete=.                            " Scan only the current buffer
set completeopt=menuone,preview,noinsert

" Autoclose preview when completion is finished
augroup ps_deoplete
    au!
    au CompleteDone * silent! pclose!
augroup END

" Always use deoplete (it is async)
let g:deoplete#enable_at_startup = 1

" Options
call deoplete#custom#option({
    \ 'smart_case': v:true,
    \ 'max_list': 150,
    \ 'refresh_always': v:true,
    \ 'auto_complete_delay': 100,
    \ 'num_processes': 4,
    \ 'sources': {
        \ 'bib': ['ultisnips'],
        \ 'snippets': ['ultisnips'],
        \ 'tex' : ['buffer', 'ultisnips', 'file', 'omni'],
        \ 'r' : ['buffer', 'ultisnips', 'file', 'omni']
    \ },
    \ 'omni_patterns':  {
		\ 'r': ['\h\w*::\w*', '\h\w*\$\w*', '\h\w*(w*'],
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
" Omni completion
call deoplete#custom#var('omni', 'input_patterns', {
        \ 'tex' : '\\(?:'
            \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
            \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
            \ . '|(?:include(?:only)?|input)\s*\{[^}]*'
            \ . '|(usepackage|RequirePackage|PassOptionsToPackage)(\s*\[[^]]*\])?\s*\{[^}]*'
            \ . '|documentclass(\s*\[[^]]*\])?\s*\{[^}]*'
            \ . '|begin(\s*\[[^]]*\])?\s*\{[^}]*'
            \ . '|end(\s*\[[^]]*\])?\s*\{[^}]*'
            \ . '|\w*'
            \ .')',
        \ 'gitcommit' : '((?:F|f)ix(?:es)?\s|'
            \ . '(?:C|c)lose(?:s)?\s|(?:R|r)esolve(?:s)?\s|(?:S|s)ee\s)\S*',
        \ 'javascript' : ['[^. *\t]\.\w*', '[A-Za-z]+'],
    \ }
\)

" External sources
let deoplete#sources#jedi#show_docstring = 1
if !empty('$TMUX')
    " Tmux completion (with tmux-complete plugin)
    let g:tmuxcomplete#trigger = ''
endif

" Reduce tabine rank
call deoplete#custom#source('tabnine', 'rank', 101)

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
" Move in preview window with tab (and map shift-tab to detab)
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><s-tab> pumvisible() ? "\<c-p>" : "\<C-d>"
" Use Ctrl-C to end completion
imap <C-c> <C-e>

" Edit dictionary files
function! s:Edit_Dict()
    let dict_file = &l:dictionary
    if empty(dict_file)
        echo 'No dictionary file found.'
        return
    endif
    let split_windows = 'vsplit '
    if winwidth(0) <= 2 * (&textwidth ? &textwidth : 80)
        let split_windows = 'split '
    endif
    execute split_windows . dict_file
endfunction
nnoremap <silent> <Leader>ed :call <SID>Edit_Dict()<CR>

" }}}
" Devicons {{{

" Add or override individual additional filetypes
if !exists('g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols')
    let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {}
endif
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {'tex': '',
            \ 'bib':'', 'gitcommit': '', 'r': 'ﳒ', 'R': 'ﳒ'}

" Add or override individual specific files
if !exists('g:WebDevIconsUnicodeDecorateFileNodesExactSymbols')
    let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {}
endif
let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {'.gitconfig': '',
            \ '.gitignore': '', 'bashrc': '', '.bashrc': '',
            \ 'bash_profile': '', '.bash_profile': ''}

" Disable denite integration (we enable our own filter)
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
" e.g: to align around all `|` press `<Leader>aip*|`
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
nmap <silent> <Leader>a, :execute "silent normal mz\<Plug>(EasyAlign)ip*,`z"<CR>
vmap <silent> <Leader>a, :mz<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*,"<CR>`z
nmap <silent> <Leader>a& :execute "silent normal mz\<Plug>(EasyAlign)ip*&`z"<CR>
vmap <silent> <Leader>a& :mz<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*&"<CR>`z
nmap <silent> <Leader>a= :execute "silent normal mz\<Plug>(EasyAlign)ip*=`z"<CR>
vmap <silent> <Leader>a= mz:<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*="<CR>`z
nnoremap <silent> <Leader>a: mzvip:<C-U>silent '<,'>EasyAlign*:>l1<CR>`z
vnoremap <silent> <Leader>a: mz:<C-U>silent '<,'>EasyAlign*:>l1<CR>`z

" Python and vim comments
nmap <silent> <Leader>a# :execute "silent normal mz\<Plug>(EasyAlign)ip*#`z"<CR>
vmap <silent> <Leader>a# :mz<C-u>execute
            \ "silent normal gv\<Plug>(EasyAlign)*#"<CR>`z
nmap <silent> <Leader>a" :execute "silent normal mz\<Plug>(EasyAlign)ip*\"`z"<CR>
vmap <silent> <Leader>a" mz:<C-u>execute
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
" Float preview {{{

set completeopt-=preview
let g:float_preview#docked = 0
let g:float_preview#max_width = 60

function! s:SetFloatPreviewWinOpts()
    call nvim_win_set_option(g:float_preview#win, 'winblend', &pumblend)
endfunction
function! s:MoveFloatPreview(direction)
    let buffer_lines =
        \ len(getbufline(nvim_win_get_buf(g:float_preview#win), 1, '$'))
    let cursor_line = nvim_win_get_cursor(g:float_preview#win)[0]
    if a:direction ==# 'down'
        let cursor_line += &previewheight
    else
        let cursor_line -= &previewheight
    endif
    if cursor_line <= 1
        let cursor_line = 1
    endif
    if cursor_line >= buffer_lines
        let cursor_line = buffer_lines
    endif
    call nvim_win_set_cursor(g:float_preview#win, [cursor_line, 0])
    return ''
endfunction

augroup ps_float_preview
    au!
    au User FloatPreviewWinOpen call <SID>SetFloatPreviewWinOpts()
    au User FloatPreviewWinOpen inoremap <silent><expr> <A-j>
        \ <SID>MoveFloatPreview('down')
    au User FloatPreviewWinOpen inoremap <silent><expr> <A-k>
        \ <SID>MoveFloatPreview('up')
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
    " Complete with issues from github and gitlab
    au Filetype gitcommit
        \ if fugitive#repo().config('remote.origin.url') =~#
            \ 'gitlab.com' |
            \ setlocal omnifunc=gitlab#omnifunc |
        \ else |
            \ setlocal omnifunc=rhubarb#omnifunc |
        \ endif
    au BufEnter *.{git/COMMIT_EDITMSG,gitcommit}
        \ if fugitive#repo().config('remote.origin.url') =~#
            \ 'gitlab.com' |
            \ setlocal omnifunc=gitlab#omnifunc |
        \ else |
            \ setlocal omnifunc=rhubarb#omnifunc |
        \ endif
    au BufEnter,WinEnter *.git/index execute '15 wincmd _'
    au BufEnter,WinEnter *.git/COMMIT_EDITMSG execute '15 wincmd _'
    au FileType fugitive nnoremap <buffer><silent> q :call <SID>QuitGstatus()<CR>
    au FileType fugitive nmap <buffer><silent> ]h ]c
    au FileType fugitive nmap <buffer><silent> [h [c
augroup END

" Gitlab
if filereadable(expand('$HOME/.gitlab_access_token'))
    let s:gitlab_keys = readfile(expand('$HOME/.gitlab_access_token'))
    if len(s:gitlab_keys) == 1
        let g:gitlab_api_keys = {'gitlab.com': s:gitlab_keys[0]}
    endif
endif

function! s:BufEnterCommit()
    normal! gg0
    if getline('.') ==# ''
        startinsert
    endif
endfunction

function! s:QuitGstatus()
    wincmd p
    let win_id = win_getid()
    wincmd p
    bdelete
    call win_gotoid(win_id)
endfunction

" The following command is needed for Gbrowse to work since netrw fails to open
" links when set shellslash is set on Windows and disabling shellslash around
" Gbrowse (for instance using NoShellSlash() function) doesn't work nicely.
if s:is_win
    command! -bar -nargs=1 Browse silent! exe '! start ' escape(<q-args>, '!%#')
endif

" Mappings
nnoremap <silent> <Leader>gi :Denite output:echo\ system("git\ init")<cr>
nnoremap <silent> <Leader>gd :Gdiffsplit<CR>:wincmd x<CR>
nnoremap <Leader>gD :Git diff<space>
nnoremap <silent> <Leader>gs :botright Git<CR>:wincmd J<bar>:15 wincmd _<CR>
nnoremap <silent> <Leader>gc :w!<CR>:Git commit<CR>
nnoremap <Leader>gC :ShowGitChanges<space>
nnoremap <Leader>gM :Git! mergetool<CR>
nnoremap <Leader>gr :Git rebase -i<space>
nnoremap <silent> <Leader>gR :GRemove<CR>
nnoremap <silent> <Leader>gp :call <SID>NoShellSlash('Dispatch git push')<CR>
nnoremap <silent> <Leader>gF :call
            \ <SID>NoShellSlash('Dispatch git push --force-with-lease')<CR>
nnoremap <silent> <Leader>gP :Dispatch git pull<CR>
nnoremap <Leader>gf :Dispatch git fetch<space>
nnoremap <silent> <Leader>gb :GBrowse<CR>
vnoremap <silent> <Leader>gb :GBrowse<CR>
nnoremap <silent> <Leader>gB :GBrowse!<CR>
vnoremap <silent> <Leader>gB :GBrowse!<CR>


" Show Git Changes against any git object (i.e commit, branch, etc)
command! -nargs=1 ShowGitChanges silent! call s:ShowGitChanges(<f-args>)

function! s:ShowGitChanges(git_object) abort
  execute 'Git difftool --name-only ' . a:git_object
  call s:GDiffQfEntry()
  copen
  nnoremap <buffer> <CR> <CR><BAR>:call <sid>GDiffQfEntry()<CR>
  wincmd p
  wincmd x
endfunction

function s:GDiffQfEntry() abort
  for window in getwininfo()
    if window.winnr !=? winnr() && bufname(window.bufnr) =~? '^fugitive:'
      execute 'bdelete' window.bufnr
    endif
  endfor
  cc
  diffoff!
  let qf = getqflist({'context': 0, 'idx': 0})
  if get(qf, 'idx') && type(get(qf, 'context')) == type({}) && type(get(qf.context, 'items')) == type([])
    let diff = get(qf.context.items[qf.idx - 1], 'diff', [])
    for i in reverse(range(len(diff)))
        execute (i ? 'leftabove' : 'rightbelow') 'vert diffsplit' fnameescape(diff[i].filename)
        wincmd x
        11copen
        wincmd p
        wincmd h
    endfor
  endif
endfunction

" }}}
" HighlightedYank {{{

let g:highlightedyank_highlight_duration = 500
let g:highlightedyank_max_lines = 2000

" }}}
" GitGutter {{{

" FIXME: Not working on Windows?
let g:gitgutter_map_keys = 0           " Disable default mappings
let g:gitgutter_signs = 0              " Don't show signs (toggle them with map)
let g:gitgutter_terminal_reports_focus = 0

" Mappings
nnoremap <silent> <Leader>gg :GitGutterSignsToggle<CR>
nmap ]h <Plug>(GitGutterNextHunk)<bar>zvzz
nmap [h <Plug>(GitGutterPrevHunk)<bar>zvzz
nmap <Leader>hp <Plug>(GitGutterPreviewHunk)

" Note:
" We could stage and remove individual hunks with GitGutterStage(Revert)Hunk but
" we can also do this with Gdiff: i) use d[p]ut from working file and d[o]btain
" index file to stage individual hunks, ii) save the index file and iii) commit

" }}}
" GitMessenger {{{

let g:git_messenger_always_into_popup = v:true

nmap <silent> <Leader>gm <Plug>(git-messenger)

function! s:setup_gitmessengerpopup() abort
    setlocal winblend=3
    nmap <buffer><C-p> o
    nmap <buffer><C-n> O
endfunction
augroup ps_gitmessenger
    au!
    au FileType gitmessengerpopup call <SID>setup_gitmessengerpopup()
augroup END

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
" GV {{{

function! s:GVYankCommit()
    let commit_hash = matchstr(getline('.'), '-\d\+\s\zs\w*\ze\s')
    call setreg('+', commit_hash)
endfunction

augroup ps_gv
    au!
    au FileType GV nmap <silent> <buffer> <C-y> :call <SID>GVYankCommit()<CR>
augroup END

nnoremap <silent> <Leader>cb :GV<cr>
nnoremap <silent> <Leader>cB :GV!<cr>  " only current file

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

" For deoplete to work
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#max_doc_height = 15
let g:jedi#use_tabs_not_buffers = 0  " Open goto in split buffers
let g:jedi#use_splits_not_buffers = 'winwidth'
let g:jedi#smart_auto_mappings = 0

" Change/disable some mappings (to be enabled later on)
let g:jedi#goto_assignments_command = ''
let g:jedi#goto_command = ''
let g:jedi#goto_stubs_command = ''
let g:jedi#rename_command = ''
let g:jedi#documentation_command = ''  " We use K mapping in our ftplugin file
let g:jedi#usages_command = ''

augroup ps_jedi
    au!
    " Jedi mappings (we do it here so they are silent mappings)
    au Filetype python nnoremap <buffer><silent> <C-]>
        \ :call jedi#goto_assignments()<CR>
    au Filetype python nnoremap <buffer><silent> <Leader>jd
        \ :call jedi#goto()<CR>
    au Filetype python nnoremap <buffer><silent> <Leader>js
        \ :call jedi#goto_stubs()<CR>
    au Filetype python nnoremap <buffer><silent> <Leader>rn
        \ :call jedi#rename()<CR>
    au Filetype python nnoremap <buffer><silent> <Leader>ap
        \ :call jedi#usages()<CR>:cclose<CR>:Denite -post-action=suspend quickfix<CR>
    " Set jedi completion to work with deoplete
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
" Neomake {{{

let g:neomake_open_list = 2  " Open qf and preserve cusor position
let g:neomake_echo_current_error = 0 " Don't echo error for cusor line
let g:neomake_highlight_columns = 0 " Don't hl columns with the error
let g:neomake_virtualtext_current_error = 1
let g:neomake_virtualtext_prefix = ' '
call neomake#quickfix#enable()  " enable experimental quickfix formatting

" Set sign symbols
let g:neomake_place_signs = 0  " Don't place signs
let g:neomake_error_sign = {'text': ' ', 'texthl': 'NeomakeErrorSign'}
let g:neomake_warning_sign = {'text': ' ', 'texthl': 'NeomakeWarningSign'}

" Python
let g:neomake_python_enabled_makers = ['flake8', 'mypy', 'pylint']

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
" Markdown
let g:neomake_markdown_enabled_makers = ['markdownlint']
let g:neomake_markdown_markdownlint_args = ['--config',
            \ expand($HOME . '/.markdownlint.json')]
" SQL
let g:neomake_sql_enabled_makers = ['sqlint']

" Run neomake after saving for files were we only have linter settings (i.e no
" other specific filetype settings in ftplugin folder)
augroup pl_neomake
    au!
    au BufWritePost *.{vim,yaml,yml,markdown,md,bashrc,bash_profile},bashrc,
                \bash_profile,Dockerfile,dockerfile silent Neomake
augroup END

" }}}
" Neoterm {{{

let g:neoterm_autoinsert = 1
let g:neoterm_automap_keys = ''
let g:neoterm_keep_term_open = 0
let g:neoterm_autoscroll = 1
let g:neoterm_default_mod = 'botright'
let g:neoterm_fixedsize = 1
let g:neoterm_marker = ''
if executable('ipython3')
    let g:neoterm_repl_python = 'ipython3'
else
    let g:neoterm_repl_python = 'python3'
endif

" Functions
function! s:OpenNeotermSplit(position)
    let old_size = g:neoterm_size
    let g:neoterm_size = 12
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
    let g:neoterm_size = 12
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
" Terminal w(ipe) (clear)
nnoremap <silent> <Leader>tw :Tclear<CR><ESC>
nnoremap <silent> <Leader>ri :call <SID>RunLineREPL()<CR>

augroup term_au
    au!
    " Get into insert mode whenever we enter a terminal buffer
    au BufEnter * if &buftype == 'terminal' | startinsert | endif
augroup END

" }}}
" Nvim-R {{{

" Note: to use this plugin with packrat we need first to run:
" `packrat::set_opts(external.packages = c("nvimcom"))`

" Console settings (using tmux)
if executable('radian')
    let R_app = 'radian'
    let R_cmd = 'R'
    let R_args = ['--quiet']
    let R_hl_term = 0
    let R_bracketed_paste = 1
else
    let R_args = ['--no-save', '--quiet']
endif
let R_in_buffer = 0
let R_source = expand('$DOTVIM/bundle/repos/github.com/jalvesaq/Nvim-R/' .
            \  'R/tmux_split.vim')
let R_tmux_title = 'automatic'
let R_rconsole_width = 0  " Always use horizontal split
let R_rconsole_height = 12

let R_assign = 0  " Disable _ conversion
let r_syntax_folding = 1
let Rout_more_colors = 1
let rout_follow_colorscheme = 1
let g:R_debug = 0   " Don't jump to the line being debugged

" Object browser
let R_objbr_place = 'LEFT'
let R_objbr_w = 40

function! s:RunR(mode)
    if g:rplugin.nvimcom_port == 0
        call StartR('R')
        while g:rplugin.nvimcom_port == 0
            sleep 300m
        endwhile
    endif
    if a:mode ==# 'file'
        call SendFileToR('silent')
    elseif a:mode ==# 'visual'
        call SendSelectionToR('silent', 'down')
    endif
endfunction

augroup plugin_R
    au!
    au FileType r nmap <silent> <Leader>rs :lcd %:p:h<CR><Plug>RStart
    au FileType r nmap <silent> <Leader>rq <Plug>RClose
    au FileType r nnoremap <silent> <Leader>rk :RKill<CR>
    au FileType r nmap <silent> <Leader>rw <Plug>RClearAll
    au FileType r nmap <silent> <Leader>rc <Plug>RClearConsole
    au FileType r nnoremap <silent> <Leader>rf :lcd %:p:h<CR>
                \ :call <SID>RunR('file')<CR>
    au FileType r vnoremap <silent> <Leader>rf <Esc>:lcd %:p:h<CR>
                \ :call <SID>RunR('visual')<CR>
    au FileType r nmap <silent> <Leader>ro <Plug>RUpdateObjBrowser
    au FileType r nmap <silent> <Leader>rv <Plug>RViewDF
    " Object browser mappings
    au FileType rbrowser nmap <buffer> q <Plug>RUpdateObjBrowser
    au FileType rbrowser nmap <silent><buffer> zo :call RBrOpenCloseLs(1)<CR>
    au FileType rbrowser nmap <silent><buffer> zr :call RBrOpenCloseLs(1)<CR>
    au FileType rbrowser nmap <silent><buffer> zm :call RBrOpenCloseLs(0)<CR>
    au FileType rbrowser nmap <silent><buffer> zc :call RBrOpenCloseLs(0)<CR>
augroup END

" }}}
" Pythonsense {{{

let g:is_pythonsense_suppress_location_keymaps = 1

augroup ps_pythonsense
    au!
    " Text Objects
    " FIXME: When args are split in several lines this doesn't work
    " See: https://github.com/jeetsukumaran/vim-pythonsense/issues/6
    au Filetype python map <buffer>am <Plug>(PythonsenseOuterFunctionTextObject)
    au Filetype python map <buffer>im <Plug>(PythonsenseInnerFunctionTextObject)
    " Motions
    au Filetype python map <buffer> ]c <Plug>(PythonsenseStartOfNextPythonClass)
    au Filetype python map <buffer> ]C <Plug>(PythonsenseEndOfPythonClass)
    au Filetype python map <buffer> [c <Plug>(PythonsenseStartOfPythonClass)
    au Filetype python map <buffer> [C
                \ <Plug>(PythonsenseEndOfPreviousPythonClass)
    au Filetype python map <buffer> ]f
                \ <Plug>(PythonsenseStartOfNextPythonFunction)
    au Filetype python map <buffer> ]F <Plug>(PythonsenseEndOfPythonFunction)
    au Filetype python map <buffer> [f <Plug>(PythonsenseStartOfPythonFunction)
    au Filetype python map <buffer> [F
                \ <Plug>(PythonsenseEndOfPreviousPythonFunction)
augroup END

" }}}
" Scriptease {{{

augroup ps_scriptease
    au!
    au Filetype vim nnoremap <silent> <F7> :Runtime<CR>
    au Filetype vim nnoremap <silent> <Leader>oi :PP<CR>
    au Filetype vim nnoremap <silent> <Leader>bp :Breakadd here<CR>
    au Filetype vim nnoremap <silent> <Leader>rb :Breakdel *<CR>
    au Filetype vim nnoremap <silent> <Leader>lb :breaklist<CR>
augroup END


" }}}
" Semshi {{{

let g:semshi#mark_selected_nodes = 0
let g:semshi#simplify_markup = v:false
let g:semshi#error_sign = v:false

augroup ps_semshi
    au!
    au FileType python call PythonSemshiHl()
augroup END

function PythonSemshiHl()
    " If these are defined within our colorschem they will be overriden so
    " define them here instead
    hi semshiImported        guifg=#e06c75 gui=NONE
    hi semshiParameter       guifg=#d19a66
    hi semshiParameterUnused guifg=#d19a66 gui=underline
    hi semshiBuiltin         guifg=#e5c07b
    hi semshiSelf            guifg=#e06c75
    hi semshiAttribute       guifg=#abb2bf
    hi semshiLocal           guifg=#56b6c2
    hi semshiFree            guifg=#be5046
    hi semshiGlobal          guifg=#528bff
    hi semshiUnresolved      guifg=#abb2bf gui=NONE
    " Python default (defined here to override semshi's)
    hi pythonKeyword         guifg=#98c379
endfunction

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
" t or T match) and Alt-x to replace ',' (previous match)
nnoremap <A-n> ;
nnoremap <A-b> ,
" Make Sneak behaviour consistent with previous mappings
nmap <A-n> <Plug>SneakNext
nmap <A-b> <Plug>SneakPrevious

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
let g:tagbar_show_tag_linenumbers = 1

let g:tagbar_iconchars = ['', '']

let g:tagbar_type_tex = {
    \ 'sort' : 1,
    \ 'kinds' : [
        \ 'i:includes:1:0',
        \ 'l:labels:0:0',
        \ 'f:frames'
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
nnoremap <silent> <Leader>tb :TagbarOpen jc<CR>

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

" Automatically insert header when creating new files (Note: the header snippet
" is defined in all.snippets file) or when we opening a blank file (if we only
" want this for new file use BufNew event instead)
augroup ps_ultisnips
    au!
    " au BufNewFile,BufRead *.{bib,py,snippets,tex,txt,vim,m,R,r,src,js,sh}
                " \ call s:ExpandHeader()
    au BufNewFile,BufRead *.py call s:ExpandHeader('python')
    au BufNewFile,BufRead *.{yaml,yml} call s:ExpandHeader('yaml')
augroup END
function! s:ExpandHeader(ft)
    " Don't try to expand a header from a Gdiff (when file path includes .git)
    " or if the file is not empty
    if expand('%:p') =~# "/\\.git/" || line('$') > 1 || getline(1) !=# ''
        return
    endif
    let snippet_trigger = 'hea'
    if a:ft ==# 'python'
        let snippet_trigger = 'md'
    elseif a:ft ==# 'yaml'
        let snippet_trigger = 'wp'
    endif
    if line('$') == 1 && getline(1) ==# ''
        startinsert
        call feedkeys(snippet_trigger . "\<C-s>")
    endif
endfunction

" Mappings
let g:UltiSnipsExpandTrigger = '<C-s>'
nnoremap <Leader>es :UltiSnipsEdit<CR>
" Snippet explorer with Denite (we use this mapping for sudo edit now)
" nnoremap <silent> <Leader>se :Denite output:call\ UltiSnips#ListSnippets()<CR>

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
" vim-markdown {{{

let g:vim_markdown_folding_style_pythonic = 1
let g:vim_markdown_override_foldtext = 0
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 1

augroup ps_vimmarkdown
    au!
    au Filetype markdown nmap <silent> <buffer> <Leader>tc :Toc<CR>
augroup END

" }}}
" Vimtex {{{

" TOC and labels
let g:vimtex_toc_config = {
    \ 'split_pos': 'vert topleft',
    \ 'split_width': 40,
    \ 'mode': 1,
    \ 'fold_enable': 1,
    \ 'fold_level_start': -1,
    \ 'show_help': 0,
    \ 'resize': 0,
    \ 'show_numbers': 1,
    \ 'layer_status': {'label': 0, 'include': 0, 'todo': 0, 'content': 1},
    \ 'hide_line_numbers': 0,
    \ 'tocdepth': 1,
\}
let g:vimtex_toc_show_preamble = 0
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
" Virtualenv (poetv) {{{

let g:airline#extensions#poetv#enabled = 1
let g:poetv_auto_activate = 1
let g:poetv_statusline_symbol = ' '

augroup pl_venv_python
    au!
    au Filetype python nnoremap <silent><buffer> <Leader>pva :PoetvActivate<CR>
    au Filetype python nnoremap <silent><buffer> <Leader>pvd :PoetvDeactivate<CR>
augroup END

" }}}
" Vista {{{

augroup ps_vista
    au!
    " TODO: Set floating preview hl (needs an unimplemented user defined au)
    au FileType vista setlocal relativenumber
    au VimEnter * call vista#RunForNearestMethodOrFunction()
    au FileType vista nnoremap <silent><buffer> q :call vista#sidebar#Close()<CR>
augroup END

let g:vista_sidebar_position = 'vertical topleft'
let g:vista_sidebar_width = 45
let g:vista_echo_cursor = 0  " Don't echo when moving cursor
" FIXME: Not working?
let g:vista_icon_indent = ['', '']
let g:vista_blink = [0, 0]
let g:vista_top_level_blink = [0, 0]

" }}}
" Zoom {{{

let g:zoom#statustext = ' '
nmap <Leader>zw <Plug>(zoom-toggle)

if dein#tap('zoom') == 1
    function! s:AirlineZoomIndicator()
        let g:airline_section_c = g:airline_section_c .
                    \ '%{airline#util#wrap(zoom#statusline(),0)}'
    endfunction
    augroup ps_airline_zoom_indicator
        au!
        au User AirlineAfterInit call s:AirlineZoomIndicator()
    augroup END
endif

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
    if !empty('$TMUX')
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

function! s:OpenLink(mode)
    if a:mode ==# 'visual'
        let url = getline("'<")[getpos("'<")[2] - 1:getpos("'>")[2] - 1]
    else
        let line = getline ('.')
        let url = matchstr(line, '\(http\|www\.\)[^ ]:\?[[:alnum:]%\/_#.-]*')
    endif
    let url = escape(url, '#!?&;|%')
    if url ==# ''
        let url = '%'
    endif
    let open_command = 'open '
    if s:is_win
        let open_command = 'start '
    elseif s:is_linux
        let open_command = 'xdg-open '
    endif
    execute 'silent! !' .  open_command . url
    redraw!
endfunction

nnoremap <silent> <Leader>ol :call <SID>OpenLink('normal')<CR>
vnoremap <silent> <Leader>ol :call <SID>OpenLink('visual')<CR>

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

function! s:goog(mode, lucky)
    if a:mode ==# 'visual'
        let pat = getline("'<")[getpos("'<")[2] - 1:getpos("'>")[2] - 1]
    else
        let pat = expand('<cWORD>')
    endif
    let q = '"'.substitute(pat, '["\n]', ' ', 'g').'"'
    let q = substitute(q, '[[:punct:] ]',
       \ '\=printf("%%%02X", char2nr(submatch(0)))', 'g')
    let open_command = 'open '
    if s:is_win
        let open_command = 'start '
    elseif s:is_linux
        let open_command = 'xdg-open '
    endif
    call system(printf(open_command . '"https://www.google.com/search?%sq=%s"',
                    \ a:lucky ? 'btnI&' : '', q))
endfunction

nnoremap <silent><Leader>? :call <SID>goog('cword', 0)<CR>
nnoremap <silent><Leader>! :call <SID>goog('cword', 1)<CR>
vnoremap <silent> ? :call <SID>goog('visual', 0)<CR>
vnoremap <silent> ! :call <SID>goog('visual', 1)<CR>

" }}}
" Tmux run in split window {{{

function! s:TmuxSplitCmd(cmd, cwd)
    if empty('$TMUX')
        return
    endif
    if a:cwd ==# ''
        let cwd = getcwd()
    else
        let cwd = a:cwd
    endif
   silent execute '!tmux split-window -p 30 -c '. cwd . ' ' . a:cmd | redraw!
endfunction

" }}}

" }}}
