require('neoclip').setup({
    default_register = '+',
    keys = {
        telescope = {
            i = {
                delete = '<C-d>',
                edit = '<C-e>',
                paste = '<CR>',
                paste_behind = '<nop>',
                replay = '<C-q>',
                select = '<C-y>',
            },
            n = {
                delete = 'd',
                edit = 'e',
                paste = '<CR>',
                paste_behind = 'P',
                replay = 'q',
                select = '<C-y>',
            },
        },
    },
})
