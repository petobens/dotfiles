-- Enable experimental lua module loader
vim.loader.enable()

-- Global and enviromental variables
vim.g.mapleader = ','
vim.g.python3_host_prog = '/usr/bin/python'
vim.g.do_filetype_lua = true
vim.env.DOTVIM = vim.env.HOME .. '/.config/nvim'
vim.env.CACHE = vim.env.DOTVIM .. '/cache/Arch'

-- Add some filetypes
vim.filetype.add({
    filename = {
        ['pdbrc'] = 'python',
        ['poetry.lock'] = 'toml',
        ['sqlfluff'] = 'toml',
    },
    pattern = {
        ['.*sql'] = 'sql',
    },
})

-- Source lua modules
require('plugins')
require('options')
require('autocmds')
require('ft_autocmds')
require('mappings')
