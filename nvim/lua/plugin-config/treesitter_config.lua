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

-- Custom queries (see for example https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/python/folds.scm)
vim.treesitter.set_query('python', 'folds', [[[(class_definition)] @fold]])
vim.treesitter.set_query('markdown', 'folds', [[[(section)] @fold]])
