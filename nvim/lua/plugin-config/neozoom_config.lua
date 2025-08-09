require('neo-zoom').setup({
    winopts = {
        offset = {
            width = 0.75,
            height = 0.94,
        },
        border = 'rounded',
    },
})

vim.keymap.set('n', '<Leader>zw', vim.cmd.NeoZoomToggle, { desc = 'Toggle NeoZoom' })
