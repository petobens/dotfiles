local onedarkpro = require('onedarkpro')

onedarkpro.setup({
    theme = 'onedark',
    colors = {
        bg = '#24272e',
        fg = '#abb2bf',
        -- Base colors
		black = '#24272e',
		blue = '#528bff',
		cyan = '#56b6c2',
		gray = '#5c6370',
		green = '#98c379',
		orange = '#d19a66',
		purple = '#c678dd',
		red = '#e06c75',
		white = '#abb2bf',
		yellow = '#e5c07b',

        -- Custom Colors
        comment_grey = '#5c6370',
        light_blue = '#61afef',
        linenr_grey = '#4b5263',
        pmenu = '#333841',
        visual_grey = '#3e4452',

        -- Some HL groups
        color_column = '#282c34',
        cursorline = '#282c34', -- cursor_grey
        highlight = '#d19a66', -- dark yellow
        none = 'NONE',
    },
    hlgroups = {
        -- General UI
        CursorLineNr = {fg = '${fg}', bg = '${black}', style = 'none'},
        FoldColumn = {fg = '${comment_grey}', bg = '${black}'},
        Folded = {fg = '${comment_grey}', bg = '${black}'},
        IncSearch = {fg = '${orange}', bg = '${black}'},
        LineNr = {fg = '${linenr_grey}'},
        PMenu = {fg = '${fg}', bg = '${pmenu}'},
        PMenuSbar = {fg = '${fg}', bg = '${pmenu}'},
        PMenuSel = {fg = '${black}', bg = '${light_blue}'},
        PMenuThumb = {bg = '${white}'},
        Search = {fg = '${black}', bg = '${yellow}'},
        VertSplit = {fg = '${cursorline}'},
        Visual = {bg = '${visual_grey}'},
        VisualNOS = {link = 'Visual'},
        WildMenu = {link = 'PMenuSel'},

        -- Syntax
        Comment = {fg = '${comment_grey}', style = 'italic'},
    },
    options = {
        italic = false,
        cursorline = true,
        underline = false,
    },
})

onedarkpro.load()
