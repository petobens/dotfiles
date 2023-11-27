-- luacheck:ignore 631
local u = require('utils')

-- Syntax
vim.opt.iskeyword = vim.opt.iskeyword + { ':' }
vim.opt.termguicolors = true

-- Vim behaviour
vim.opt.autowrite = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.cmdwinheight = 4
vim.opt.confirm = true
vim.opt.diffopt =
    { 'internal', 'filler', 'indent-heuristic', 'algorithm:histogram', 'linematch:60' }
vim.opt.foldcolumn = 'auto'
vim.opt.foldlevelstart = 0
vim.opt.foldopen = vim.opt.foldopen + { 'insert', 'jump' }
vim.opt.lazyredraw = false
vim.opt.modeline = false
vim.opt.shortmess = 'aoOtTIcF'
vim.opt.signcolumn = 'number'
vim.opt.timeoutlen = 550
vim.opt.title = true
vim.opt.ttimeoutlen = 0
vim.opt.updatetime = 500
vim.opt.visualbell = true
vim.g.editorconfig = false

-- Appearance
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.cursorline = true
vim.opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.pumblend = 6
vim.opt.pumheight = 15
vim.opt.relativenumber = true
vim.opt.scrolloff = 3
vim.opt.showmode = false
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitkeep = 'cursor'
vim.opt.splitright = true
vim.opt.startofline = true
vim.opt.virtualedit = { 'block', 'onemore' }
vim.opt.winblend = 6

-- Backups, sessions, undo and shada
vim.opt.backup = true
vim.opt.backupdir = vim.env.CACHE .. '/tmp/backup//'
vim.opt.directory = vim.env.CACHE .. '/tmp/swap//'
vim.opt.sessionoptions = vim.opt.sessionoptions - { 'tabpages' } + { 'winpos', 'resize' }
vim.opt.shadafile = vim.env.CACHE .. '/tmp/shada/main.shada'
vim.opt.undodir = vim.env.CACHE .. '/tmp/undo//'
vim.opt.undofile = true
vim.opt.viewdir = vim.env.CACHE .. '/tmp/view//'
vim.opt.shada = [[!,'150,<50,s10,h]]

-- Search, matching and substitution
vim.opt.gdefault = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.matchtime = 1
vim.opt.showmatch = true
vim.opt.smartcase = true
if vim.fn.executable('rg') then
    vim.opt.grepprg = 'rg --smart-case --vimgrep --no-heading'
    vim.opt.grepformat = { '%f:%l:%c:%m', '%f:%l:%m' }
end

-- Editing, tab and indent
vim.opt.autoindent = true
vim.opt.breakindent = true
vim.opt.colorcolumn = '+1'
vim.opt.expandtab = true
vim.opt.formatoptions = 'jcql'
vim.opt.linebreak = true
vim.opt.listchars = 'tab:▸\\ ,eol:¬,trail:•,extends:»,precedes:«,nbsp:␣'
vim.opt.shiftround = true
vim.opt.shiftwidth = 4
vim.opt.smartcase = true
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.textwidth = 80
vim.opt.whichwrap = vim.o.whichwrap .. ',<,>,h,l,[,]'
vim.opt.wrap = true

-- Wildmenu
vim.opt.wildignore = {
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
vim.opt.wildignorecase = true
vim.opt.wildmode = { 'longest:full', 'full' }

-- Misc
vim.opt.spellfile = vim.env.DOTVIM .. '/spell/custom-dictionary.utf-8.add'
vim.opt.spelllang = { 'en', 'es' }

-- Foldtext
function _G.my_custom_foldtext()
    return vim.fn.trim(tostring(vim.fn.getline(vim.v.foldstart)), vim.wo.foldmarker)
end
vim.opt.foldtext = 'v:lua.my_custom_foldtext()'

-- Filetype detection and settings
vim.filetype.add({
    filename = {
        ['bash_profile'] = 'sh',
        ['config.rasi'] = 'css',
        ['dunstrc'] = 'cfg',
        ['flake8'] = 'config',
        ['matplotlibrc'] = 'confini',
        ['pdbrc'] = 'python',
        ['poetry.lock'] = 'toml',
        ['pylintrc'] = 'config',
        ['ripgreprc'] = 'confini',
        ['sqlfluff'] = 'toml',
        ['vimiv.conf'] = 'dosini',
        ['zathurarc'] = 'config',
    },
    pattern = {
        ['.*onedrive/config'] = 'config',
        ['.*sql'] = 'sql',
        ['.*ssh/config'] = 'sshconfig',
    },
})
u.set_ft_option({ 'i3config', 'sh' }, 'foldmethod', 'marker')
