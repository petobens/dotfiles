_G.LspConfig = {}

-- Define higlights for markdown hover documentation
local md_docs_ns = vim.api.nvim_create_namespace('markdown_docs_highlights')
function _G.LspConfig.highlight_doc_patterns(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, md_docs_ns, 0, -1)
    local patterns = {
        ['─'] = 'RenderMarkdownDash',
        ['---'] = 'RenderMarkdownDash',
        -- Lua/vimdoc
        ['@%S+'] = '@variable.parameter',
        -- Python
        ['^%s*(Parameters)$'] = '@markup.heading.vimdoc',
        ['^%s*(Returns)$'] = '@markup.heading.vimdoc',
        ['^%s*(Examples)$'] = '@markup.heading.vimdoc',
        ['^%s*(Notes)$'] = '@markup.heading.vimdoc',
        ['^%s*(See Also)$'] = '@markup.heading.vimdoc',
    }

    for l, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        if vim.startswith(line, '``` man') then
            vim.bo[bufnr].filetype = 'man'
            return
        end

        for pattern, hl_group in pairs(patterns) do
            local from = 1
            while true do
                local s, e = line:find(pattern, from)
                if not s then
                    break
                end
                vim.api.nvim_buf_set_extmark(bufnr, md_docs_ns, l - 1, s - 1, {
                    end_col = e,
                    hl_group = hl_group,
                })
                from = e + 1
            end
        end
    end
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
require('lazydev').setup()
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
    -- Don't publish basedpyright diagnostics (we use ruff and mypy/zuban instead)
    handlers = {
        ['textDocument/diagnostic'] = function() end,
        ['textDocument/publishDiagnostics'] = function() end,
    },
    settings = {
        basedpyright = {
            disableOrganizeImports = true,
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
                typeCheckingMode = 'off',
            },
        },
    },
})
---- Latex
vim.lsp.config('texlab', {
    handlers = { ['textDocument/publishDiagnostics'] = function() end },
})

-- Enable all of the above servers
vim.lsp.enable({
    'bashls',
    'lua_ls',
    'marksman',
    'basedpyright',
    'texlab',
})

-- Autocmds
vim.api.nvim_create_autocmd('LspTokenUpdate', {
    desc = 'Highlight Python decorators with semantic token priority',
    callback = function(args)
        local token = args.data.token
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
vim.keymap.set('n', '<Leader>li', function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
        vim.notify('No LSP clients attached to current buffer', vim.log.levels.INFO)
        return
    end
    vim.notify(
        vim.inspect(vim.tbl_map(function(c)
            return {
                id = c.id,
                name = c.name,
                cmd = c.config and c.config.cmd,
                root_dir = c.root_dir,
            }
        end, clients)),
        vim.log.levels.INFO,
        { title = 'LSP clients (current buffer)' }
    )
end, { desc = 'Show active LSP clients' })
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Set up buffer-local keymaps and options after attaching LSP server',
    group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
    callback = function(e)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[e.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
        -- Disable lsp based color highlighting since we use colorizer plugin
        vim.lsp.document_color.enable(false, e.buf)

        -- Mappings
        vim.keymap.set('n', '<Leader>jd', function()
            if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
                vim.cmd.vsplit()
            else
                vim.cmd.split()
            end
            vim.lsp.buf.definition()
        end, { buffer = e.buf, desc = 'Jump to definition (split/vsplit)' })
        vim.keymap.set(
            'n',
            '<Leader>jD',
            vim.lsp.buf.declaration,
            { buffer = e.buf, desc = 'Jump to declaration' }
        )
        vim.keymap.set(
            'n',
            '<Leader>ap',
            vim.lsp.buf.references,
            { buffer = e.buf, desc = 'List references/appearances' }
        )
        vim.keymap.set(
            'n',
            '<Leader>rn',
            vim.lsp.buf.rename,
            { buffer = e.buf, desc = 'Rename symbol' }
        )
        vim.keymap.set(
            'n',
            'K',
            vim.lsp.buf.hover,
            { buffer = e.buf, desc = 'Show hover documentation' }
        )
        vim.keymap.set(
            'n',
            '<Leader>fs',
            vim.lsp.buf.signature_help,
            { buffer = e.buf, desc = 'Show (function) signature help' }
        )
        vim.keymap.set('n', '<Leader>ih', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, { buffer = e.buf, desc = 'Toggle inlay hints' })
        vim.keymap.set(
            'n',
            '<Leader>cA',
            vim.lsp.buf.code_action,
            { buffer = e.buf, desc = 'Code actions' }
        )
        vim.keymap.set('n', '<Leader>dc', function()
            vim.lsp.document_color.enable(not vim.lsp.document_color.is_enabled())
        end, { buffer = e.buf, desc = 'Toggle LSP document color highlighting' })
        vim.keymap.set('n', '<CR>', function()
            vim.lsp.buf.selection_range(vim.v.count1)
        end, { buffer = e.buf, desc = 'LSP incremental selection (grow)' })
    end,
})
