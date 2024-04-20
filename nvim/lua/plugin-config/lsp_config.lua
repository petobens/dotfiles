local u = require('utils')
local methods = vim.lsp.protocol.Methods

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

--- Mimic noice treesitter markdown highlights for hover, signatures and docs
-- https://github.com/MariaSolOs/dotfiles/blob/fedora/.config/nvim/lua/lsp.lua
local md_namespace = vim.api.nvim_create_namespace('noiceish_highlights')
local function add_inline_highlights(buf)
    for l, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        for pattern, hl_group in pairs({
            ['─'] = '@markup.heading.vimdoc',
            --- Lua/vimdoc
            ['@%S+'] = '@variable.parameter',
            ['{%S-}'] = '@variable.parameter',
            ['|%S-|'] = '@markup.link.vimdoc',
            -- Python
            ['^%s*(Parameters)$'] = '@markup.heading.vimdoc',
            ['^%s*(Returns)$'] = '@markup.heading.vimdoc',
            ['^%s*(Examples)$'] = '@markup.heading.vimdoc',
            ['^%s*(Notes)$'] = '@markup.heading.vimdoc',
            ['^%s*(See Also)$'] = '@markup.heading.vimdoc',
        }) do
            local from = 1
            while from do
                local to
                from, to = line:find(pattern, from)
                if from then
                    vim.api.nvim_buf_set_extmark(buf, md_namespace, l - 1, from - 1, {
                        end_col = to,
                        hl_group = hl_group,
                    })
                end
                from = to and to + 1 or nil
            end
        end
    end
    -- Don't conceal code block quotes and language delimiters
    -- FIXME: This done globally
    -- vim.treesitter.query.set(
    --     'markdown',
    --     'highlights',
    --     [[
    --     ((fenced_code_block_delimiter) @conceal (#set! conceal ""))
    --     ((language) @conceal (#set! conceal ""))
    --     ]]
    -- )
end

local function enhanced_float_handler(handler, focusable)
    return function(err, result, ctx, config)
        local bufnr, winnr = handler(
            err,
            result,
            ctx,
            vim.tbl_deep_extend('force', config or {}, {
                border = 'rounded',
                focusable = focusable,
            })
        )
        if not bufnr or not winnr then
            return
        end
        vim.wo[winnr].concealcursor = 'n'
        add_inline_highlights(bufnr)
    end
end
vim.lsp.handlers[methods.textDocument_hover] =
    enhanced_float_handler(vim.lsp.handlers.hover, true)
vim.lsp.handlers[methods.textDocument_signatureHelp] =
    enhanced_float_handler(vim.lsp.handlers.signature_help, false)

-- For cmp docs
vim.lsp.util.stylize_markdown = function(bufnr, contents, opts)
    contents = vim.lsp.util._normalize_markdown(contents, {
        width = vim.lsp.util._make_floating_popup_size(contents, opts),
    })
    vim.bo[bufnr].filetype = 'markdown'
    vim.treesitter.start(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    add_inline_highlights(bufnr)
    return contents
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
            shellcheckPath = '', -- We use shellcheck
            enableSourceErrorDiagnostics = false,
        },
    },
})
---- Lua
lspconfig.lua_ls.setup({
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
lspconfig.marksman.setup({})
---- Python
lspconfig.basedpyright.setup({
    handlers = {
        -- Don't publish basedpyright diagnostics (we use ruff, pylint and mypy instead)
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
lspconfig.texlab.setup({
    handlers = { ['textDocument/publishDiagnostics'] = function() end },
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
            vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled())
        end, opts)
        vim.keymap.set('n', '<Leader>cA', vim.lsp.buf.code_action, opts)
    end,
})
