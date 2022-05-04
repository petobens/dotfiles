-- We need this first to ensure lsp-insaller loads before lspconfig
require('nvim-lsp-installer').setup({
    ensure_installed = { 'sumneko_lua' },
})

-- Diagnostics
vim.diagnostic.config({
    signs = false,
    virtual_text = {
        prefix = '',
        format = function(diagnostic)
            local icon
            if diagnostic.severity == vim.diagnostic.severity.ERROR then
                icon = ' '
            elseif diagnostic.severity == vim.diagnostic.severity.WARN then
                icon = ' '
            elseif diagnostic.severity == vim.diagnostic.severity.INFO then
                icon = ' '
            else
                icon = ' '
            end
            return string.format('%s %s', icon, diagnostic.message)
        end,
    },
})

-- Custom formatting (filtering clients)
local function custom_lsp_format(bufnr)
    vim.lsp.buf.format({
        filter = function(clients)
            return vim.tbl_filter(function(client)
                return client.name ~= 'sumneko_lua'
            end, clients)
        end,
        bufnr = bufnr,
    })
end

local format_augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local function on_attach(client, bufnr)
    if client.supports_method('textDocument/formatting') then
        -- Autoformat on save
        vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd('BufWritePre', {
            group = format_augroup,
            buffer = bufnr,
            callback = function()
                custom_lsp_format(bufnr)
            end,
        })
    end
end

-- Servers setup
local lspconfig = require('lspconfig')
lspconfig.sumneko_lua.setup({
    settings = require('lua-dev').setup().settings,
    on_attach = on_attach,
})

-- Mappings
local u = require('utils')
local lsp_buf = vim.lsp.buf
u.keymap('n', '<Leader>jd', lsp_buf.definition)
u.keymap('n', '<Leader>ap', lsp_buf.references)
u.keymap('n', '<Leader>rn', lsp_buf.rename)
u.keymap('n', 'K', lsp_buf.hover)
u.keymap('n', '<Leader>st', lsp_buf.signature_help)
u.keymap('n', '<Leader>fc', custom_lsp_format)
u.keymap('v', '<Leader>fc', ':<C-u>call v:lua.vim.lsp.buf.range_formatting()<CR>')
