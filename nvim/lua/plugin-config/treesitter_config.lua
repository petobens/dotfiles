-- luacheck:ignore 631
local u = require('utils')

require('nvim-treesitter.configs').setup({
    ensure_installed = {
        'bash',
        'comment',
        'dockerfile',
        'java',
        'json',
        'latex',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'regex',
        'rst',
        'vim',
        'vimdoc',
        'yaml',
    },
    highlight = {
        enable = true,
        disable = { 'latex' },
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
            goto_next_start = {},
            goto_next_end = {
                [']C'] = '@class.outer',
                [']F'] = '@function.outer',
            },
            goto_previous_start = {},
            goto_previous_end = {
                ['[C'] = '@class.outer',
                ['[F'] = '@function.outer',
            },
        },
    },
    matchup = { enable = true },
})
-- Mappings (basically center when moving)
u.keymap({ 'n', 'v' }, ']c', '<Cmd>TSTextobjectGotoNextStart @class.outer<CR>zz')
u.keymap({ 'n', 'v' }, ']f', '<Cmd>TSTextobjectGotoNextStart @function.outer<CR>zz')
u.keymap({ 'n', 'v' }, ']p', '<Cmd>TSTextobjectGotoNextStart @parameter.inner<CR>zz')
u.keymap({ 'n', 'v' }, '[c', '<Cmd>TSTextobjectGotoPreviousStart @class.outer<CR>zz')
u.keymap({ 'n', 'v' }, '[f', '<Cmd>TSTextobjectGotoPreviousStart @function.outer<CR>zz')
u.keymap({ 'n', 'v' }, '[p', '<Cmd>TSTextobjectGotoPreviousStart @parameter.inner<CR>zz')
u.keymap('n', '<Leader>it', function()
    return vim.treesitter.inspect_tree({
        command = 'vnew | wincmd H | vertical resize 40',
    })
end)

-- Custom fold queries (see for example https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/python/folds.scm)
vim.treesitter.query.set('lua', 'folds', [[[(table_constructor)] @fold]])
vim.treesitter.query.set('markdown', 'folds', [[[(section)] @fold]])
vim.treesitter.query.set('python', 'folds', [[[(class_definition)] @fold]])
