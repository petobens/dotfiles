-- We need this first to ensure mason-lsp loads before lspconfig
require('mason-lspconfig').setup()

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

-- Only use null-ls for formatting
local function custom_lsp_format(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            return client.name == 'null-ls'
        end,
        bufnr = bufnr,
    })
end

-- Autocmds
local format_augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local function on_attach(client, bufnr)
    if client.name == 'sumneko_lua' then
        -- For buffer range_formatting
        -- TODO: Improve after https://github.com/neovim/neovim/issues/18371
        client.server_capabilities.documentRangeFormattingProvider = false
    end

    vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })

    -- Autoformat on save with null-ls
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = format_augroup,
        buffer = bufnr,
        callback = function()
            custom_lsp_format(bufnr)
        end,
    })
    -- Open diagnostics on save (if there are diagnostics)
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = format_augroup,
        buffer = bufnr,
        callback = function()
            if #vim.diagnostic.get(0) > 0 then
                vim.diagnostic.setloclist({
                    title = string.format(
                        'Diagnostics: %s',
                        vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
                    ),
                })
            end
        end,
    })
end

-- Lua-dev setup (must go before lspconfig)
require('lua-dev').setup({})

-- Servers setup
-- Server names available in https://github.com/williamboman/nvim-lsp-installer
local lspconfig = require('lspconfig')
lspconfig.sumneko_lua.setup({
    on_attach = on_attach,
})
lspconfig.bashls.setup({
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
u.keymap('v', '<Leader>fc', 'gq', { remap = true })
u.keymap('n', '<Leader>fd', vim.diagnostic.open_float)
u.keymap('n', '<Leader>ld', function()
    local win_id = vim.fn.win_getid()
    vim.diagnostic.setloclist({
        title = string.format(
            'Diagnostics: %s',
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
        ),
    })
    vim.fn.win_gotoid(win_id)
end)
