-- Record startup once for the package dashboard
vim.g.nvim_start_time = vim.g.nvim_start_time or vim.uv.hrtime()

-- Enable experimental lua module loader
vim.loader.enable()

-- Global and environmental variables
vim.g.mapleader = ','
vim.g.matchup_matchparen_enabled = 0
vim.g.python3_host_prog = '/usr/bin/python'
vim.g.do_filetype_lua = true
vim.env.DOTVIM = vim.fs.joinpath(vim.env.HOME, '.config', 'nvim')
vim.env.CACHE = vim.fs.joinpath(vim.env.DOTVIM, 'cache', 'Arch')

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
