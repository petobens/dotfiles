require('colorizer').setup({
    filetypes = {}, -- disabled by default (toggle it with mapping to enable it)
    user_default_options = {
        RGB = true,
        RRGGBB = true,
        names = false,
    },
})

vim.keymap.set(
    'n',
    '<Leader>cz',
    vim.cmd.ColorizerToggle,
    { desc = 'Toggle colorizer for current buffer' }
)
