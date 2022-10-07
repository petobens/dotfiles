local cmp = require('cmp')
local luasnip = require('luasnip')
local u = require('utils')

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0
        and vim.api
                .nvim_buf_get_lines(0, line - 1, line, true)[1]
                :sub(col, col)
                :match('%s')
            == nil
end

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
        ['<A-k>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<A-j>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-y>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
        }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    },
    sources = {
        {
            name = 'nvim_lsp',
            ---@diagnostic disable-next-line: unused-local
            entry_filter = function(entry, ctx)
                local kind = require('cmp.types').lsp.CompletionItemKind[entry:get_kind()]
                return ((kind ~= 'Text') and (kind ~= 'Snippet'))
            end,
        },
        { name = 'path' },
        {
            name = 'buffer',
            option = {
                get_bufnrs = function()
                    return vim.api.nvim_list_bufs()
                end,
            },
        },
        { name = 'luasnip' },
        {
            name = 'tmux',
            option = {
                all_panes = true,
            },
        },
        { name = 'nvim_lsp_signature_help' },
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
