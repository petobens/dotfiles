local u = require('utils')

require('high-str').setup({
    highlight_colors = {
		color_1 = {"#0c0d0e", "smart"},
    }
})

-- TODO: make this work in normal mode
u.keymap('v', '<Leader>hl1', ':<C-U>HSHighlight 1<CR>')
u.keymap('n', '<Leader>hlr', ':HSRmHighlight rm_all<CR>')
