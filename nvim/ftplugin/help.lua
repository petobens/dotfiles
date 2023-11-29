local u = require('utils')

-- Options
vim.opt_local.relativenumber = true

-- Appearance
vim.cmd('wincmd J')
vim.cmd('20 wincmd _')

-- Mappings
u.keymap('n', 'q', '<Cmd>bdelete<CR>', { buffer = true })
u.keymap('n', '<Leader>tc', 'gO', { buffer = true, remap = true })
