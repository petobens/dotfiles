local tmux_plugin = require('tmux')

vim.keymap.set('n', '<C-h>', tmux_plugin.move_left, { desc = 'Tmux: Move left' })
vim.keymap.set('n', '<C-j>', tmux_plugin.move_down, { desc = 'Tmux: Move down' })
vim.keymap.set('n', '<C-k>', tmux_plugin.move_up, { desc = 'Tmux: Move up' })
vim.keymap.set('n', '<C-l>', tmux_plugin.move_right, { desc = 'Tmux: Move right' })
