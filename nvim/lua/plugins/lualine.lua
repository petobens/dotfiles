require('lualine').setup({
    options = {theme = 'onedarkish'},
    sections = {
        lualine_a = {
            {
                'mode',
                fmt = function(str)
                        return str:sub(1,1)
                    end
            }
        },
    },
})
