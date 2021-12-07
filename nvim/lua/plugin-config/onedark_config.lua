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
        ColorColumn = {bg = p.cursor_grey},
        Conceal = {fg = p.linenr_grey, bg = p.black},
        Cursor = {fg = p.black, bg = p.blue}, -- actually set by terminal
        CursorColumn = {bg = p.gray},
        CursorLine = {bg = p.cursor_grey},
        CursorLineNr = {fg = p.fg, bg = p.black, style = 'none'},
        Directory = {fg = p.light_blue},
        EndOfBuffer = {link = 'NonText'},
        ErrorMsg = {fg = p.red},
        FoldColumn = {fg = p.comment_grey, bg = p.black},
        Folded = {fg = p.comment_grey, bg = p.black},
        IncSearch = {fg = p.orange, bg = p.black},
        LineNr = {fg = p.linenr_grey},
        MatchParen = {fg = p.cursor_grey, bg = p.light_blue},
        ModeMsg = {fg = p.orange},
        MoreMsg = {link = 'ModeMsg'},
        NonText = {fg = p.comment_grey, bg = p.black},
        Normal = {fg = p.fg, bg = p.bg},
        NormalFloat = {link = 'Pmenu'},
        PMenu = {fg = p.fg, bg = p.pmenu},
        PMenuSbar = {fg = p.fg, bg = p.pmenu},
        PMenuSel = {fg = p.black, bg = p.light_blue},
        PMenuThumb = {bg = p.white},
        Search = {fg = p.black, bg = p.yellow},
        SignColumn = {bg = p.bg},
        StatusLine = {fg = p.fg, bg = p.cursorline},
        StatusLineNC = {bg = p.cursorline},
        Substitute = {fg = p.bg, bg = p.orange},
        TermCursor = {bg = p.blue},
        TermCursorNC = {bg = p.gray},
        VertSplit = {fg = p.cursorline},
        Visual = {bg = p.visual_grey},
        VisualNOS = {link = 'Visual'},
        WildMenu = {link = 'PMenuSel'},

        -- Syntax
        Comment = {fg = p.comment_grey, style = 'italic'},


        -- Filetypes
        ---- Diffs and Git
		DiffAdd = {fg = p.green, bg = p.visual_grey},
		DiffChange = {fg = p.orange, bg = p.visual_grey},
		DiffDelete = {fg = p.red, bg = p.visual_grey},
		DiffText = {fg = p.light_blue, bg = p.visual_grey},
		DiffAdded = {link = 'DiffAdd'},
		DiffChanged = {fg = p.orange, bg = p.visual_grey},
		DiffRemoved = {fg = p.red, bg = p.visual_grey},
        DiffLine = {fg = p.light_blue, bg = p.visual_grey},
		DiffFile = {fg = p.red, bg = p.visual_grey},
		DiffNewFile = {fg = p.green, bg = p.visual_grey},

    },
    options = {
        italic = false,
        cursorline = true,
        underline = false,
    },
})

onedarkpro.load()
