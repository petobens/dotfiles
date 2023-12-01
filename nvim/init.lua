-- Enable experimental lua module loader
vim.loader.enable()

-- Global and enviromental variables
vim.g.mapleader = ','
vim.g.python3_host_prog = '/usr/bin/python'
vim.g.do_filetype_lua = true
vim.env.DOTVIM = vim.env.HOME .. '/.config/nvim'
vim.env.CACHE = vim.env.DOTVIM .. '/cache/Arch'

-- Use silent and nowait by default in mappings
local keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    opts.nowait = opts.nowait ~= false
    return keymap_set(mode, lhs, rhs, opts)
end

-- Source lua modules
require('plugins')
require('options')
require('mappings')
