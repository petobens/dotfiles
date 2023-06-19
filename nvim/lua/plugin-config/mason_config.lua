local u = require('utils')

require('mason').setup({
    ui = { border = 'rounded' },
})

require('mason-tool-installer').setup({
    auto_update = true,
    ensure_installed = {
        -- luacheck:ignore 631
        -- See names in https://github.com/williamboman/mason-lspconfig.nvim/blob/main/lua/mason-lspconfig/mappings/server.lua
        'bash-language-server',
        'lua-language-server',
        'pyright',
        'texlab',
    },
})

u.keymap('n', '<Leader>ms', '<Cmd>Mason<CR>')
