local tmux_plugin = require('tmux')

vim.keymap.set('n', '<C-h>', tmux_plugin.move_left)
vim.keymap.set('n', '<C-j>', tmux_plugin.move_down)
vim.keymap.set('n', '<C-k>', tmux_plugin.move_up)
vim.keymap.set('n', '<C-l>', tmux_plugin.move_right)
