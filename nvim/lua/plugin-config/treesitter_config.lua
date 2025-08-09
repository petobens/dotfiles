local ts_select = require('nvim-treesitter.textobjects.select')
local u = require('utils')

-- Setup
require('nvim-treesitter.configs').setup({
    ensure_installed = {
        'bash',
        'comment',
        'diff',
        'dockerfile',
        'html',
        'java',
        'json',
        'latex',
        'lua',
        'make',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'regex',
        'rst',
        'sql',
        'toml',
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
        swap = {
            enable = true,
            swap_next = {
                ['<A-l>'] = '@parameter.inner',
            },
            swap_previous = {
                ['<A-h>'] = '@parameter.inner',
            },
        },
    },
    matchup = { enable = true },
})

-- Ft/Langugage register
vim.treesitter.language.register('yaml', 'ghaction')

-- Mappings
vim.keymap.set({ 'n', 'v' }, ']c', function()
    vim.cmd.TSTextobjectGotoNextStart('@class.outer')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Next class' })

vim.keymap.set({ 'n', 'v' }, '[c', function()
    vim.cmd.TSTextobjectGotoPreviousStart('@class.outer')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Prev class' })

vim.keymap.set({ 'n', 'v' }, ']f', function()
    vim.cmd.TSTextobjectGotoNextStart('@function.outer')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Next function' })

vim.keymap.set({ 'n', 'v' }, '[f', function()
    vim.cmd.TSTextobjectGotoPreviousStart('@function.outer')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Prev function' })

vim.keymap.set({ 'n', 'v' }, ']p', function()
    vim.cmd.TSTextobjectGotoNextStart('@parameter.inner')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Next parameter' })

vim.keymap.set({ 'n', 'v' }, '[p', function()
    vim.cmd.TSTextobjectGotoPreviousStart('@parameter.inner')
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end, { desc = 'Prev parameter' })

vim.keymap.set({ 'o', 'x', 'n' }, '<leader>if', function()
    ts_select.select_textobject('@function.inner')
end, { desc = 'Select inner function (works in injections)' })

vim.keymap.set({ 'o', 'x', 'n' }, '<leader>af', function()
    ts_select.select_textobject('@function.outer')
end, { desc = 'Select outer function (works in injections)' })

vim.keymap.set('n', '<Leader>it', function()
    vim.treesitter.inspect_tree({
        command = 'vnew | wincmd H | vertical resize 60',
        title = function()
            return 'InspectTree'
        end,
    })
    vim.keymap.set('n', 'q', u.quit_return)
end)
