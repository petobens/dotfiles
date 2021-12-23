local lsp_installer = require('nvim-lsp-installer')

lsp_installer.on_server_ready(function(server)
    local opts = {}

    if server.name == 'sumneko_lua' then
        opts.settings = require('lua-dev').setup().settings
    end

    server:setup(opts)
end)
