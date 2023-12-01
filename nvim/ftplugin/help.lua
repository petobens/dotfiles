-- Options
vim.opt_local.relativenumber = true

-- Appearance
vim.cmd('wincmd J')
vim.cmd('20 wincmd _')

-- Mappings
vim.keymap.set('n', 'q', '<Cmd>bdelete<CR>', { buffer = true })
vim.keymap.set('n', '<Leader>tc', 'gO', { buffer = true, remap = true })
