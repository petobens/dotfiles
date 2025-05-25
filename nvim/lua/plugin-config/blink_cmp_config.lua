-- luacheck:ignore 631

-- FIXME:
-- Dynamic menu position: https://github.com/Saghen/blink.cmp/issues/1801

local blink_cmp = require('blink.cmp')
local u = require('utils')

blink_cmp.setup({
    fuzzy = { implementation = 'rust' },
    appearance = {
        kind_icons = require('lspkind').presets.default,
        nerd_font_variant = 'mono',
    },
    completion = {
        menu = {
            border = u.border('FloatBorder'),
            winhighlight = 'Normal:NormalFloat,CursorLine:PmenuSel,Search:None',
            draw = {
                columns = {
                    { 'kind_icon' },
                    { 'label', 'label_description', gap = 1 },
                    { 'source_name' },
                },
                components = {
                    source_name = {
                        text = function(ctx)
                            local map = {
                                buffer = '[Buffer]',
                                codecompanion = '[CodeCompanion]',
                                copilot = '[Copilot]',
                                dbee = '[dbee]',
                                emoji = '[Emoji]',
                                git = '[Git]',
                                lsp = '[LSP]',
                                luasnip = '[Snippet]',
                                path = '[Path]',
                                tmux = '[Tmux]',
                            }
                            return map[ctx.source_id]
                                or map[ctx.source_name]
                                or (
                                    '['
                                    .. (ctx.source_name or ctx.source_id or '?')
                                    .. ']'
                                )
                        end,
                    },
                },
            },
        },
        list = {
            selection = {
                preselect = true,
                auto_insert = true,
            },
            max_items = 50,
        },
        documentation = {
            auto_show = true,
            window = {
                border = u.border('FloatBorder'),
                winhighlight = 'Normal:NormalFloat,Search:None',
            },
            draw = function(opts)
                opts.default_implementation()
                _G.LspConfig.highlight_doc_patterns(opts.window.buf)
                local win_id = opts.window:get_win()
                if win_id then
                    require('render-markdown.core.ui').update(
                        opts.window.buf,
                        win_id,
                        'BlinkDraw',
                        true
                    )
                end
            end,
        },
        ghost_text = { enabled = true },
    },
    signature = {
        enabled = true,
        window = {
            border = u.border('FloatBorder'),
            winhighlight = 'Normal:NormalFloat,Search:None',
        },
    },
    keymap = {
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-y>'] = { 'select_and_accept', 'fallback' },
        ['<C-e>'] = { 'cancel', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<A-k>'] = { 'scroll_documentation_up', 'fallback' },
        ['<A-j>'] = { 'scroll_documentation_down', 'fallback' },
        ['<A-v>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    },
    sources = {
        default = {
            'buffer',
            'copilot',
            'emoji',
            'lsp',
            'path',
            'snippets',
            'tmux',
        },
        per_filetype = {
            codecompanion = { 'codecompanion', 'buffer' },
            gitcommit = { 'git', 'buffer' },
            lua = { inherit_defaults = true, 'lazydev' },
            sql = { 'dbee', 'buffer' },
        },
        providers = {
            buffer = {
                min_keyword_length = 3,
                max_items = 10,
                opts = {
                    get_bufnrs = function()
                        return vim.tbl_filter(function(bufnr)
                            return vim.bo[bufnr].buftype == ''
                        end, vim.api.nvim_list_bufs())
                    end,
                },
            },
            codecompanion = {
                name = 'codecompanion',
                module = 'codecompanion.providers.completion.blink',
                transform_items = function(_, items)
                    for _, item in ipairs(items) do
                        item.kind_icon = ' '
                    end
                    return items
                end,
            },
            copilot = {
                name = 'copilot',
                module = 'blink-copilot',
                async = true,
            },
            dbee = {
                name = 'dbee',
                module = 'blink.compat.source',
            },
            emoji = {
                name = 'emoji',
                module = 'blink-emoji',
                score_offset = function()
                    if vim.bo.filetype == 'tex' then
                        return -1
                    end
                    return 0
                end,
            },
            git = {
                name = 'git',
                module = 'blink-cmp-git',
                enabled = function()
                    return vim.bo.filetype == 'gitcommit'
                end,
            },
            lazydev = {
                name = 'lazydev',
                module = 'lazydev.integrations.blink',
            },
            lsp = {
                name = 'lsp',
                module = 'blink.cmp.sources.lsp',
                fallbacks = {},
                transform_items = function(_, items)
                    local cmp_kind = require('blink.cmp.types').CompletionItemKind
                    return vim.tbl_filter(function(item)
                        -- Don't show lsp text and snippets
                        return item.kind ~= cmp_kind.Text
                            and item.kind ~= cmp_kind.Snippet
                    end, items)
                end,
            },
            tmux = {
                name = 'tmux',
                module = 'blink-cmp-tmux',
                opts = { all_panes = true },
            },
        },
    },
    snippets = { preset = 'luasnip' },
    cmdline = {
        enabled = true,
        completion = {
            menu = {
                auto_show = true,
            },
        },
        sources = function()
            local type = vim.fn.getcmdtype()
            if type == ':' then
                return { 'cmdline', 'path' }
            elseif type == '@' then
                return { 'path' }
            end
            return {}
        end,
        keymap = {
            ['<CR>'] = { 'select_and_accept', 'fallback' },
            ['<C-y>'] = { 'select_accept_and_enter' },
        },
    },
})

-- Extend neovim's client capabilities with the completion ones
vim.lsp.config(
    '*',
    { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) }
)

-- Ensure doc window is treated as markdown by treesitter
vim.treesitter.language.register('markdown', 'blink-cmp-documentation')

-- Autocmd settings
vim.api.nvim_create_autocmd('User', {
    pattern = 'LuasnipInsertNodeEnter',
    callback = function()
        vim.schedule(function()
            blink_cmp.show()
        end)
    end,
})
