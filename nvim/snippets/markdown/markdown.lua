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
        { trig = 'cb', dscr = 'Code block' },
        fmta(
            [[
        ```<>
        <><>
        ```

    ]],
            {
                c(1, { sn(nil, { i(1, 'python') }), t('') }),
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
        { trig = 'tl', dscr = 'Todo List' },
        fmta(
            [[
        - [ ] To-Do <>
          - [ ] <>
    ]],
            {
                p(os.date, '%d/%m/%Y'),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'il', dscr = 'Inline link' },
        fmta(
            [[
                [<>](#<><>)
            ]],
            {
                i(1),
                i(2),
                f(_G.LuaSnipConfig.visual_selection),
            }
        )
    ),
    s(
        { trig = 'url', dscr = 'Url' },
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
    s({ trig = 'wl', dscr = 'Wiki Link' }, {
        t('[['),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t(']]'),
        i(0),
    }),
    s(
        { trig = 'fig', dscr = 'Figure' },
        fmta(
            [[
                ![<>](<><>)<>
            ]],
            {
                i(1),
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
        { trig = 'fm', dscr = 'Front matter' },
        fmta(
            [[
                ---
                fontsize: 12pt
                geometry: margin=3cm

                title: <>
                author: <>
                date: <>
                ---
            ]],
            {
                i(1),
                i(2, 'Pedro Ferrari'),
                p(os.date, '%d/%m/%Y'),
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
        { trig = '(%d)c', regTrig = true, dscr = 'Columns', docTrig = '3c' },
        fmta(
            [[
               <>
            ]],
            {
                d(1, function(_, snip)
                    local nodes = {}
                    local nr_cols = tonumber(snip.captures[1])
                    if not nr_cols then
                        return
                    end
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
        { trig = '(%d)x(%d)', regTrig = true, dscr = 'Rows x columns', docTrig = '2x3' },
        fmta(
            [[
               <>
            ]],
            {
                d(1, function(_, snip)
                    local nodes = {}
                    local nr_rows = tonumber(snip.captures[1])
                    local nr_cols = tonumber(snip.captures[2])
                    if not nr_cols then
                        return
                    end
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
    s(
        { trig = 'cD', dscr = 'Current Date - Format' },
        fmta(
            [[
                <>
            ]],
            {
                p(os.date, '%Y-%m-%d'),
            }
        )
    ),
    s(
        { trig = 'co', dscr = 'Callout' },
        fmta(
            [[
        >> [!<>]
        >>
        >> <><>
    ]],
            {
                i(1, 'NOTE'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
}, {
    s(
        { trig = '(%d)h', regTrig = true, dscr = 'Header', docTrig = '2h' },
        fmta(
            [[
               <> <>
            ]],
            {
                f(function(_, snip)
                    local count = tonumber(snip.captures[1])
                    if not count then
                        return
                    end
                    return string.rep('#', count)
                end, {}),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = '--', dscr = 'Checkbox' },
        fmta(
            [[
        - [ ] <>
    ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s({ trig = '``', wordTrig = false, dscr = 'Inline code' }, {
        t('`'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('`'),
        i(0),
    }),
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
    s({ trig = '$$', wordTrig = false, dscr = 'Inline math' }, {
        t('$'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('$'),
        i(0),
    }),
}
