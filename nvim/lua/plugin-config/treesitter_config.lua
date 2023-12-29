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
    },
    matchup = { enable = true },
})
-- Mappings (basically center when moving)
vim.keymap.set({ 'n', 'v' }, ']c', '<Cmd>TSTextobjectGotoNextStart @class.outer<CR>zz')
vim.keymap.set({ 'n', 'v' }, ']f', '<Cmd>TSTextobjectGotoNextStart @function.outer<CR>zz')
vim.keymap.set(
    { 'n', 'v' },
    ']p',
    '<Cmd>TSTextobjectGotoNextStart @parameter.inner<CR>zz'
)
vim.keymap.set(
    { 'n', 'v' },
    '[c',
    '<Cmd>TSTextobjectGotoPreviousStart @class.outer<CR>zz'
)
vim.keymap.set(
    { 'n', 'v' },
    '[f',
    '<Cmd>TSTextobjectGotoPreviousStart @function.outer<CR>zz'
)
vim.keymap.set(
    { 'n', 'v' },
    '[p',
    '<Cmd>TSTextobjectGotoPreviousStart @parameter.inner<CR>zz'
)
vim.keymap.set('n', '<Leader>it', function()
    vim.treesitter.inspect_tree({
        command = 'vnew | wincmd H | vertical resize 40',
        title = function()
            return 'InspectTree'
        end,
    })
    vim.keymap.set('n', 'q', u.quit_return)
end)
