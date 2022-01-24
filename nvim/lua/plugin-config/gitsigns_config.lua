local u = require('utils')

require('gitsigns').setup({
    signcolumn = false, -- disable by default
})

u.keymap('n', '<Leader>gg', '<Cmd>Gitsigns toggle_signs<CR>')
