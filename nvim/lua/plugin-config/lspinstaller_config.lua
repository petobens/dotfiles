local lsp_installer = require('nvim-lsp-installer')

-- Autoinstall servers
lsp_installer.setup({
    ensure_installed = { 'sumneko_lua' },
})
