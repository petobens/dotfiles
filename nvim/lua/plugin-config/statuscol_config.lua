local builtin = require('statuscol.builtin')

require('statuscol').setup({
    relculright = true,
    segments = {
        {
            sign = {
                name = { 'Diagnostic' },
                maxwidth = 1,
                auto = true,
            },
        },
        {
            sign = {
                namespace = { 'gitsign' },
                auto = true,
            },
        },
        {
            text = {
                function()
                    return '%='
                end,
                builtin.foldfunc,
            },
            auto = true,
        },
        {
            text = {
                builtin.lnumfunc,
                ' ',
            },
        },
    },
})
