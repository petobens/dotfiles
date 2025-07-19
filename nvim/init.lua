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
    opts = opts or {}
    -- Use silent and nowait by default in mappings
    opts.silent = opts.silent ~= false
    opts.nowait = opts.nowait ~= false
    return keymap_set(mode, lhs, rhs, opts)
end

vim.print = function(...)
    local args = { ... }
    local msg = table.concat(
        vim.tbl_map(function(v)
            return type(v) == 'table' and vim.inspect(v) or tostring(v)
        end, args),
        '\t'
    )
    -- Always show printed output in the pager
    vim.schedule(function()
        vim.api.nvim_echo({ { msg } }, false, { kind = 'list_cmd' })
    end)
    return ...
end

-- Source lua modules
require('plugins')
require('options')
require('mappings')
