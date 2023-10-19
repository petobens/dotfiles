local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

local p = extras.partial
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Editing
    s(
        { trig = '(%d)h', regTrig = true, dscr = 'Header' },
        fmta(
            [[
               <> <>
            ]],
            {
                f(function(_, snip)
                    return string.rep('#', snip.captures[1])
                end, {}),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ti', dscr = 'Italics' },
        fmta(
            [[
        _<><>_
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'tb', dscr = 'Bold' },
        fmta(
            [[
        **<><>**
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'st', dscr = 'Strikethrough' },
        fmta(
            [[
        ~~<><>~~
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'bq', dscr = 'Block quotes' },
        fmta(
            [[
        >> <><>
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ic', dscr = 'Inline code' },
        fmta(
            [[
        `<><>`
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'bc', dscr = 'Block code' },
        fmta(
            [[
        ```<>
        <><>
        ```
    ]],
            {
                c(1, { sn(nil, { i(1, 'language') }), t('') }),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ite', dscr = 'Itemize' },
        fmta(
            [[
        <item_marker> <>
        <> <>
    ]],
            {
                item_marker = c(1, { t('-'), t('*') }),
                i(2),
                rep(1),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cb', dscr = 'Checkbox' },
        fmta(
            [[
        <> [<>] <>
    ]],
            {
                c(1, { t('-'), t('*') }),
                c(2, { t(''), t('x') }),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'enu', dscr = 'Enumerate' },
        fmta(
            [[
        1. <>
        2. <>
    ]],
            {
                i(1),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'il', dscr = 'Inline link' },
        fmta(
            [[
                [<>](<><>)
            ]],
            {
                i(1),
                i(2),
                f(_G.LuaSnipConfig.visual_selection),
            }
        )
    ),
    s(
        { trig = 'fig', dscr = 'Figure' },
        fmta(
            [[
                ![<>](<><>)<>
            ]],
            {
                i(1, 'caption'),
                i(2),
                f(_G.LuaSnipConfig.visual_selection),
                i(3),
            }
        )
    ),
    s(
        { trig = 'mld', dscr = 'Markdowlint disable' },
        fmta(
            [[
                <<!-- markdownlint-disable MD0<> -->>
            ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),

    -- Pandoc
    s(
        { trig = 'ph', dscr = 'Pandoc Header' },
        fmta(
            [[
                ---
                fontsize: 12pt
                geometry: margin=3cm

                title: <>
                author:
                    - <>
                ---
                <<!-- markdownlint-disable MD025 -->>
            ]],
            {
                i(1),
                i(2, 'Pedro Ferrari'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'eq', dscr = 'Equation' },
        fmta(
            [[
        $$
        <><>
        $$
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        ),
        { condition = line_begin }
    ),

    -- Tables
    s(
        { trig = '(%d)c', regTrig = true, dscr = 'Columns' },
        fmta(
            [[
               <>
            ]],
            {
                d(1, function(_, snip)
                    local nodes = {}
                    local nr_cols = snip.captures[1]
                    for j = 1, nr_cols do
                        table.insert(nodes, t('| '))
                        table.insert(nodes, i(j))
                        table.insert(nodes, t(' '))
                    end
                    table.insert(nodes, t({ '|', '' }))
                    return sn(nil, nodes)
                end),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = '(%d)x(%d)', regTrig = true, dscr = 'Rows x columns' },
        fmta(
            [[
               <>
            ]],
            {
                d(1, function(_, snip)
                    local nodes = {}
                    local nr_rows = snip.captures[1]
                    local nr_cols = snip.captures[2]
                    local idx = 0

                    local hlines = ''
                    for _ = 1, nr_cols do
                        idx = idx + 1
                        table.insert(nodes, t('| '))
                        table.insert(nodes, i(idx))
                        table.insert(nodes, t(' '))
                        hlines = hlines .. '|-----'
                    end
                    table.insert(nodes, t({ '|', '' }))
                    hlines = hlines .. '|'
                    table.insert(nodes, t({ hlines, '' }))

                    for _ = 1, nr_rows do
                        for _ = 1, nr_cols do
                            idx = idx + 1
                            table.insert(nodes, t('| '))
                            table.insert(nodes, i(idx))
                            table.insert(nodes, t(' '))
                        end
                        table.insert(nodes, t({ '|', '' }))
                    end
                    return sn(nil, nodes)
                end),
            }
        ),
        { condition = line_begin }
    ),

    -- Note-taking
    s(
        { trig = 'cd', dscr = 'Current Date' },
        fmta(
            [[
                <>
            ]],
            {
                p(os.date, '%d/%m/%Y'),
            }
        )
    ),
}, {
    s({ trig = '``', wordTrig = false, dscr = 'Inline code' }, {
        t('`'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('`'),
        i(0),
    }),
    s({ trig = '$$', wordTrig = false, dscr = 'Inline math' }, {
        t('$'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('$'),
        i(0),
    }),
    s({ trig = 'db', wordTrig = false, dscr = 'Wiki Link' }, {
        t('[['),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t(']]'),
        i(0),
    }),
}
