local actions = require('diffview.actions')

-- Setup
require('diffview').setup({
    show_help_hints = false,
    file_panel = {
        win_config = {
            position = 'left',
            width = 43,
            win_opts = {
                number = true,
                relativenumber = true,
                winfixbuf = true,
                signcolumn = 'no',
            },
        },
    },
    hooks = {
        view_opened = function()
            actions.toggle_files()
        end,
        diff_buf_read = function()
            vim.defer_fn(function()
                vim.cmd('normal ]h')
            end, 1)
        end,
    },
    keymaps = {
        view = {
            { 'n', '<Leader>fp', actions.toggle_files },
            { 'n', '<Leader>ff', actions.focus_files },
            { 'n', ']c', ']h', { remap = true } },
            { 'n', '[c', '[h', { remap = true } },
            { 'n', 'Q', '<Cmd>DiffviewClose<CR>' },
        },
        file_panel = {
            { 'n', 'j', 'j' },
            { 'n', 'k', 'k' },
            { 'n', 'l', 'l' },
            { 'n', 'h', 'h' },
            { 'n', 'q', actions.toggle_files },
            { 'n', 'Q', '<Cmd>DiffviewClose<CR>' },
            { 'n', 'zm', actions.close_all_folds },
            { 'n', 'zr', actions.open_all_folds },
            { 'n', '?', 'g?', { remap = true } },
        },
    },
})

-- Mappings
vim.keymap.set('n', '<Leader>vd', '<Cmd>DiffviewOpen<CR>')
vim.keymap.set('n', '<Leader>ve', '<Cmd>DiffviewClose<CR>')
