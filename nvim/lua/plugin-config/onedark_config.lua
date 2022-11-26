local onedarkpro = require('onedarkpro')

local palette = {
    bg = '#24272e',
    fg = '#abb2bf',
    none = 'NONE',

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
    highlights = {
        -- See https://github.com/olimorris/onedarkpro.nvim/blob/main/lua/onedarkpro/theme.lua
        -- General UI
        ColorColumn = { bg = p.cursor_grey },
        Conceal = { fg = p.linenr_grey, bg = p.black },
        Cursor = { fg = p.black, bg = p.blue }, -- actually set by terminal
        CursorColumn = { bg = p.gray },
        CursorLine = { bg = p.cursor_grey },
        CursorLineNr = { fg = p.fg, bg = p.black, style = p.none },
        Directory = { fg = p.light_blue },
        EndOfBuffer = { fg = p.comment_grey },
        ErrorMsg = { fg = p.red },
        FloatBorder = { fg = p.cursor_grey },
        FloatTitle = { fg = p.cursor_grey },
        FoldColumn = { fg = p.comment_grey, bg = p.black },
        Folded = { link = 'FoldColumn' },
        IncSearch = { fg = p.bg, bg = p.orange },
        LineNr = { fg = p.linenr_grey },
        MatchParen = { fg = p.cursor_grey, bg = p.light_blue },
        ModeMsg = { link = 'Normal' },
        MoreMsg = { fg = p.orange },
        MsgArea = { link = 'Normal' },
        NonText = { fg = p.comment_grey },
        Normal = { fg = p.fg, bg = p.bg },
        NormalFloat = { fg = p.fg, bg = p.bg, blend = 6 },
        NormalNC = { link = 'Normal' },
        Pmenu = { fg = p.fg, bg = p.pmenu },
        PmenuSbar = { link = 'Pmenu' }, -- scrolling bar space
        PmenuSel = { link = 'WildMenu' },
        PmenuThumb = { bg = p.pmenu }, -- scrollbar color
        Question = { fg = p.light_blue },
        QuickFixLine = { bg = p.cursor_grey },
        Search = { fg = p.black, bg = p.yellow },
        CurSearch = { link = 'IncSearch' },
        SignColumn = { bg = p.bg },
        SpecialKey = { fg = p.special_grey },
        SpellBad = { sp = p.red, style = 'undercurl' },
        SpellCap = { sp = p.orange, style = 'undercurl' },
        SpellLocal = { link = 'SpellCap' },
        SpellRare = { link = 'SpellCap' },
        StatusLine = { fg = p.fg, bg = p.cursor_grey },
        StatusLineNC = { bg = p.cursor_grey },
        Substitute = { link = 'IncSearch' },
        TabLine = { fg = p.white, bg = p.black },
        TabLineFill = { fg = p.comment_grey, bg = p.visual_grey },
        TabLineSel = { link = 'WildMenu' },
        TermCursor = { bg = p.blue },
        TermCursorNC = { link = 'CursorColumn' },
        Title = { fg = p.fg },
        VertSplit = { link = 'FloatBorder' }, -- for nvim-tree separator
        Visual = { bg = p.visual_grey },
        VisualNOS = { bg = p.visual_grey },
        WarningMsg = { fg = p.orange },
        Whitespace = { fg = p.special_grey }, -- listchars
        WildMenu = { fg = p.black, bg = p.light_blue },
        WinSeparator = { link = 'FloatBorder' },

        -- Syntax
        Comment = { fg = p.comment_grey, style = 'italic' },
        Constant = { fg = p.cyan },
        String = { fg = p.green },
        Character = { fg = p.green },
        Number = { fg = p.orange },
        Boolean = { link = 'Number' },
        Float = { link = 'Number' },
        Identifier = { fg = p.red, style = p.none },
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
        -- Initial empty hl ({}) to avoid highlighting code with diagnostic colors
        DiagnosticError = {},
        DiagnosticWarn = {},
        DiagnosticInfo = {},
        DiagnosticHint = {},
        DiagnosticVirtualTextError = { link = 'Error' },
        DiagnosticVirtualTextWarn = { fg = p.orange },
        DiagnosticVirtualTextInfo = { fg = p.light_blue },
        DiagnosticVirtualTextHint = { fg = p.cyan },
        DiagnosticUnderlineError = { link = 'DiagnosticVirtualTextError' },
        DiagnosticUnderlineWarn = { link = 'DiagnosticVirtualTextWarn' },
        DiagnosticUnderlineInfo = { link = 'DiagnosticVirtualTextInfo' },
        DiagnosticUnderlineHint = { link = 'DiagnosticVirtualTextHint' },
        DiagnosticFloatingError = { link = 'DiagnosticVirtualTextError' },
        DiagnosticFloatingWarn = { link = 'DiagnosticVirtualTextWarn' },
        DiagnosticFloatingInfo = { link = 'DiagnosticVirtualTextInfo' },
        DiagnosticFloatingHint = { link = 'DiagnosticVirtualTextHint' },
        DiagnosticSignError = { link = 'DiagnosticVirtualTextError' },
        DiagnosticSignWarn = { link = 'DiagnosticVirtualTextWarn' },
        DiagnosticSignInfo = { link = 'DiagnosticVirtualTextInfo' },
        DiagnosticSignHint = { link = 'DiagnosticVirtualTextHint' },
        LspReferenceText = { bg = p.visual_grey },
        LspReferenceRead = { link = 'LspReferenceText' },
        LspReferenceWrite = { link = 'LspReferenceText' },

        -- Treesitter
        ['@boolean'] = { fg = p.orange },
        ['@field'] = { fg = p.fg },
        ['@function'] = { fg = p.light_blue },
        ['@include'] = { fg = p.purple },
        ['@method'] = { fg = p.light_blue },
        ['@parameter'] = { fg = p.orange },
        ['@punctuation.special'] = { fg = p.blue },
        ['@string.escape'] = { fg = p.fg },
        ['@text.danger'] = { fg = p.red, style = 'bold' },
        ['@text.emphasis'] = { fg = p.orange, style = 'italic' },
        ['@text.literal'] = { fg = p.green }, -- embedded code
        ['@text.reference'] = { link = 'TSText' },
        ['@text.strong'] = { fg = p.orange, style = 'bold' },
        ['@text.title'] = { fg = p.dark_red, style = 'bold' },
        ['@text.uri'] = { fg = p.blue, style = 'underline' },
        ['@text.warning'] = { fg = p.orange, style = 'bold' },

        -- Filetypes
        ---- Bash
        ['@parameter.bash'] = { fg = p.fg },
        ['@punctuation.special.bash'] = { fg = p.red },

        ---- Json
        ['@label.json'] = { fg = p.red },

        -- Latex
        texTitleArg = { style = 'bold' },
        texMathEnvArgName = { fg = p.yellow },

        ---- Markdown
        ['@punctuation.special.markdown'] = { fg = p.dark_red, style = 'bold' },
        ['@text.title.markdown'] = { fg = p.dark_red, style = 'bold' },

        ---- Python
        ['@constant.python'] = { fg = p.orange },
        ['@function.builtin.python'] = { fg = p.yellow },
        ['@punctuation.special.python'] = { fg = p.orange },

        --- Yaml
        yamlBool = { fg = p.orange },

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
        DiffChanged = { link = 'DiffChange' },
        DiffRemoved = { link = 'DiffDelete' },
        DiffLine = { link = 'DiffText' },
        DiffFile = { link = 'DiffDelete' },
        DiffNewFile = { link = 'DiffAdd' },

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
        ---- Cmp
        CmpItemAbbr = { fg = p.fg },
        CmpItemAbbrDeprecated = { fg = p.fg },
        CmpItemAbbrMatch = { fg = p.blue },
        CmpItemAbbrMatchFuzzy = { fg = p.blue },
        CmpItemMenu = { fg = p.gray },
        CmpItemKind = { fg = p.gray },

        ---- Fugitive
        diffAdded = { fg = p.green },
        diffRemoved = { fg = p.red },
        fugitiveUnstagedHeading = { fg = p.red },
        fugitiveUnstagedModifier = { fg = p.red },
        fugitiveStagedHeading = { fg = p.green },
        fugitiveStagedModifier = { fg = p.green },

        ---- Gitsigns
        GitSignsAdd = { fg = p.green },
        GitSignsChange = { fg = p.orange },
        GitSignsDelete = { fg = p.red },

        ---- HlWords (in udfs)
        HlWord1 = { link = 'Search' },
        HlWord2 = { fg = p.black, bg = p.green },
        HlWord3 = { fg = p.black, bg = p.purple },
        HlWord4 = { fg = p.black, bg = p.orange },
        HlWord5 = { fg = p.black, bg = p.light_blue },
        HlWord6 = { fg = p.black, bg = p.white },

        ---- IndentBlankline
        IndentLine = { fg = p.comment_grey },
        IndentBlanklineContextChar = { fg = p.white },

        ---- Leap (and flit)
        LeapMatch = { fg = p.black, bg = p.purple, style = 'bold' },
        LeapLabelPrimary = { fg = p.black, bg = p.purple, style = 'bold' },

        ---- NvimTree
        NvimTreeFolderIcon = { fg = p.light_blue },
        NvimTreeFolderName = { fg = p.light_blue },
        NvimTreeOpenedFolderName = { link = 'NvimTreeFolderName' },
        NvimTreeEmptyFolderName = { link = 'NvimTreeFolderName' },
        NvimTreeRootFolder = { fg = p.purple },
        NvimTreeIndentMarker = { fg = p.gray, style = 'bold' },
        NvimTreeSymlink = { fg = p.purple },
        NvimTreeGitDirty = { fg = p.red }, -- modified/unstaged
        NvimTreeGitStaged = { fg = p.green },
        NvimTreeGitMerge = { fg = p.cyan },
        NvimTreeGitRenamed = { fg = p.yellow },
        NvimTreeGitNew = { fg = p.green },
        NvimTreeGitDeleted = { fg = p.red },
        NvimTreeExecFile = { fg = p.red },
        NvimTreeSpecialFile = { fg = p.yellow, style = 'bold' },

        ---- Packer
        packerFail = { fg = p.red },
        packerSuccess = { fg = p.green },
        packerWorking = { fg = p.yellow },
        packerOutput = { fg = p.blue },
        packerStatusFail = { fg = p.red },
        packerStatusSuccess = { fg = p.green },

        ---- Telescope
        TelescopeNormal = { link = 'Normal' },
        TelescopeSelection = { fg = p.fg, bg = p.cursor_grey, style = 'bold' },
        TelescopeSelectionCaret = { fg = p.purple, style = 'bold' },
        TelescopeMultiSelection = { fg = p.orange },
        TelescopeMultiIcon = { fg = p.orange },
        TelescopeBorder = { link = 'FloatBorder' },
        TelescopeTitle = { fg = p.comment_grey, bg = p.bg },
        TelescopePromptCounter = { fg = p.linenr_grey },
        TelescopePromptPrefix = { fg = p.purple, style = 'bold' },
        TelescopeMatching = { fg = p.blue },
    },
    filetypes = {
        all = false,
    },
    plugins = {
        all = false,
        treesitter = true,
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
