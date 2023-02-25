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
        'regex',
        'vim',
    },
    highlight = {
        enable = true,
        disable = { 'latex' },
        additional_vim_regex_highlighting = { 'latex' },
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            scope_incremental = '<S-CR>',
            node_decremental = '<BS>',
        },
    },
    textobjects = {
        select = {
            enable = true,
            lookahead = true,
            keymaps = {
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ai'] = '@conditional.outer',
                ['ii'] = '@conditional.inner',
                ['aa'] = '@parameter.outer',
                ['ia'] = '@parameter.inner',
                ['av'] = '@variable.outer',
                ['iv'] = '@variable.inner',
            },
        },
        move = {
            enable = true,
            set_jumps = true, -- set jumps in the jumplist
            goto_next_start = {
                [']c'] = '@class.outer',
                [']f'] = '@function.outer',
                [']p'] = '@parameter.inner',
            },
            goto_next_end = {
                [']C'] = '@class.outer',
                [']F'] = '@function.outer',
            },
            goto_previous_start = {
                ['[c'] = '@class.outer',
                ['[f'] = '@function.outer',
                ['[p'] = '@parameter.inner',
            },
            goto_previous_end = {
                ['[C'] = '@class.outer',
                ['[F'] = '@function.outer',
            },
        },
    },
    matchup = { enable = true },
})

u.keymap('n', '<Leader>cg', '<Cmd>Inspect<CR>')

-- Custom queries (see for example https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/python/folds.scm)
vim.treesitter.set_query('lua', 'folds', [[[(table_constructor)] @fold]])
vim.treesitter.set_query('markdown', 'folds', [[[(section)] @fold]])
vim.treesitter.set_query('python', 'folds', [[[(class_definition)] @fold]])
