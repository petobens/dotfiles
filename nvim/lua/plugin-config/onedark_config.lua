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

local p = palette

onedarkpro.setup({
    theme = 'onedark',
    colors = palette,
    hlgroups = {
        -- See https://github.com/olimorris/onedarkpro.nvim/blob/main/lua/onedarkpro/theme.lua
        -- General UI
        CursorLineNr = {fg = p.fg, bg = p.black, style = 'none'},
        Cursor = {fg = p.black, bg = p.blue}, -- actually set by terminal
        Directory = {fg = p.light_blue},
        NonText = {fg = p.comment_grey, bg = p.black},
        EndOfBuffer = {link = 'NonText'},
        FoldColumn = {fg = p.comment_grey, bg = p.black},
        Folded = {fg = p.comment_grey, bg = p.black},
        IncSearch = {fg = p.orange, bg = p.black},
        LineNr = {fg = p.linenr_grey},
        PMenu = {fg = p.fg, bg = p.pmenu},
        PMenuSbar = {fg = p.fg, bg = p.pmenu},
        PMenuSel = {fg = p.black, bg = p.light_blue},
        PMenuThumb = {bg = p.white},
        Search = {fg = p.black, bg = p.yellow},
        StatusLine = {fg = p.fg, bg = p.cursorline},
        StatusLineNC = {bg = p.cursorline},
        VertSplit = {fg = p.cursorline},
        Visual = {bg = p.visual_grey},
        VisualNOS = {link = 'Visual'},
        WildMenu = {link = 'PMenuSel'},
        TermCursor = {bg = p.blue},
        TermCursorNC = {bg = p.gray},
        ErrorMsg = {fg = p.red},
        -- TODO: add transparency/window blend
        NormalFloat = {fg = p.fg, bg = p.bg},
        SignColumn = {bg = p.bg},
        Substitute = {fg = p.bg, bg = p.yellow},
        MatchParen = {fg = p.bg, bg = p.light_blue},
        ModeMsg = {link = 'Normal'},
        MoreMsg = {link = 'ModeMsg'},
        Normal = {fg = p.fg, bg = p.bg},

        -- Syntax
        Comment = {fg = p.comment_grey, style = 'italic'},
    },
    options = {
        italic = false,
        cursorline = true,
        underline = false,
    },
})

onedarkpro.load()
