local u = require('utils')

require('nvim-treesitter.configs').setup({
    highlight = {
        enable = true,
    },
    ensure_installed = {
        'bash',
        'json',
        'lua',
        'markdown',
        'python',
        'vim',
    },
})

u.keymap('n', '<Leader>cg', '<Cmd>TSHighlightCapturesUnderCursor<CR>')
