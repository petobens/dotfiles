-- Setup
require('render-markdown').setup({
    enabled = true,
    file_types = { 'markdown', 'codecompanion' },
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
        language_border = '',
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
    html = { comment = { conceal = false } },
    on = {
        render = function(ctx)
            local is_lsp_float =
                pcall(vim.api.nvim_win_get_var, ctx.win, 'lsp_floating_bufnr')
            if is_lsp_float then
                _G.LspConfig.highlight_doc_patterns(ctx.buf)
            end
        end,
    },
    overrides = {
        filetype = {
            -- CodeCompanion
            codecompanion = {
                heading = {
                    icons = { '󰪥 ', '  ', ' ', ' ', ' ', '' },
                    custom = {
                        codecompanion_input = {
                            pattern = '^## Me$',
                            icon = ' ',
                            background = 'CodeCompanionInputHeader',
                        },
                    },
                },
                html = {
                    tag = {
                        buf = {
                            icon = '󰌹 ',
                            highlight = 'Comment',
                        },
                        file = {
                            icon = '󰨸 ',
                            highlight = 'Comment',
                        },
                        gdoc = {
                            icon = '󰈙 ',
                            highlight = 'Comment',
                        },
                        gsheet = {
                            icon = '󰧷 ',
                            highlight = 'Comment',
                        },
                        gslides = {
                            icon = '󰈩 ',
                            highlight = 'Comment',
                        },
                        group = {
                            icon = ' ',
                            highlight = 'Comment',
                        },
                        help = {
                            icon = ' ',
                            highlight = 'Comment',
                        },
                        image = {
                            icon = '󰥶 ',
                            highlight = 'Comment',
                        },
                        rules = {
                            icon = ' ',
                            highlight = 'Comment',
                        },
                        tmux = {
                            icon = ' ',
                            highlight = 'Comment',
                        },
                        tool = {
                            icon = ' ',
                            highlight = 'Comment',
                        },
                        url = {
                            icon = ' ',
                            highlight = 'Comment',
                        },
                    },
                },
            },
        },
    },
})
