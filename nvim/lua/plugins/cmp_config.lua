local cmp = require('cmp')

cmp.setup({
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<C-y>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
        }),
    },

    sources = {
        {name = 'nvim_lsp'},
        {name = 'path'},
        {name = 'buffer', keyword_length = 3},
    },

    experimental = {
        ghost_text = true,
    },
})

