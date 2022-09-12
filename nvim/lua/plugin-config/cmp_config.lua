local cmp = require('cmp')

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

local function border(hl_name)
    return {
        { '╭', hl_name },
        { '─', hl_name },
        { '╮', hl_name },
        { '│', hl_name },
        { '╯', hl_name },
        { '─', hl_name },
        { '╰', hl_name },
        { '│', hl_name },
    }
end

cmp.setup({
    completion = {
        completeopt = 'menu,menuone,noinsert',
    },
    window = {
        completion = {
            winhighlight = 'Normal:CmpPmenu,CursorLine:PmenuSel,Search:None',
            border = border('CmpBorder'),
        },
        documentation = {
            winhighlight = 'Normal:CmpPmenu,Search:None',
            border = border('CmpBorder'),
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
            elseif vim.fn['vsnip#available'](1) == 1 then
                feedkey('<Plug>(vsnip-expand-or-jump)', '')
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.fn['vsnip#jumpable'](-1) == 1 then
                feedkey('<Plug>(vsnip-jump-prev)', '')
            end
        end, { 'i', 's' }),
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        {
            name = 'buffer',
            option = {
                get_bufnrs = function()
                    return vim.api.nvim_list_bufs()
                end,
            },
        },
        { name = 'vsnip' },
        {
            name = 'tmux',
            option = {
                all_panes = true,
            },
        },
    },
    snippet = {
        expand = function(args)
            vim.fn['vsnip#anonymous'](args.body)
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
