local lsp_installer = require('nvim-lsp-installer')

lsp_installer.on_server_ready(function(server)
    local opts = {}
    server:setup(opts)
end)
