local u = require('utils')

require('neo-zoom').setup({
    left_ratio = 0.1,
    width_ratio = 0.8,
    top_ratio = 0.1,
    height_ratio = 0.9,
})

u.keymap('n', '<Leader>zw', ':NeoZoomToggle<CR>')
