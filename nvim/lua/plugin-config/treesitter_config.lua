local u = require('utils')

require('nvim-treesitter.configs').setup({
    highlight = {
        enable = true,
    },
    ensure_installed = {
        'bash',
        'comment',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'vim',
    },
    matchup = { enable = true },
})

u.keymap('n', '<Leader>cg', '<Cmd>TSHighlightCapturesUnderCursor<CR>')
