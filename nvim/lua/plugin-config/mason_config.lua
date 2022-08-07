require('mason').setup({
    ui = { border = 'rounded' },
})

require('mason-tool-installer').setup({
    auto_update = true,
    ensure_installed = {
        -- LSP servers
        'lua-language-server',
    },
})
