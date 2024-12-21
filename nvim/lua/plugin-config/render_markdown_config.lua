require('render-markdown').setup({
    enabled = true,
    file_types = { 'markdown', 'chatgpt', 'chatgpt-input' },
    render_modes = true,
    win_options = {
        conceallevel = { rendered = 2 },
        concealcursor = { rendered = 'nc' },
    },
    anti_conceal = {
        -- Preserve glyphs in normal mode but make them "anti_conceal" in insert mode to
        -- replicate concealcursor behaviour
        ignore = {
            bullet = { 'n' },
            callout = { 'n' },
            check_icon = { 'n' },
            check_scope = { 'n' },
            code_language = { 'n' },
            dash = { 'n' },
            head_icon = { 'n' },
            link = { 'n' },
            quote = { 'n' },
            table_border = { 'n' },
        },
    },
    dash = {
        width = 80,
    },
    heading = {
        sign = false,
        icons = { '󰪥 ', '󰺕 ', ' ', ' ', ' ', '' },
        position = 'inline',
    },
    bullet = {
        icons = { '', '•', '', '-', '-' },
    },
    checkbox = {
        unchecked = { icon = '' },
        checked = { icon = '', scope_highlight = '@markup.strikethrough' },
        custom = {
            doing = {
                raw = '[_]',
                rendered = '󰄮',
                highlight = 'RenderMarkdownDoing',
            },
            wontdo = {
                raw = '[~]',
                rendered = '󰅗',
                highlight = 'RenderMarkdownWontdo',
            },
        },
    },
    code = {
        sign = false,
        width = 'block',
        border = 'thick',
        min_width = 80,
        highlight_language = 'LineNr',
        language_name = false,
    },
    quote = { icon = '▐' },
    pipe_table = { cell = 'raw' },
    link = {
        wiki = { icon = '󱗖 ', highlight = 'RenderMarkdownWikiLink' },
        custom = {
            gdrive = {
                pattern = 'drive%.google%.com/drive',
                icon = ' ',
            },
            spreadsheets = {
                pattern = 'docs%.google%.com/spreadsheets',
                icon = '󰧷 ',
            },
            document = {
                pattern = 'docs%.google%.com/document',
                icon = '󰈙 ',
            },
            presentation = {
                pattern = 'docs%.google%.com/presentation',
                icon = '󰈩 ',
            },
        },
    },
    latex = { enabled = false },
})
