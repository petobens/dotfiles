local u = require('utils')

-- Use borders for floating hovers
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or u.border('FloatBorder')
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- FIXME: We should be able to add_inline_highlights here
local hover = vim.lsp.buf.hover
vim.lsp.buf.hover = function()
    return hover({
        border = 'rounded',
        focusable = true,
    })
end

local signature_help = vim.lsp.buf.signature_help
vim.lsp.buf.signature_help = function()
    return signature_help({
        border = 'rounded',
        focusable = false,
    })
end

-- Servers setup
---- Bash
vim.lsp.config('bashls', {
    settings = {
        bashIde = {
            shellcheckPath = '', -- We use shellcheck
            enableSourceErrorDiagnostics = false,
        },
    },
})
----- Lua
vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            diagnostics = { enable = false }, -- We use luacheck
            hint = { enable = true },
            telemetry = { enable = false },
            workspace = {
                ignoreDir = { '.git', 'undo' },
                preloadFileSize = 750,
                checkThirdParty = 'Disable',
            },
        },
    },
})
---- Markdown
vim.lsp.config('marksman', {})
---- Python
vim.lsp.config('basedpyright', {
    handlers = {
        -- Don't publish basedpyright diagnostics (we use ruff and mypy instead)
        ['textDocument/publishDiagnostics'] = function() end,
    },
    settings = {
        basedpyright = {
            disableOrganizeImports = true,
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
vim.lsp.config('texlab', {
    handlers = { ['textDocument/publishDiagnostics'] = function() end },
})

-- Enable of the above servers
vim.lsp.enable({
    'bashls',
    'lua_ls',
    'marksman',
    'basedpyright',
    'texlab',
})

-- Autocmds
vim.api.nvim_create_autocmd('LspTokenUpdate', {
    callback = function(args)
        local token = args.data.token
        -- Ensure python decorators have priority over builtin semantic token highlights
        if vim.bo[args.buf].filetype == 'python' and token.type == 'decorator' then
            vim.lsp.semantic_tokens.highlight_token(
                token,
                args.buf,
                args.data.client_id,
                '@lsp.type.decorator.python',
                { priority = 128 }
            )
        end
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>li', '<Cmd>LspInfo<CR>')
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(e)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[e.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Map only after language server attaches to the current buffer
        local opts = { buffer = e.buf }
        vim.keymap.set('n', '<Leader>jd', function()
            local split_cmd = 'split'
            if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
                split_cmd = 'vsplit'
            end
            vim.cmd(split_cmd)
            vim.lsp.buf.definition()
        end, opts)
        vim.keymap.set('n', '<Leader>jD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', '<Leader>ap', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<Leader>fs', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<Leader>ih', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, opts)
        vim.keymap.set('n', '<Leader>cA', vim.lsp.buf.code_action, opts)
    end,
})
