local u = require('utils')

require('nvim-treesitter.configs').setup({
    highlight = {
        enable = true,
        disable = { 'latex' },
        additional_vim_regex_highlighting = { 'latex' },
    },
    ensure_installed = {
        'bash',
        'comment',
        'java',
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

-- Custom queries
vim.treesitter.set_query('markdown', 'folds', [[[(section)] @fold]])
