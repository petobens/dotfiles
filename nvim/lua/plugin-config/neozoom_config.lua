local u = require('utils')

require('neo-zoom').setup({
    winopts = {
        offset = {
            width = 0.75,
            height = 0.94,
        },
        border = 'rounded',
    },
})

u.keymap('n', '<Leader>zw', ':NeoZoomToggle<CR>')
