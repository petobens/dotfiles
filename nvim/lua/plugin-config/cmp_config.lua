-- luacheck:ignore 631
local cmp = require('cmp')
local u = require('utils')

local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(key, true, true, true),
        mode,
        true
    )
end

cmp.setup({
    completion = {
        completeopt = 'menu,menuone,noinsert',
        get_trigger_characters = function(trigger_characters)
            table.insert(trigger_characters, ':') -- for tex
            table.insert(trigger_characters, '[') -- for markdown
            return trigger_characters
        end,
    },
    window = {
        completion = {
            winhighlight = 'Normal:NormalFloat,CursorLine:PmenuSel,Search:None',
            border = u.border('FloatBorder'),
        },
        -- Note: we show/render docs with noice
        documentation = {
            winhighlight = 'Normal:NormalFloat,Search:None',
            border = u.border('FloatBorder'),
        },
    },
    experimental = {
        ghost_text = false, -- show completion candidate on same line
    },
    formatting = {
        fields = { 'kind', 'abbr', 'menu' },
        format = function(entry, vim_item)
            vim_item.kind = require('lspkind').presets.default[vim_item.kind]
            vim_item.menu = ({
                buffer = '[Buffer]',
                copilot = '[Copilot]',
                luasnip = '[Snippet]',
                nvim_lsp = '[LSP]',
                path = '[Path]',
                tmux = '[TMUX]',
                emoji = '[Emoji]',
            })[entry.source.name]
            return vim_item
        end,
    },
    mapping = {
        ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item()),
        ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item()),
        ['<CR>'] = cmp.mapping(cmp.mapping.confirm({ select = true })),
        ['<C-y>'] = cmp.mapping(cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert, --useful for cmdline
            select = true,
        })),
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<A-k>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<A-j>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<A-v>'] = cmp.mapping(function()
            if cmp.visible_docs() then
                cmp.close_docs()
            else
                cmp.open_docs()
            end
        end, { 'i', 's' }),
    },
    sources = {
        -- Note: sources are prioritized in the order that they are defined here
        { name = 'luasnip' },
        {
            name = 'nvim_lsp',
            entry_filter = function(entry, ctx)
                local kind = require('cmp.types').lsp.CompletionItemKind[entry:get_kind()]
                if ctx.filetype == 'markdown' then
                    -- Marksman uses Text kind for completion as per
                    -- https://github.com/artempyanykh/marksman/issues/204#issuecomment-1751657224
                    return (kind ~= 'Snippet')
                else
                    return ((kind ~= 'Text') and (kind ~= 'Snippet'))
                end
            end,
        },
        {
            name = 'buffer',
            option = {
                get_bufnrs = function()
                    return vim.api.nvim_list_bufs()
                end,
            },
        },
        { name = 'path' },
        {
            name = 'tmux',
            option = {
                all_panes = true,
            },
        },
        { name = 'git' },
        { name = 'emoji' },
    },
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
})

-- Complete commands and paths in command prompt
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline({
        -- Select candidate but don't execute with enter (do that with C-y)
        ['<CR>'] = {
            c = cmp.mapping.confirm({
                select = true,
            }),
        },
        ['<C-y>'] = cmp.mapping(function()
            cmp.confirm({ select = true })
            feedkey('<CR>', '')
        end, { 'c' }),
    }),
    sources = cmp.config.sources({
        { name = 'cmdline' },
    }, {
        { name = 'path' },
    }),
    formatting = {
        fields = { 'abbr' },
    },
})
-- Also use cmp-cmdline to complete vim.ui.input paths
cmp.setup.cmdline('@', {
    mapping = cmp.mapping.preset.cmdline({
        -- Select candidate but don't execute with enter (do that with C-y)
        ['<CR>'] = {
            c = cmp.mapping.confirm({
                select = true,
            }),
        },
        ['<C-y>'] = cmp.mapping(function()
            cmp.confirm({ select = true })
            feedkey('<CR>', '')
        end, { 'c' }),
    }),
    sources = cmp.config.sources({
        { name = 'path' },
    }),
    formatting = {
        fields = { 'abbr' },
    },
})

-- Setup git source
require('cmp_git').setup()
