local tmux_plugin = require('tmux')
local u = require('utils')

u.keymap('n', '<C-h>', tmux_plugin.move_left)
u.keymap('n', '<C-j>', tmux_plugin.move_down)
u.keymap('n', '<C-k>', tmux_plugin.move_up)
u.keymap('n', '<C-l>', tmux_plugin.move_right)
