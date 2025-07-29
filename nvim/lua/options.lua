local u = require('utils')

-- Helpers
function _G.my_custom_foldtext()
    return vim.trim(tostring(vim.fn.getline(vim.v.foldstart)), vim.wo.foldmarker)
end

-- Syntax
vim.opt.iskeyword = vim.opt.iskeyword + { ':' }
vim.opt.termguicolors = true

-- Vim behaviour
require('vim._extui').enable({}) -- experimental new TUI message grid
vim.opt.autowrite = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.cmdwinheight = 4
vim.opt.confirm = true
vim.opt.diffopt = {
    'internal',
    'filler',
    'closeoff',
    'indent-heuristic',
    'algorithm:histogram',
    'linematch:60',
}
vim.opt.foldcolumn = 'auto'
vim.opt.foldlevelstart = 0
vim.opt.foldopen = vim.opt.foldopen + { 'insert', 'jump' }
vim.opt.foldtext = 'v:lua.my_custom_foldtext()'
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
---- Create non-existing parent directory on save
vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('create_dir_before_write', { clear = true }),
    callback = function()
        u.mk_non_dir()
    end,
})
---- Save when losing focus
vim.api.nvim_create_autocmd('FocusLost', {
    group = vim.api.nvim_create_augroup('focus_lost', { clear = true }),
    command = 'silent! wall',
})
---- Disable readonly warning
vim.api.nvim_create_autocmd('FileChangedRO', {
    group = vim.api.nvim_create_augroup('no_ro_warn', { clear = true }),
    callback = function()
        vim.opt_local.readonly = false
    end,
})

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
vim.opt.winborder = 'rounded'
---- Resize splits when the Vim window is resized
vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('vim_resized', { clear = true }),
    command = 'wincmd =',
})
---- Only show cursorline in the current window and save last visited window id
local cline_acg = vim.api.nvim_create_augroup('cline', { clear = true })
vim.api.nvim_create_autocmd('WinLeave', {
    group = cline_acg,
    callback = function()
        vim.opt_local.cursorline = false
        _G.LastWinId = vim.api.nvim_get_current_win()
    end,
})
vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'BufWinEnter' }, {
    group = cline_acg,
    callback = function()
        vim.opt_local.cursorline = true
    end,
})

-- Backups, sessions, undo and shada
vim.opt.backup = true
vim.opt.backupdir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'backup') .. '//'
vim.opt.directory = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'swap') .. '//'
vim.opt.sessionoptions = vim.opt.sessionoptions - { 'tabpages' } + { 'winpos', 'resize' }
vim.opt.shadafile = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'shada', 'main.shada')
vim.opt.undodir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'undo') .. '//'
vim.opt.undofile = true
vim.opt.viewdir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'view') .. '//'
vim.opt.shada = [[!,'150,<50,s10,h]]
---- Save and load viewoptions and previous session
local session_acg = vim.api.nvim_create_augroup('session', { clear = true })
vim.api.nvim_create_autocmd('VimLeavePre', {
    group = session_acg,
    callback = function()
        -- Only save session if there is an attached UI (i.e., not in headless mode such
        -- as a neotest worker)
        if #vim.api.nvim_list_uis() > 0 then
            vim.cmd.mksession({ args = { u.vim_session_file() }, bang = true })
        end
    end,
})
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = session_acg,
    pattern = { '*.*', 'bashrc', 'bash_profile', 'config' },
    command = 'if &previewwindow != 1 | mkview | endif',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = session_acg,
    pattern = { '*.*', 'bashrc', 'bash_profile', 'config' },
    command = 'if &previewwindow != 1 | silent! loadview | endif',
})

-- Search, matching, substitution and yanking
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
---- Briefly highlight yanked text
vim.api.nvim_create_autocmd({ 'TextYankPost' }, {
    group = vim.api.nvim_create_augroup('hl_yank', { clear = true }),
    callback = function()
        vim.hl.on_yank({ higroup = 'Visual', timeout = 300 })
    end,
})

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
vim.opt.spellfile =
    vim.fs.joinpath(vim.env.DOTVIM, 'spell', 'custom-dictionary.utf-8.add')
vim.opt.spelllang = { 'en', 'es' }

-- Filetype detection and autocmd settings
vim.filetype.add({
    filename = {
        ['bash_profile'] = 'sh',
        ['config.rasi'] = 'css',
        ['dunstrc'] = 'cfg',
        ['flake8'] = 'config',
        ['gitconfig'] = 'gitconfig',
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
        ['.*doc/.*'] = 'help',
        ['.*github/workflows/.*'] = 'ghaction',
        ['.*onedrive/config'] = 'config',
        ['.*sql'] = 'sql',
        ['.*ssh/config'] = 'sshconfig',
    },
})
u.set_ft_option({ 'crontab' }, 'setlocal nobackup nowritebackup')
u.set_ft_option({ 'html' }, 'setlocal shiftwidth=2 tabstop=2 softtabstop=2')
u.set_ft_option({ 'i3config', 'sh' }, 'setlocal foldmethod=marker')
u.set_ft_option({ 'text' }, 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 spell')
u.set_ft_option({ 'vim' }, 'setlocal foldmethod=marker formatoptions-=ro')

---- Python
_G.PyVenv = { active_venv = {} } -- if set inside ftplugin file it will be reset
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('auto_venv', { clear = true }),
    pattern = { '*.py' },
    callback = function()
        local fname = vim.api.nvim_buf_get_name(0)
        if not string.match(fname, '.git/') and not vim.startswith(fname, 'copilot') then
            _G.PyVenv.activate()
        end
    end,
})
