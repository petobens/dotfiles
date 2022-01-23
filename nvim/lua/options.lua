local set = vim.opt

-- Syntax
set.iskeyword = set.iskeyword + { ':' }
set.termguicolors = true

-- Vim behaviour
set.autowrite = true
set.clipboard = 'unnamedplus'
set.cmdwinheight = 4
set.confirm = true
set.diffopt = { 'internal', 'filler', 'indent-heuristic', 'algorithm:histogram' }
set.foldlevelstart = 0
set.foldopen = set.foldopen + { 'insert', 'jump' }
set.lazyredraw = true
set.modeline = false
set.shortmess = 'aoOtTIc'
set.signcolumn = 'number'
set.timeoutlen = 550
set.title = true
set.ttimeoutlen = 0
set.updatetime = 500
set.visualbell = true

-- Appearance
set.completeopt = { 'menu', 'menuone', 'noselect' }
set.cursorline = true
set.mouse = 'a'
set.number = true
set.pumblend = 5
set.pumheight = 15
set.relativenumber = true
set.scrolloff = 3
set.showmode = false
set.splitbelow = true
set.splitright = true
set.startofline = true
set.virtualedit = { 'block', 'onemore' }
set.winblend = 5

-- Backups, sessions, undo and shada
set.backup = true
set.backupdir = vim.env.CACHE .. '/tmp/backup//'
set.directory = vim.env.CACHE .. '/tmp/swap//'
set.sessionoptions = set.sessionoptions - { 'tabpages' } + { 'winpos', 'resize' }
set.shadafile = vim.env.CACHE .. '/tmp/shada/main.shada'
set.undodir = vim.env.CACHE .. '/tmp/undo//'
set.undofile = true
set.viewdir = vim.env.CACHE .. '/tmp/view//'

-- Search, matching and substitution
set.gdefault = true
set.hlsearch = true
set.ignorecase = true
set.matchtime = 1
set.showmatch = true
set.smartcase = true
if vim.fn.executable('rg') then
    set.grepprg = 'rg --smart-case --vimgrep --no-heading'
    set.grepformat = { '%f:%l:%c:%m', '%f:%l:%m' }
end

-- Editing, tab and indent
set.autoindent = true
set.breakindent = true
set.colorcolumn = '+1'
set.expandtab = true
set.formatoptions = 'jcql'
set.linebreak = true
set.listchars = 'tab:▸\\ ,eol:¬,trail:•,extends:»,precedes:«,nbsp:␣'
set.shiftround = true
set.shiftwidth = 4
set.smartcase = true
set.softtabstop = 4
set.tabstop = 4
set.textwidth = 80
set.whichwrap = vim.o.whichwrap .. ',<,>,h,l,[,]'
set.wrap = true

-- Wildmenu
set.wildignore = {
    '*~',
    '*.o',
    '*.obj',
    '*.dll',
    '*.dat',
    '*.swp',
    '*.zip',
    '*.exe',
    '*.DS_Store',
    '*.out',
    '*.toc',
}
set.wildignorecase = true
set.wildmode = { 'longest:full', 'full' }

-- Misc
set.spellfile = vim.env.DOTVIM .. '/spell/custom-dictionary.utf-8.add'
set.spelllang = { 'en', 'es' }
