local builtin = require('statuscol.builtin')

require('statuscol').setup({
    ft_ignore = { 'NvimTree' },
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
            click = 'v:lua.ScFa',
            auto = true,
        },
        {
            text = {
                function(args)
                    return (args.relnum == 0) and ' ' or ''
                end,
            },
        },
        {
            text = {
                builtin.lnumfunc,
                ' ',
            },
        },
    },
})
