local u = require('utils')

require('aerial').setup({
    layout = {
        width = 43,
        default_direction = 'left',
        placement = 'edge',
        preserve_equality = true,
    },
    close_on_select = true,
    highlight_on_hover = true,
    highlight_on_jump = 500,
    keymaps = {
        ['v'] = 'actions.jump_vsplit',
        ['s'] = 'actions.jump_split',
    },
})

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('aerial', { clear = true }),
    pattern = { 'aerial' },
    command = 'setlocal number relativenumber',
})

-- Mappings
u.keymap('n', '<Leader>tb', '<Cmd>AerialToggle<CR>')
