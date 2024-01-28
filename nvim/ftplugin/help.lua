-- Options
vim.opt_local.relativenumber = true
vim.cmd('wincmd J | resize 20 | set winfixheight') -- show help as bottom window

-- Mappings
vim.keymap.set('n', 'q', '<Cmd>bdelete<CR>', { buffer = true })
vim.keymap.set('n', '<Leader>tc', 'gO', { buffer = true, remap = true })
