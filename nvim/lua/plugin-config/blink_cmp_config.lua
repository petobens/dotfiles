-- luacheck:ignore 631

local blink_cmp = require('blink.cmp')
local u = require('utils')

-- Helpers
local copilot_multiline_menu_direction = nil
local function is_multiline_copilot_selected()
    local item = blink_cmp.get_selected_item()
    if item and (item.source_id == 'copilot' or item.source_name == 'copilot') then
        local text = item.insertText or item.label or item.display
        if text and text:find('\n') then
            return true
        end
    end
    return false
end

-- Setup
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
            direction_priority = function()
                return copilot_multiline_menu_direction or { 's', 'n' }
            end,
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
        default = function()
            local sources = {
                'buffer',
                'copilot',
                'emoji',
                'lsp',
                'path',
                'snippets',
                'tmux',
            }
            -- Workaround for git source not supporting per_filetype configuration
            -- https://github.com/Kaiser-Yang/blink-cmp-git/issues/62#issuecomment-3062425218
            if vim.bo.filetype == 'gitcommit' then
                sources = u.is_online() and { 'buffer', 'git' } or { 'buffer' }
            end
            return sources
        end,
        per_filetype = {
            codecompanion = { 'codecompanion', 'buffer' },
            lua = { inherit_defaults = true, 'lazydev' },
            sql = { 'dbee', 'buffer' },
        },
        providers = {
            buffer = {
                min_keyword_length = 3,
                max_items = 10,
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
                score_offset = function()
                    return 100
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
vim.api.nvim_create_autocmd('User', {
    pattern = 'BlinkCmpMenuOpen',
    callback = function()
        copilot_multiline_menu_direction = nil
        local timer = vim.uv.new_timer()
        timer:start(
            0,
            80,
            vim.schedule_wrap(function()
                if
                    not copilot_multiline_menu_direction
                    and is_multiline_copilot_selected()
                then
                    copilot_multiline_menu_direction = { 'n', 's' }
                    require('blink.cmp.completion.windows.menu').update_position()
                    require('blink.cmp.completion.windows.documentation').update_position()
                end
            end)
        )

        vim.api.nvim_create_autocmd('User', {
            pattern = 'BlinkCmpMenuClose',
            once = true,
            callback = function()
                timer:stop()
                timer:close()
                copilot_multiline_menu_direction = nil
            end,
        })
    end,
})
