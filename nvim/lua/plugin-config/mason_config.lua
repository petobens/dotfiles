require('mason').setup({
    ui = { border = 'rounded' },
})

require('mason-tool-installer').setup({
    auto_update = true,
    ensure_installed = {
        -- LSP servers
        'bash-language-server',
        'lua-language-server',
        'pyright',
    },
})
