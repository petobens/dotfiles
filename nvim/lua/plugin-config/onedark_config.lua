-- luacheck:ignore 631

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
        CursorLineFold = { link = 'CursorLineNr' },
        Directory = { fg = p.light_blue },
        EndOfBuffer = { fg = p.comment_grey },
        ErrorMsg = { fg = p.red },
        FloatBorder = { fg = p.cursor_grey, bg = p.none },
        FloatTitle = { fg = p.cursor_grey, bg = p.none },
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
        PmenuSbar = { bg = p.bg }, -- scrolling bar space
        PmenuThumb = { bg = p.pmenu }, -- scrollbar color
        PmenuSel = { link = 'WildMenu' },
        Question = { fg = p.light_blue },
        QuickFixLine = { bg = p.cursor_grey },
        Search = { fg = p.black, bg = p.yellow },
        CurSearch = { link = 'IncSearch' },
        SignColumn = { bg = p.bg },
        SpecialKey = { fg = p.special_grey },
        SpellBad = { fg = p.none, sp = p.red, style = 'undercurl' },
        SpellCap = { fg = p.none, sp = p.orange, style = 'undercurl' },
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
        Title = { fg = p.green },
        VertSplit = { link = 'FloatBorder' },
        Visual = { bg = p.visual_grey },
        VisualNOS = { bg = p.visual_grey },
        WarningMsg = { fg = p.orange },
        Whitespace = { fg = p.special_grey }, -- listchars
        WildMenu = { fg = p.black, bg = p.light_blue },
        WinSeparator = { link = 'FloatBorder' },

        -- Syntax
        Comment = { fg = p.comment_grey, bg = p.none, style = 'italic' },
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

        -- Diagnostics
        DiagnosticError = { link = 'Error' },
        DiagnosticWarn = { link = 'WarningMsg' },
        DiagnosticInfo = { fg = p.light_blue },
        DiagnosticHint = { fg = p.cyan },
        DiagnosticOk = { fg = p.green },
        DiagnosticDeprecated = { fg = p.fg, style = 'strikethrough' },
        DiagnosticVirtualTextError = { link = 'DiagnosticError' },
        DiagnosticVirtualTextWarn = { link = 'DiagnosticWarn' },
        DiagnosticVirtualTextInfo = { link = 'DiagnosticInfo' },
        DiagnosticVirtualTextHint = { link = 'DiagnosticHint' },
        DiagnosticUnderlineError = { link = 'DiagnosticError' },
        DiagnosticUnderlineWarn = { link = 'DiagnosticWarn' },
        DiagnosticUnderlineInfo = { link = 'DiagnosticInfo' },
        DiagnosticUnderlineHint = { link = 'DiagnosticHint' },
        DiagnosticFloatingError = { link = 'DiagnosticError' },
        DiagnosticFloatingWarn = { link = 'DiagnosticWarn' },
        DiagnosticFloatingInfo = { link = 'DiagnosticInfo' },
        DiagnosticFloatingHint = { link = 'DiagnosticHint' },
        DiagnosticSignError = { link = 'DiagnosticError' },
        DiagnosticSignWarn = { link = 'DiagnosticWarn' },
        DiagnosticSignInfo = { link = 'DiagnosticInfo' },
        DiagnosticSignHint = { link = 'DiagnosticHint' },

        -- Lsp
        LspReferenceText = { bg = p.visual_grey },
        LspReferenceRead = { link = 'LspReferenceText' },
        LspReferenceWrite = { link = 'LspReferenceText' },
        LspSignatureActiveParameter = { fg = p.light_blue, bg = p.visual_grey },
        LspInlayHint = { fg = p.linenr_grey },

        -- Treesitter
        ['@boolean'] = { fg = p.orange },
        ['@field'] = { fg = p.fg },
        ['@function'] = { fg = p.light_blue },
        ['@include'] = { fg = p.purple },
        ['@keyword'] = { fg = p.purple },
        ['@method'] = { fg = p.light_blue },
        ['@parameter'] = { fg = p.orange },
        ['@punctuation.special'] = { fg = p.blue },
        ['@string.escape'] = { fg = p.fg },
        ['@text.danger'] = { fg = p.red, style = 'bold' },
        ['@text.emphasis'] = { fg = p.orange, style = 'italic' },
        ['@text.literal'] = { fg = p.green }, -- embedded code
        ['@text.reference'] = { fg = p.blue },
        ['@text.strong'] = { fg = p.orange, style = 'bold' },
        ['@text.title'] = { fg = p.dark_red, style = 'bold' },
        ['@text.uri'] = { fg = p.blue, sp = p.blue, style = 'undercurl' },
        ['@text.uri.comment'] = {
            fg = p.comment_grey,
            sp = p.comment_grey,
            style = 'undercurl',
        },
        ['@text.warning'] = { fg = p.orange, style = 'bold' },

        -- Generic Semantic Tokens
        ['@defaultLibrary'] = { fg = p.yellow },

        -- Filetypes
        ---- Bash
        ['@parameter.bash'] = { fg = p.orange },
        ['@punctuation.special.bash'] = { fg = p.red },

        ---- Json
        ['@label.json'] = { fg = p.red },

        -- Latex
        texTitleArg = { style = 'bold' },
        texMathEnvArgName = { fg = p.yellow },
        ---- treesitter hl for embedded latex in md files:
        ['@function.latex'] = { fg = p.purple },
        ['@function.macro.latex'] = { fg = p.purple },
        ['@punctuation.bracket.latex'] = { fg = p.blue },
        ['@markup.link.latex'] = {},
        ['@markup.environment.latex'] = { fg = p.purple },
        ['@markup.environment.name.latex'] = { fg = p.yellow },
        ['@md_latex_equation_dollar'] = { fg = p.blue },
        ['@md_latex_equation_double_dollar'] = { fg = p.blue },

        -- Lua
        ['@field.lua'] = { fg = p.red },
        ['@keyword.lua'] = { fg = p.purple },
        ['@keyword.return.lua'] = { fg = p.purple },
        ['@lsp.mod.defaultLibrary.lua'] = { fg = p.yellow },
        ['@lsp.mod.documentation.lua'] = { fg = p.purple },
        ['@lsp.mod.static.lua'] = { fg = p.yellow },
        ['@lsp.type.comment.lua'] = {},
        ['@lsp.type.keyword.lua'] = { fg = p.red },
        ['@lsp.type.method.lua'] = { fg = p.light_blue },
        ['@lsp.type.property.lua'] = {},
        ['@lsp.typemod.function.defaultLibrary.lua'] = { fg = p.yellow },
        ['@punctuation.bracket.lua'] = { fg = p.fg },

        ---- Markdown
        ['@markup.heading.1.markdown'] = { fg = p.purple, style = 'bold' },
        ['@markup.heading.1.marker.markdown'] = { link = '@markup.heading.1.markdown' },
        ['@text.title.1.conceal.markdown'] = { link = '@markup.heading.1.markdown' },
        ['@markup.heading.2.markdown'] = { fg = p.light_blue, style = 'bold' },
        ['@markup.heading.2.marker.markdown'] = { link = '@markup.heading.2.markdown' },
        ['@text.title.2.conceal.markdown'] = { link = '@markup.heading.2.markdown' },
        ['@markup.heading.3.markdown'] = { fg = p.cyan, style = 'bold' },
        ['@markup.heading.3.marker.markdown'] = { link = '@markup.heading.3.markdown' },
        ['@text.title.3.conceal.markdown'] = { link = '@markup.heading.3.markdown' },
        ['@markup.heading.4.markdown'] = { fg = p.blue, style = 'bold' },
        ['@markup.heading.4.marker.markdown'] = { link = '@markup.heading.4.markdown' },
        ['@text.title.4.conceal.markdown'] = { link = '@markup.heading.4.markdown' },
        ['@markup.heading.5.markdown'] = { fg = p.green, style = 'bold' },
        ['@markup.heading.5.marker.markdown'] = { link = '@markup.heading.5.markdown' },
        ['@text.title.5.conceal.markdown'] = { link = '@markup.heading.5.markdown' },
        ['@markup.list.markdown'] = { fg = p.dark_red, style = 'bold' },
        ['@punctuation.special.bullet.conceal.markdown'] = {
            link = '@markup.list.markdown',
        },
        ['@text.todo.checked.markdown'] = { fg = p.green },
        ['@text.todo.checked.conceal.markdown'] = { link = '@text.todo.checked.markdown' },
        ['@text.todo.unchecked.markdown'] = { fg = p.red },
        ['@text.todo.unchecked.conceal.markdown'] = {
            link = '@text.todo.unchecked.markdown',
        },
        ['@text.todo.doing.conceal.markdown_inline'] = { fg = p.cyan },
        ['@text.todo.wontdo.conceal.markdown_inline'] = { fg = p.red },
        ['@punctuation.special.block.conceal.markdown'] = { fg = p.gray },
        ['@markup.quote.markdown'] = { fg = p.comment_grey },
        ['@markup.link.label.markdown_inline'] = { fg = p.blue, style = 'undercurl' },
        ['@markup.link.url.markdown_inline'] = {
            fg = p.light_blue,
            sp = p.light_blue,
            style = 'undercurl',
        },
        ['@lsp.type.class.markdown'] = { fg = p.orange }, -- wiki links
        ['@lsp.type.enumMember.markdown'] = { fg = p.orange }, -- hashtags
        ['@label.markdown'] = { fg = p.cyan }, -- code blocks
        ['@markup.strong.markdown_inline'] = { style = 'bold' },
        ['@markup.italic.markdown_inline'] = { style = 'italic' },
        ['@text.comment.markdown'] = { link = 'Comment' },
        ['@front_matter.markdown'] = { fg = p.yellow },

        --- Sql
        ['@type.sql'] = { fg = p.light_blue },

        --- TOML
        ['@table_brackets.toml'] = { fg = p.yellow },

        ---- Python
        ['@attribute.builtin.python'] = { fg = p.blue },
        ['@attribute.python'] = { fg = p.blue },
        ['@constant.builtin.python'] = { fg = p.orange },
        ['@constant.python'] = { fg = p.orange },
        ['@function.builtin.python'] = { fg = p.yellow },
        ['@include.python'] = { fg = p.purple },
        ['@keyword.python'] = { fg = p.purple },
        ['@keyword.return.python'] = { fg = p.purple },
        ['@punctuation.special.python'] = { fg = p.orange },

        ---- vim-doc and checkhealth
        ['@conceal.vimdoc'] = { fg = p.red },
        ['@label.vimdoc'] = { fg = p.green, style = p.none },
        ['@parameter.vimdoc'] = { fg = p.light_blue },
        ['@text.literal.vimdoc'] = { fg = p.yellow },
        ['@text.literal.block.vimdoc'] = { link = '@text.literal.vimdoc' },
        ['@text.reference.vimdoc'] = { fg = p.red },
        ['@text.title.vimdoc'] = { fg = p.purple },
        ['@text.title.1.vimdoc'] = { link = '@text.title.vimdoc' },
        ['@text.title.2.vimdoc'] = { link = '@text.title.vimdoc' },
        ['@text.title.3.vimdoc'] = { link = '@text.title.vimdoc' },
        ['@text.title.4.vimdoc'] = { link = '@text.title.vimdoc' },
        ['@text.title.5.vimdoc'] = { link = '@text.title.vimdoc' },
        helpSectionDelim = { fg = p.red },
        healthSuccess = { fg = p.black, bg = p.green },
        ['@constant.builtin.vim'] = { fg = p.yellow },

        --- YAML
        ['@field.yaml'] = { fg = p.red },
        ['@punctuation.special.yaml'] = { fg = p.yellow },

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
        ---- Aerial
        AerialLine = { bg = p.visual_grey },

        ---- Cmp
        CmpItemAbbr = { fg = p.fg },
        CmpItemAbbrDeprecated = { fg = p.fg },
        CmpItemAbbrMatch = { fg = p.blue },
        CmpItemAbbrMatchFuzzy = { fg = p.blue },
        CmpItemMenu = { fg = p.gray },
        CmpItemKind = { fg = p.gray },

        ---- DBUI
        dbui_new_query = { fg = p.green },

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
        GitSignsAddInline = { link = 'DiffAdd' },
        GitSignsChangeInline = { link = 'DiffChange' },
        GitSignsDeleteInline = { link = 'DiffDelete' },

        ---- HlWords
        HlWord1 = { link = 'Search' },
        HlWord2 = { fg = p.black, bg = p.green },
        HlWord3 = { fg = p.black, bg = p.purple },
        HlWord4 = { fg = p.black, bg = p.orange },
        HlWord5 = { fg = p.black, bg = p.light_blue },
        HlWord6 = { fg = p.black, bg = p.white },

        ---- Lazy
        LazyCommit = { fg = p.red },
        LazyHandlerPlugin = { fg = p.purple },
        LazyDimmed = { fg = p.comment_grey },

        ---- IndentBlankline
        IblIndent = { fg = p.special_grey },
        IblScope = { fg = p.gray },

        ---- Leap (and flit)
        LeapMatch = { fg = p.black, bg = p.purple, style = 'bold' },
        LeapLabelPrimary = { fg = p.black, bg = p.purple, style = 'bold' },

        ---- Neotest
        NeotestAdapterName = { fg = p.purple },
        NeotestTarget = { fg = p.orange },
        NeotestDir = { fg = p.light_blue },
        NeotestFile = { fg = p.white },
        NeotestNamespace = { fg = p.yellow },
        NeotestExpandMarker = { fg = p.gray },
        NeotestMarked = { fg = p.fg, bg = p.cursor_grey, style = 'bold' },
        NeotestFocused = { bg = p.visual_grey },
        NeotestPassed = { fg = p.green },
        NeotestFailed = { fg = p.red },
        NeotestRunning = { fg = p.orange },
        NeotestSkipped = { fg = p.yellow },
        NeotestUnknown = { fg = p.gray },

        ---- NvimTree
        NvimTreeWinSeparator = { link = 'FloatBorder' },
        NvimTreeFolderName = { fg = p.light_blue },
        NvimTreeFolderIcon = { link = 'NvimTreeFolderName' },
        NvimTreeOpenedFolderName = { link = 'NvimTreeFolderName' },
        NvimTreeEmptyFolderName = { link = 'NvimTreeFolderName' },
        NvimTreeRootFolder = { fg = p.purple },
        NvimTreeIndentMarker = { fg = p.gray, style = 'bold' },
        NvimTreeFolderArrowOpen = { link = 'NvimTreeIndentMarker' },
        NvimTreeFolderArrowClosed = { link = 'NvimTreeIndentMarker' },
        NvimTreeSymlink = { fg = p.purple },
        NvimTreeGitDirty = { fg = p.red }, -- modified/unstaged
        NvimTreeGitStaged = { fg = p.green },
        NvimTreeGitMerge = { fg = p.cyan },
        NvimTreeGitRenamed = { fg = p.yellow },
        NvimTreeGitNew = { fg = p.green },
        NvimTreeGitDeleted = { fg = p.red },
        NvimTreeExecFile = { fg = p.red },
        NvimTreeSpecialFile = { fg = p.yellow, style = 'bold' },

        ---- Overseer
        OverseerTask = { fg = p.purple },
        OverseerSUCCESS = { fg = p.green },
        OverseerFAILURE = { fg = p.red },
        OverseerCANCELED = { fg = p.orange },

        ---- Sniprun
        SnipRunVirtualTextOk = { fg = p.black, bg = p.purple, style = 'bold' },

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

        ---- VimTex
        VimtexTocSec0 = { link = 'Normal' },
    },
    filetypes = {
        all = false,
    },
    plugins = {
        all = false,
        treesitter = true,
    },
})

vim.cmd('colorscheme onedark')
