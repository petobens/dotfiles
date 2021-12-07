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
        FloatBorder = {link = 'VertSplit'},
        FoldColumn = {fg = p.comment_grey, bg = p.black},
        Folded = {fg = p.comment_grey, bg = p.black},
        IncSearch = {fg = p.orange, bg = p.black},
        LineNr = {fg = p.linenr_grey},
        MatchParen = {fg = p.cursor_grey, bg = p.light_blue},
        ModeMsg = {link = 'Normal'},
        MoreMsg = {fg = p.orange},
        MsgArea = {link = 'ModeMsg'},
        NonText = {fg = p.comment_grey, bg = p.black},
        Normal = {fg = p.fg, bg = p.bg},
        NormalFloat = {link = 'Pmenu'},
        NormalNC = {link = 'Normal'},
        PMenu = {fg = p.fg, bg = p.pmenu},
        PMenuSbar = {fg = p.fg, bg = p.pmenu},
        PMenuSel = {fg = p.black, bg = p.light_blue},
        PMenuThumb = {bg = p.white},
        Question = {fg = p.light_blue},
        QuickFixLine = {link = 'Normal'},
        Search = {fg = p.black, bg = p.yellow},
        SignColumn = {bg = p.bg},
        SpecialKey = {fg = p.special_grey},
        SpellBad = {sp = p.red, style = 'undercurl'},
        SpellCap = {sp = p.orange, style = 'undercurl'},
        SpellLocal = {link = 'SpellCap'},
        SpellRare = {link = 'SpellCap'},
        StatusLine = {fg = p.fg, bg = p.cursor_grey},
        StatusLineNC = {bg = p.cursor_grey},
        Substitute = {fg = p.bg, bg = p.orange},
        TabLine = {fg = p.white, bg = p.black},
        TabLineFill = {fg = p.comment_grey, bg = p.visual_grey},
        TabLineSel = {fg = p.black, bg = p.light_blue},
        TermCursor = {bg = p.blue},
        TermCursorNC = {bg = p.gray},
        Title = {fg = p.fg},
        VertSplit = {fg = p.cursor_grey},
        Visual = {bg = p.visual_grey},
        VisualNOS = {link = 'Visual'},
        WarningMsg = {fg = p.orange},
        Whitespace = {fg = p.special_grey},
        WildMenu = {link = 'PMenuSel'},

        -- Syntax
        Comment = {fg = p.comment_grey, style = 'italic'},
        Constant = {fg = p.green},
        String = {fg = p.green},
        Character = {fg = p.green},
        Number = {fg = p.orange},
        Boolean = {fg = p.orange},
        Float = {fg = p.orange},
        Identifier = {fg = p.red, style = 'none'},
        Function = {fg = p.light_blue},
        Statement = {fg = p.purple},
        Conditional = {fg = p.purple},
        Repeat = {fg = p.purple},
        Label = {fg = p.purple},
        Operator = {fg = p.blue},
        Keyword = {fg = p.red},
        Exception = {fg = p.purple},
        PreProc = {fg = p.yellow},
        Include = {fg = p.light_blue},
        Define = {fg = p.purple},
        Macro = {fg = p.purple},
        PreCondit = {fg = p.yellow},
        Type = {fg = p.yellow},
        StorageClass = {fg = p.yellow},
        Structure = {fg = p.yellow},
        TypeDef = {fg = p.yellow},
        Special = {fg = p.light_blue},
        SpecialChar = {},
        Tag = {},
        Delimiter = {fg = p.blue},
        SpecialComment = {fg = p.comment_grey},
        Debug = {},
        Ignore = {},
        Underline = {style = 'underline'},
        Bold = {style = 'bold'},
        Italic = {style = 'italic'},
        Error = {fg = p.red, bg = p.black, style = 'bold'},
        Todo = {fg = p.red, bg = p.black},

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
