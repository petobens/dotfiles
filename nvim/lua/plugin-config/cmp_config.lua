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
    },
    window = {
        completion = {
            winhighlight = 'Normal:NormalFloat,CursorLine:PmenuSel,Search:None',
            border = u.border('FloatBorder'),
        },
        documentation = {
            winhighlight = 'Normal:NormalFloat,Search:None',
            border = u.border('FloatBorder'),
        },
    },
    experimental = {
        ghost_text = true,
    },
    formatting = {
        format = require('lspkind').cmp_format({
            with_text = true,
        }),
    },
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-y>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert, --useful for cmdline
            select = true,
        }),
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
    },
    sources = {
        -- Note: sources are prioritized in the order that they are defined
        -- here
        { name = 'luasnip' },
        {
            name = 'nvim_lsp',
            ---@diagnostic disable-next-line: unused-local
            entry_filter = function(entry, ctx)
                local kind = require('cmp.types').lsp.CompletionItemKind[entry:get_kind()]
                return ((kind ~= 'Text') and (kind ~= 'Snippet'))
            end,
        },
        { name = 'nvim_lsp_signature_help' },
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
})
