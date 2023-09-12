-- Enable experimental lua module loader
vim.loader.enable()

-- Source lua modules
require('env')
require('plugins')
require('options')
require('autocmds')
require('ft_autocmds')
require('mappings')
