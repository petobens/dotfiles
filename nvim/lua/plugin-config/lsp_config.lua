local u = require('utils')

-- Mason and neodev must load befor lsp-config (and mason must go first)
require('mason-lspconfig').setup()
require('neodev').setup({})
local lspconfig = require('lspconfig')

-- Use borders for floating hovers
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or u.border('FloatBorder')
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
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
    settings = {
        bashIde = {
            shellcheckPath = '', -- We use null-ls shellcheck
            enableSourceErrorDiagnostics = false,
        },
    },
})
---- Lua
lspconfig.lua_ls.setup({
    settings = {
        Lua = {
            diagnostics = { enable = false }, -- We use null-ls luacheck
            hint = { enable = true },
            telemetry = { enable = false },
            workspace = {
                ignoreDir = { '.git', 'undo' },
                preloadFileSize = 750,
                checkThirdParty = false,
            },
        },
    },
})
---- Python
lspconfig.pyright.setup({
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
                useLibraryCodeForTypes = true,
            },
        },
    },
})
---- Latex
lspconfig.texlab.setup({
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
        u.keymap('n', '<Leader>jd', function()
            local split_cmd = 'split'
            if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
                split_cmd = 'vsplit'
            end
            vim.cmd(split_cmd)
            vim.lsp.buf.definition()
        end, opts)
        u.keymap('n', '<Leader>jD', vim.lsp.buf.declaration, opts)
        u.keymap('n', '<Leader>ap', vim.lsp.buf.references, opts)
        u.keymap('n', '<Leader>rn', vim.lsp.buf.rename, opts)
        u.keymap('n', 'K', vim.lsp.buf.hover, opts)
        u.keymap('n', '<Leader>fs', vim.lsp.buf.signature_help, opts)
        u.keymap('n', '<Leader>ih', function()
            vim.lsp.inlay_hint(0, nil)
        end, opts)
        u.keymap('n', '<Leader>ca', vim.lsp.buf.code_action, opts)
    end,
})
