local lsp_installer = require('nvim-lsp-installer')

-- Auto install servers
local servers = {
    'sumneko_lua',
}
for _, name in pairs(servers) do
    local server_is_found, server = lsp_installer.get_server(name)
    if server_is_found then
        if not server:is_installed() then
            print('Installing ' .. name)
            server:install()
        end
    end
end

-- Customize servers
lsp_installer.on_server_ready(function(server)
    local opts = {}

    if server.name == 'sumneko_lua' then
        opts = vim.tbl_deep_extend('force', require('lua-dev').setup(), opts)
        opts.on_attach = function(client)
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false
        end
    end

    server:setup(opts)
end)
