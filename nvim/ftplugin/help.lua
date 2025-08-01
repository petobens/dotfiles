-- Options
vim.opt_local.relativenumber = true
-- Show help as bottom window
vim.cmd.wincmd('J')
vim.api.nvim_win_set_height(0, 20)
vim.api.nvim_win_set_option(0, 'winfixheight', true)

-- Mappings
vim.keymap.set('n', 'q', '<Cmd>bdelete<CR>', { buffer = true })
vim.keymap.set('n', '<Leader>tc', 'gO', { buffer = true, remap = true })
