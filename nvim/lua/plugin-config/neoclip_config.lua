require('neoclip').setup({
    default_register = '+',
    keys = {
        telescope = {
            i = {
                select = '<C-y>',
                paste = '<CR>',
                paste_behind = '<nop>',
                replay = '<c-q>',
                delete = '<c-d>',
                edit = '<c-e>',
            },
            n = {
                select = '<C-y>',
                paste = '<CR>',
                paste_behind = 'P',
                replay = 'q',
                delete = 'd',
                edit = 'e',
            },
        },
    },
})
