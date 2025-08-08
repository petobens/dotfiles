local u = require('utils')

-- Helpers
function _G.my_custom_foldtext()
    local bufnr = vim.api.nvim_get_current_buf()
    local foldstart = vim.v.foldstart
    local line = vim.api.nvim_buf_get_lines(bufnr, foldstart - 1, foldstart, false)[1]
        or ''
    local marker = vim.wo.foldmarker or ''
    return vim.trim(line, marker)
end

-- Core options
vim.g.editorconfig = false
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
vim.opt.foldopen:append({ 'insert', 'jump' })
vim.opt.foldtext = 'v:lua.my_custom_foldtext()'
vim.opt.iskeyword:append(':')
vim.opt.lazyredraw = false
vim.opt.modeline = false
vim.opt.shortmess = 'aoOtTIcF'
vim.opt.signcolumn = 'number'
vim.opt.termguicolors = true
vim.opt.timeoutlen = 550
vim.opt.title = true
vim.opt.ttimeoutlen = 0
vim.opt.updatetime = 500
vim.opt.visualbell = true

require('vim._extui').enable({}) -- experimental new TUI message grid

vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('create_dir_before_write', { clear = true }),
    desc = 'Create parent directory before writing file',
    callback = function()
        u.mk_non_dir()
    end,
})
vim.api.nvim_create_autocmd('FocusLost', {
    group = vim.api.nvim_create_augroup('focus_lost', { clear = true }),
    desc = 'Save all files when Neovim loses focus',
    callback = function()
        vim.cmd.wall({ mods = { silent = true } })
    end,
})
vim.api.nvim_create_autocmd('FileChangedRO', {
    group = vim.api.nvim_create_augroup('no_ro_warn', { clear = true }),
    desc = 'Disable readonly warning after file changed outside of Neovim',
    callback = function()
        vim.opt_local.readonly = false
    end,
})

-- UI
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.cursorline = true
vim.opt.fillchars = {
    eob = ' ',
    fold = ' ',
    foldopen = '',
    foldsep = ' ',
    foldclose = '',
}
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

vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('vim_resized', { clear = true }),
    desc = 'Equalize all window splits when the Neovim window is resized',
    callback = function()
        vim.cmd.wincmd('=')
    end,
})
local cline_acg = vim.api.nvim_create_augroup('cline', { clear = true })
vim.api.nvim_create_autocmd('WinLeave', {
    group = cline_acg,
    desc = 'Hide cursorline and save last window id on leaving window',
    callback = function()
        vim.opt_local.cursorline = false
        _G.LastWinId = vim.api.nvim_get_current_win()
    end,
})
vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'BufWinEnter' }, {
    group = cline_acg,
    desc = 'Show cursorline in the active window',
    callback = function()
        vim.opt_local.cursorline = true
    end,
})

-- Backups, sessions, undo, shada
vim.opt.backup = true
vim.opt.backupdir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'backup') .. '//'
vim.opt.directory = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'swap') .. '//'
vim.opt.sessionoptions = vim.opt.sessionoptions - { 'tabpages' } + { 'winpos', 'resize' }
vim.opt.shada = [[!,'150,<50,s10,h]]
vim.opt.shadafile = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'shada', 'main.shada')
vim.opt.undodir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'undo') .. '//'
vim.opt.undofile = true
vim.opt.viewdir = vim.fs.joinpath(vim.env.CACHE, 'tmp', 'view') .. '//'

local session_acg = vim.api.nvim_create_augroup('session', { clear = true })
vim.api.nvim_create_autocmd('VimLeavePre', {
    group = session_acg,
    desc = 'Save session on exit if UI is attached',
    callback = function()
        if #vim.api.nvim_list_uis() > 0 then
            vim.cmd.mksession({ args = { u.vim_session_file() }, bang = true })
        end
    end,
})
local session_patterns = { '*.*', 'bashrc', 'bash_profile', 'config' }
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = session_acg,
    pattern = session_patterns,
    desc = 'Save view when leaving buffer window',
    callback = function(args)
        if not vim.wo.previewwindow then
            vim.api.nvim_buf_call(args.buf, function()
                vim.cmd.mkview()
            end)
        end
    end,
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = session_acg,
    pattern = session_patterns,
    desc = 'Restore view when entering buffer window',
    callback = function(args)
        if not vim.wo.previewwindow then
            vim.api.nvim_buf_call(args.buf, function()
                pcall(vim.cmd.loadview)
            end)
        end
    end,
})

-- Search, matching, substitution, yanking
vim.opt.gdefault = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.matchtime = 1
vim.opt.showmatch = true
vim.opt.smartcase = true
if vim.fn.executable('rg') == 1 then
    vim.opt.grepprg = 'rg --smart-case --vimgrep --no-heading'
    vim.opt.grepformat = { '%f:%l:%c:%m', '%f:%l:%m' }
end
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('hl_yank', { clear = true }),
    desc = 'Briefly highlight yanked text',
    callback = function()
        vim.hl.on_yank({ higroup = 'Visual', timeout = 300 })
    end,
})

-- Editing, tabs, indent
vim.opt.autoindent = true
vim.opt.breakindent = true
vim.opt.colorcolumn = { '+1' }
vim.opt.expandtab = true
vim.opt.formatoptions = 'jcql'
vim.opt.linebreak = true
vim.opt.listchars = {
    tab = '▸\\ ',
    eol = '¬',
    trail = '•',
    extends = '»',
    precedes = '«',
    nbsp = '␣',
}
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

-- Spelling
vim.opt.spellfile =
    vim.fs.joinpath(vim.env.DOTVIM, 'spell', 'custom-dictionary.utf-8.add')
vim.opt.spelllang = { 'en', 'es' }

-- Filetype detection
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

-- Filetype-specific options
local function set_ft_option(ft, vim_cmd)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        group = vim.api.nvim_create_augroup('FtOptions', {}),
        desc = ('Set filetype-specific options: %s'):format(vim.inspect(ft)),
        command = vim_cmd,
    })
end
set_ft_option({ 'crontab' }, 'setlocal nobackup nowritebackup')
set_ft_option({ 'html' }, 'setlocal shiftwidth=2 tabstop=2 softtabstop=2')
set_ft_option({ 'i3config', 'sh' }, 'setlocal foldmethod=marker')
set_ft_option({ 'text' }, 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 spell')
set_ft_option({ 'vim' }, 'setlocal foldmethod=marker formatoptions-=ro')

-- Python: auto-activate virtualenvs
_G.PyVenv = { active_venv = {} } -- if set inside ftplugin file it will be reset
vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('auto_venv', { clear = true }),
    pattern = { '*.py' },
    desc = 'Auto-activate Python virtualenv on entering Python buffer',
    callback = function()
        local fname = vim.api.nvim_buf_get_name(0)
        if not string.match(fname, '.git/') and not vim.startswith(fname, 'copilot') then
            _G.PyVenv.activate()
        end
    end,
})
