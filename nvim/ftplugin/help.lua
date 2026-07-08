-- Options
vim.opt_local.relativenumber = true
-- Show help as bottom window
vim.cmd.wincmd('J')
vim.api.nvim_win_resize(0, -1, 20, { anchor = 'bottom' })
vim.api.nvim_set_option_value('winfixheight', true, { win = 0 })

-- Mappings
vim.keymap.set('n', 'q', vim.cmd.bdelete, { buf = 0, desc = 'Close help buffer' })
vim.keymap.set(
    'n',
    '<Leader>tc',
    'gO',
    { buf = 0, remap = true, desc = 'Go to help table of contents' }
)
