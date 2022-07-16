require('nvim-surround').setup({
    delimiters = {
        pairs = {
            ['('] = { '(', ')' },
            ['['] = { '[', ']' },
            ['{'] = { '{', '}' },
            ['<'] = { '<', '>' },
        },
    },
})
