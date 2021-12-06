local onedarkpro = require('onedarkpro')

local palette = {
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
    none = 'NONE',

    -- Custom Colors
    cursor_grey = '#282c34',
    dark_red = '#be5046',
    light_blue = '#61afef',
    linenr_grey = '#4b5263',
    pmenu = '#333841',
    special_grey = '#3b4048',
    visual_grey = '#3e4452',
}
palette.comment_grey = palette.gray
palette.color_column = palette.cursor_grey
palette.cursorline = palette.cursor_grey
palette.highlight = palette.orange
palette.indentline = palette.comment_grey

onedarkpro.setup({
    theme = 'onedark',
    colors = palette,
    hlgroups = {
        -- See https://github.com/olimorris/onedarkpro.nvim/blob/main/lua/onedarkpro/theme.lua
        -- General UI
        CursorLineNr = {fg = '${fg}', bg = '${black}', style = 'none'},
        Cursor = {fg ='${black}', bg = '${blue}'}, -- actually set by terminal
        Directory = {fg = '${light_blue}'},
        NonText = {fg = '${comment_grey}', bg = '${black}'},
        EndOfBuffer = {link = 'NonText'},
        FoldColumn = {fg = '${comment_grey}', bg = '${black}'},
        Folded = {fg = '${comment_grey}', bg = '${black}'},
        IncSearch = {fg = '${orange}', bg = '${black}'},
        LineNr = {fg = '${linenr_grey}'},
        PMenu = {fg = '${fg}', bg = '${pmenu}'},
        PMenuSbar = {fg = '${fg}', bg = '${pmenu}'},
        PMenuSel = {fg = '${black}', bg = '${light_blue}'},
        PMenuThumb = {bg = '${white}'},
        Search = {fg = '${black}', bg = '${yellow}'},
        StatusLine = {fg = '${fg}', bg = '${cursorline}'},
        StatusLineNC = {bg = '${cursorline}'},
        VertSplit = {fg = '${cursorline}'},
        Visual = {bg = '${visual_grey}'},
        VisualNOS = {link = 'Visual'},
        WildMenu = {link = 'PMenuSel'},
        TermCursor = {bg = '${blue}'},
        TermCursorNC = {bg = '${gray}'},
        ErrorMsg = {fg = '${red}'},
        -- TODO: add transparency/window blend
        NormalFloat = {fg = '${fg}', bg = '${bg}'},
        SignColumn = {bg = '${bg}'},
        Substitute = {fg = '${bg}', bg = '${yellow}'},
        MatchParen = {fg = '${bg}', bg = '${light_blue}'},
        ModeMsg = {link = 'Normal'},
        MoreMsg = {link = 'ModeMsg'},
        Normal = {fg = '${fg}', bg = '${bg}'},

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
