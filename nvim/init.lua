-- Enable experimental lua module loader
vim.loader.enable()

-- Global and enviromental variables
vim.g.mapleader = ','
vim.g.python3_host_prog = '/usr/bin/python'
vim.g.do_filetype_lua = true
vim.env.DOTVIM = vim.env.HOME .. '/.config/nvim'
vim.env.CACHE = vim.env.DOTVIM .. '/cache/Arch'

-- Override some functions
local keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
    -- Use silent and nowait by default in mappings
    opts = opts or {}
    opts.silent = opts.silent ~= false
    opts.nowait = opts.nowait ~= false
    return keymap_set(mode, lhs, rhs, opts)
end

local orig_print = vim.print
vim.print = function(...)
    -- Always open msg area after print
    local ret = { orig_print(...) }
    vim.schedule(function()
        -- FIXME: Only run this if spill
        vim.cmd('normal! g<')
        vim.cmd('stopinsert')
    end)
    return unpack(ret)
end

-- Source lua modules
require('plugins')
require('options')
require('mappings')
