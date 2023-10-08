local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

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
                c(2, { t('X'), t('') }),
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
        { trig = 'url', dscr = 'Link' },
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
}, {
    s({ trig = '``', wordTrig = false, dscr = '<>' }, {
        t('`'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('`'),
        i(0),
    }),
    s({ trig = '$$', wordTrig = false, dscr = '<>' }, {
        t('$'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('$'),
        i(0),
    }),
}
