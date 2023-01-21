local u = require('utils')

require('nvim-treesitter.configs').setup({
    ensure_installed = {
        'bash',
        'comment',
        'help', -- vimdoc help
        'java',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'vim',
    },
    highlight = {
        enable = true,
        disable = { 'latex' },
        additional_vim_regex_highlighting = { 'latex' },
    },
    matchup = { enable = true },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            scope_incremental = '<S-CR>',
            node_decremental = '<BS>',
        },
    },
})

u.keymap('n', '<Leader>cg', '<Cmd>Inspect<CR>')

-- Custom queries (see for example https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/python/folds.scm)
vim.treesitter.set_query('lua', 'folds', [[[(table_constructor)] @fold]])
vim.treesitter.set_query('markdown', 'folds', [[[(section)] @fold]])
vim.treesitter.set_query('python', 'folds', [[[(class_definition)] @fold]])
