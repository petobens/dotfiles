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

local p = palette

onedarkpro.setup({
    theme = 'onedark',
    colors = palette,
    hlgroups = {
        -- See https://github.com/olimorris/onedarkpro.nvim/blob/main/lua/onedarkpro/theme.lua
        -- General UI
        ColorColumn = { bg = p.cursor_grey },
        Conceal = { fg = p.linenr_grey, bg = p.black },
        Cursor = { fg = p.black, bg = p.blue }, -- actually set by terminal
        CursorColumn = { bg = p.gray },
        CursorLine = { bg = p.cursor_grey },
        CursorLineNr = { fg = p.fg, bg = p.black, style = 'none' },
        Directory = { fg = p.light_blue },
        EndOfBuffer = { fg = p.comment_grey },
        ErrorMsg = { fg = p.red },
        FloatBorder = { fg = p.cursor_grey },
        FoldColumn = { fg = p.comment_grey, bg = p.black },
        Folded = { fg = p.comment_grey, bg = p.black },
        IncSearch = { fg = p.bg, bg = p.orange },
        LineNr = { fg = p.linenr_grey },
        MatchParen = { fg = p.cursor_grey, bg = p.light_blue },
        ModeMsg = { fg = p.fg, bg = p.bg },
        MoreMsg = { fg = p.orange },
        MsgArea = { fg = p.fg, bg = p.bg },
        NonText = { fg = p.comment_grey },
        Normal = { fg = p.fg, bg = p.bg },
        NormalFloat = { fg = p.fg, bg = p.pmenu },
        -- NormalFloat = { link = 'Pmenu' },
        NormalNC = { fg = p.fg, bg = p.bg },
        Pmenu = { fg = p.fg, bg = p.pmenu },
        PmenuSbar = { fg = p.fg, bg = p.pmenu }, -- scrolling bar space
        PmenuSel = { fg = p.black, bg = p.light_blue },
        PmenuThumb = { bg = p.linenr_grey }, -- scrollbar color
        Question = { fg = p.light_blue },
        QuickFixLine = { bg = p.cursor_grey },
        Search = { fg = p.black, bg = p.yellow },
        SignColumn = { bg = p.bg },
        SpecialKey = { fg = p.special_grey },
        SpellBad = { sp = p.red, style = 'undercurl' },
        SpellCap = { sp = p.orange, style = 'undercurl' },
        SpellLocal = { link = 'SpellCap' },
        SpellRare = { link = 'SpellCap' },
        StatusLine = { fg = p.fg, bg = p.cursor_grey },
        StatusLineNC = { bg = p.cursor_grey },
        Substitute = { fg = p.bg, bg = p.orange },
        TabLine = { fg = p.white, bg = p.black },
        TabLineFill = { fg = p.comment_grey, bg = p.visual_grey },
        TabLineSel = { fg = p.black, bg = p.light_blue },
        TermCursor = { bg = p.blue },
        TermCursorNC = { bg = p.gray },
        Title = { fg = p.fg },
        Visual = { bg = p.visual_grey },
        VisualNOS = { bg = p.visual_grey },
        WarningMsg = { fg = p.orange },
        Whitespace = { fg = p.special_grey }, -- listchars
        WildMenu = { fg = p.black, bg = p.light_blue },
        WinSeparator = { fg = p.cursor_grey },

        -- Syntax
        Comment = { fg = p.comment_grey, style = 'italic' },
        Constant = { fg = p.cyan },
        String = { fg = p.green },
        Character = { fg = p.green },
        Number = { fg = p.orange },
        Boolean = { fg = p.orange },
        Float = { fg = p.orange },
        Identifier = { fg = p.red, style = 'none' },
        Function = { fg = p.light_blue },
        Statement = { fg = p.purple },
        Conditional = { fg = p.purple },
        Repeat = { fg = p.purple },
        Label = { fg = p.purple },
        Operator = { fg = p.cyan },
        Keyword = { fg = p.red },
        Exception = { fg = p.purple },
        PreProc = { fg = p.yellow },
        Include = { fg = p.light_blue },
        Define = { fg = p.purple },
        Macro = { fg = p.purple },
        PreCondit = { fg = p.yellow },
        Type = { fg = p.yellow },
        StorageClass = { fg = p.yellow },
        Structure = { fg = p.yellow },
        TypeDef = { fg = p.yellow },
        Special = { fg = p.light_blue },
        SpecialChar = { fg = p.orange },
        Tag = {},
        Delimiter = { fg = p.blue },
        SpecialComment = { fg = p.comment_grey },
        Debug = {},
        Ignore = {},
        Underlined = { style = 'underline' },
        Bold = { style = 'bold' },
        Italic = { style = 'italic' },
        Error = { fg = p.red, bg = p.black, style = 'bold' },
        Todo = { fg = p.red, bg = p.black },

        -- Diagnostics (and LSP)
        DiagnosticError = { link = 'Error' },
        DiagnosticWarn = { fg = p.orange },
        DiagnosticInfo = { fg = p.light_blue },
        DiagnosticHint = { fg = p.cyan },
        DiagnosticFloatingError = { link = 'DiagnosticError' },
        DiagnosticFloatingWarn = { link = 'DiagnosticWarn' },
        DiagnosticFloatingInfo = { link = 'DiagnosticInfo' },
        DiagnosticFloatingHint = { link = 'DiagnosticHint' },
        DiagnosticSignError = { link = 'DiagnosticError' },
        DiagnosticSignWarn = { link = 'DiagnosticWarn' },
        DiagnosticSignInfo = { link = 'DiagnosticInfo' },
        DiagnosticSignHint = { link = 'DiagnosticHint' },
        DiagnosticUnderlineError = { link = 'DiagnosticError' },
        DiagnosticUnderlineWarn = { link = 'DiagnosticWarn' },
        DiagnosticUnderlineInfo = { link = 'DiagnosticInfo' },
        DiagnosticUnderlineHint = { link = 'DiagnosticHint' },
        DiagnosticVirtualTextError = { link = 'DiagnosticError' },
        DiagnosticVirtualTextWarn = { link = 'DiagnosticWarn' },
        DiagnosticVirtualTextInfo = { link = 'DiagnosticInfo' },
        DiagnosticVirtualTextHint = { link = 'DiagnosticHint' },
        LspReferenceText = { bg = p.visual_grey },
        LspReferenceRead = { link = 'LspReferenceText' },
        LspReferenceWrite = { link = 'LspReferenceText' },
        -- TODO: add other lsp hls (as code lens)

        -- Treesitter stuff
        TSBoolean = { fg = p.orange },
        TSDanger = { fg = p.red, style = 'bold' },
        TSEmphasis = { fg = p.orange, style = 'italic' },
        TSField = { fg = p.fg },
        TSFunction = { fg = p.light_blue },
        TSInclude = { fg = p.purple },
        TSLiteral = { fg = p.green }, -- embedded code
        TSMethod = { fg = p.light_blue },
        TSParameter = { fg = p.orange },
        TSPunctSpecial = { fg = p.blue },
        TSStringEscape = { fg = p.fg },
        TSStrong = { fg = p.orange, style = 'bold' },
        TSTextReference = { link = 'TSText' },
        TSTitle = { fg = p.dark_red, style = 'bold' },
        TSURI = { fg = p.blue, style = 'underline' },
        TSWarning = { fg = p.orange },

        -- Filetypes
        ---- Vim help
        helpCommand = { fg = p.yellow },
        helpExample = { fg = p.yellow },
        helpHeader = { fg = p.white, style = 'bold' },
        helpSectionDelim = { fg = p.comment_grey },

        ---- Diffs
        DiffAdd = { fg = p.green, bg = p.visual_grey },
        DiffChange = { fg = p.orange, bg = p.visual_grey },
        DiffDelete = { fg = p.red, bg = p.visual_grey },
        DiffText = { fg = p.light_blue, bg = p.visual_grey },
        DiffAdded = { link = 'DiffAdd' },
        DiffChanged = { fg = p.orange, bg = p.visual_grey },
        DiffRemoved = { fg = p.red, bg = p.visual_grey },
        DiffLine = { fg = p.light_blue, bg = p.visual_grey },
        DiffFile = { fg = p.red, bg = p.visual_grey },
        DiffNewFile = { fg = p.green, bg = p.visual_grey },

        ---- Git
        gitcommitComment = { fg = p.comment_grey },
        gitcommitUnmerged = { fg = p.green },
        gitcommitOnBranch = { fg = p.fg },
        gitcommitBranch = { fg = p.purple },
        gitcommitDiscardedType = { fg = p.red },
        gitcommitSelectedType = { fg = p.green },
        gitcommitHeader = { fg = p.fg },
        gitcommitUntrackedFile = { fg = p.cyan },
        gitcommitDiscardedFile = { fg = p.red },
        gitcommitSelectedFile = { fg = p.green },
        gitcommitUnmergedFile = { fg = p.yellow },
        gitcommitFile = { fg = p.fg },
        gitcommitFirstLine = { fg = p.fg },
        gitcommitNoBranch = { link = 'gitcommitBranch' },
        gitcommitUntracked = { link = 'gitcommitComment' },
        gitcommitDiscarded = { link = 'gitcommitComment' },
        gitcommitSelected = { link = 'gitcommitComment' },
        gitcommitDiscardedArrow = { link = 'gitcommitDiscardedFile' },
        gitcommitSelectedArrow = { link = 'gitcommitSelectedFile' },
        gitcommitUnmergedArrow = { link = 'gitcommitUnmergedFile' },

        -- Plugins
        ---- Fugitive
        diffAdded = { fg = p.green },
        diffRemoved = { fg = p.red },
        fugitiveUnstagedHeading = { fg = p.red },
        fugitiveUnstagedModifier = { fg = p.red },
        fugitiveStagedHeading = { fg = p.green },
        fugitiveStagedModifier = { fg = p.green },

        ---- IndentBlankline
        IndentLine = { fg = p.comment_grey },
        IndentBlanklineContextChar = { fg = p.white },

        ---- HlWords (in udfs)
        HlWord1 = { fg = p.black, bg = p.yellow },
        HlWord2 = { fg = p.black, bg = p.green },
        HlWord3 = { fg = p.black, bg = p.purple },
        HlWord4 = { fg = p.black, bg = p.orange },
        HlWord5 = { fg = p.black, bg = p.light_blue },
        HlWord6 = { fg = p.black, bg = p.white },

        ---- Telescope
        TelescopeNormal = { fg = p.fg, bg = p.bg },
        TelescopeSelection = { fg = p.fg, bg = p.cursor_grey, style = 'bold' },
        TelescopeSelectionCaret = { fg = p.purple, style = 'bold' },
        TelescopeMultiSelection = { fg = p.orange },
        TelescopeMultiIcon = { fg = p.orange },
        TelescopeBorder = { fg = p.cursor_grey },
        TelescopeTitle = { fg = p.comment_grey, bg = p.bg },
        TelescopePromptCounter = { fg = p.linenr_grey },
        TelescopePromptPrefix = { fg = p.purple, style = 'bold' },
        TelescopeMatching = { fg = p.blue },
    },
    filetype_hlgroups = {
        json = {
            jsonTSLabel = { fg = p.red },
        },
        markdown = {
            markdownTSPunctSpecial = { fg = p.dark_red, style = 'bold' },
        },
        python = {
            pythonTSConstant = { fg = p.orange },
            pythonTSPunctSpecial = { fg = p.orange },
        },
        sh = {
            bashTSParameter = { fg = p.fg },
            bashTSPunctSpecial = { fg = p.red, style = 'none' },
        },
        yaml = {
            yamlBool = { fg = p.orange },
        },
    },
    plugins = {
        all = false,
        treesitter = true,
    },
    options = {
        italic = false,
        cursorline = true,
        underline = false,
    },
})

onedarkpro.load()

-- Embedded Terminal colors (don't really need to define these)
local set = vim.g
set.terminal_color_0 = p.black
set.terminal_color_1 = p.red
set.terminal_color_2 = p.green
set.terminal_color_3 = p.yellow
set.terminal_color_4 = p.light_blue
set.terminal_color_5 = p.purple
set.terminal_color_6 = p.cyan
set.terminal_color_7 = p.white
set.terminal_color_8 = p.visual_grey
set.terminal_color_9 = p.dark_red
set.terminal_color_10 = p.green
set.terminal_color_11 = p.orange
set.terminal_color_12 = p.light_blue
set.terminal_color_13 = p.purple
set.terminal_color_14 = p.cyan
set.terminal_color_15 = p.comment_grey
set.terminal_color_background = p.black
set.terminal_color_foreground = p.white
