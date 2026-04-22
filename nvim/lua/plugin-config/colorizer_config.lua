require('colorizer').setup({
    -- Sentinel filetype keeps colorizer off by default (empty table errors).
    filetypes = { '_colorizer_off' },
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
