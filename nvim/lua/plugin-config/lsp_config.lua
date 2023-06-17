local u = require('utils')

-- Mason and neodev must load befor lsp-config (and mason must go first)
require('mason-lspconfig').setup()
require('neodev').setup({})
local lspconfig = require('lspconfig')

-- Use borders for floating hovers
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or u.border('FloatBorder')
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

-- On-Attach
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
                -- Format location list to include source and error code (but do
                -- it only once to avoid repetition when reopening the location list)
                for _, v in pairs(diagnostics) do
                    if not string.match(v.message, v.source) then
                        v.message = string.format('%s: %s', v.source, v.message)
                        if v.code ~= '' then
                            v.message = string.format('%s [%s]', v.message, v.code)
                        end
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

-- FIXME: workaround for https://github.com/neovim/neovim/issues/23291
local ok, wf = pcall(require, 'vim.lsp._watchfiles')
if ok then
    wf._watchfunc = function()
        return function() end
    end
end

-- Servers setup (names available in https://github.com/williamboman/nvim-lsp-installer)
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
        -- Don't publish pyright diagnostics (we use pylint and mypy instead)
        ['textDocument/publishDiagnostics'] = function() end,
    },
    settings = {
        pyright = {
            disableOrganizeImports = true,
        },
        python = {
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
                typeCheckingMode = 'off',
                useLibraryCodeForTypes = false,
            },
        },
    },
})
---- Latex
require('lspconfig').texlab.setup({
    handlers = { ['textDocument/publishDiagnostics'] = function() end },
})

-- Mappings
u.keymap('n', '<Leader>li', '<Cmd>LspInfo<CR>')
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Map only after language server attaches to the current buffer
        local opts = { buffer = ev.buf }
        u.keymap('n', '<Leader>jd', vim.lsp.buf.definition, opts)
        u.keymap('n', '<Leader>jD', vim.lsp.buf.declaration, opts)
        u.keymap('n', '<Leader>ap', vim.lsp.buf.references, opts)
        u.keymap('n', '<Leader>rn', vim.lsp.buf.rename, opts)
        u.keymap('n', 'K', vim.lsp.buf.hover, opts)
        u.keymap('n', '<Leader>fs', vim.lsp.buf.signature_help, opts)
        u.keymap('n', '<Leader>fc', custom_lsp_format, opts)
    end,
})
u.keymap('v', '<Leader>fc', 'gq', { remap = true })
