-- Record startup once for the package dashboard
vim.g.nvim_start_time = vim.g.nvim_start_time or vim.uv.hrtime()

-- Enable experimental lua module loader
vim.loader.enable()

-- Global and environmental variables
vim.g.mapleader = ','
vim.g.matchup_matchparen_enabled = 0
vim.g.python3_host_prog = '/usr/bin/python'
vim.env.DOTVIM = vim.fs.joinpath(vim.env.HOME, '.config', 'nvim')
vim.env.CACHE = vim.fs.joinpath(vim.env.DOTVIM, 'cache', 'Arch')

-- Focus applications opened through the system handler
local default_open = vim.ui.open
vim.ui.open = function(path, opts)
    opts = vim.tbl_extend('keep', opts or {}, {
        cmd = {
            vim.fs.joinpath(vim.env.HOME, '.config', 'hypr', 'scripts', 'system_open'),
        },
    })
    return default_open(path, opts)
end

-- Use silent and nowait by default in mappings
local keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    opts.nowait = opts.nowait ~= false
    return keymap_set(mode, lhs, rhs, opts)
end

-- Colorscheme
vim.opt.termguicolors = true
vim.cmd.colorscheme('onedarkish')

-- Plugins, options and mappings
require('plugins')
require('options')
require('mappings')
