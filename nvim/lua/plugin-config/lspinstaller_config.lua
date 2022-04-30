local lsp_installer = require('nvim-lsp-installer')
local lspconfig = require('lspconfig')

-- Autoinstall servers
lsp_installer.setup({
    ensure_installed = { 'sumneko_lua' },
})

-- Client specific
local function on_attach(client, bufnr)
    if client.name == 'sumneko_lua' then
        -- We use null-ls
        client.resolved_capabilities.document_formatting = false
        client.resolved_capabilities.document_range_formatting = false
    end
end

lspconfig.sumneko_lua.setup({
    settings = require('lua-dev').setup().settings,
    on_attach = on_attach,
})
