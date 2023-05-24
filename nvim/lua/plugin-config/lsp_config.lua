-- We need this first to ensure mason-lsp loads before lspconfig
require('mason-lspconfig').setup()

-- Diagnostics
vim.diagnostic.config({
    underline = false,
    signs = false,
    float = { source = true },
    virtual_text = {
        spacing = 0,
        source = 'if_many',
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
        suffix = function(diagnostic)
            return diagnostic.code and (' [%s]'):format(diagnostic.code) or ''
        end,
    },
})

-- Use borders for floating hovers
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or require('utils').border('FloatBorder')
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- Only use null-ls for formatting
local function custom_lsp_format(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            return client.name == 'null-ls'
        end,
        bufnr = bufnr,
        -- FIXME: if set to true then diagnostic list autocloses
        async = false,
    })
end

-- Autocmds
local format_augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local function on_attach(client, bufnr)
    -- We do range formatting with null-ls so disable it here
    client.server_capabilities.documentRangeFormattingProvider = false

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
            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics > 0 then
                -- Format location list to include source (but do it only once
                -- to avoid repetition)
                for _, v in pairs(diagnostics) do
                    if not string.match(v.message, v.source) then
                        v.message = string.format('%s: %s', v.source, v.message)
                    end
                end
                vim.diagnostic.setloclist({
                    title = string.format(
                        'Diagnostics: %s',
                        vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
                    ),
                })
            else
                vim.cmd('lclose')
            end
        end,
    })
end

-- neodev setup (must go before lspconfig)
require('neodev').setup({})

-- Servers setup
-- Server names available in https://github.com/williamboman/nvim-lsp-installer
local lspconfig = require('lspconfig')
---- Bash
lspconfig.bashls.setup({
    on_attach = on_attach,
})
-- Lua
lspconfig.lua_ls.setup({
    on_attach = on_attach,
    settings = {
        Lua = {
            workspace = {
                ignoreDir = { '.git', 'undo' },
                preloadFileSize = 750,
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
})
---- Python
lspconfig.pyright.setup({
    on_attach = on_attach,
    handlers = {
        -- Don't use pyright as a linter (we use pylint and mypy instead)
        ['textDocument/publishDiagnostics'] = function() end,
    },
    settings = {
        pyright = {
            disableOrganizeImports = true,
        },
    },
})
---- Latex
require('lspconfig').texlab.setup({
    handlers = { ['textDocument/publishDiagnostics'] = function() end },
})

-- Mappings
local u = require('utils')
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
u.keymap('n', '<Leader>li', '<Cmd>LspInfo<CR>')
u.keymap('v', '<Leader>fc', 'gq', { remap = true })

local lsp_buf = vim.lsp.buf
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Map only after language server attaches to the current buffer
        local opts = { buffer = ev.buf }
        u.keymap('n', '<Leader>jd', lsp_buf.definition, opts)
        u.keymap('n', '<Leader>ap', lsp_buf.references, opts)
        u.keymap('n', '<Leader>rn', lsp_buf.rename, opts)
        u.keymap('n', 'K', lsp_buf.hover, opts)
        u.keymap('n', '<Leader>fs', lsp_buf.signature_help, opts)
        u.keymap('n', '<Leader>fc', custom_lsp_format, opts)
    end,
})
