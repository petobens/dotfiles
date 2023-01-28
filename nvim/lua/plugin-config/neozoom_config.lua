local u = require('utils')

require('neo-zoom').setup({
    left_ratio = 0.1,
    width_ratio = 0.8,
    height_ratio = 0.91,
    border = 'rounded',
})

u.keymap('n', '<Leader>zw', ':NeoZoomToggle<CR>')
