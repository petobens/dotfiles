require('hlargs').setup({
    color = '#d19a66',
    excluded_argnames = {
        declarations = {
            python = { 'self', 'cls' },
            lua = { 'self' },
        },
        usages = {
            python = { 'self', 'cls' },
            lua = { 'self' },
        },
    },
})
