local leap = require('leap')

require('flit').setup({}) -- enhanced f,F,t and T motions (as in sneak)

-- Mappings
vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap-forward)')
vim.keymap.set({ 'n', 'x', 'o' }, 'S', '<Plug>(leap-backward)')
leap.opts.keys.next_target = { '<A-n>' }
leap.opts.keys.prev_target = { '<A-p>' }
