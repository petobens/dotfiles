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
    -- Math Operators & Notation
    s(
        { trig = 'frac', wordTrig = false, dscr = 'Fraction' },
        fmta(
            [[
        \frac{<><>}{<>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'nom'),
                i(2, 'denom'),
            }
        )
    ),
    s(
        { trig = 'sum', dscr = 'Sum or Product' },
        fmta(
            [[
        \<>_{<>}<> <>
    ]],
            {
                c(1, { sn(nil, { i(1, 'sum') }), t('prod') }),
                i(2, 't=1'),
                c(3, { sn(nil, { t('^{'), i(1, '\\infty'), t('}') }), t('') }),
                f(_G.LuaSnipConfig.visual_selection),
            }
        )
    ),
    s(
        { trig = 'lim', dscr = 'Limit' },
        fmta(
            [[
        \lim_{<> \to <>}
    ]],
            {
                i(1),
                i(2),
            }
        )
    ),
    s(
        { trig = 'pd', dscr = 'Partial derivative' },
        fmta(
            [[
        \frac{\partial <><>}{\partial <>}
    ]],
            {
                i(1),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        )
    ),
    s(
        { trig = 'int', dscr = 'Integral' },
        fmta(
            [[
        \int<>\!<>\,\d <>
    ]],
            {
                c(1, {
                    sn(
                        nil,
                        { t('_{'), i(1, 'inf'), t('}'), t('^{'), i(2, 'sup'), t('}') }
                    ),
                    t(''),
                }),
                i(2, 'function'),
                i(3, 'variable'),
            }
        )
    ),
    s(
        { trig = 'sr', dscr = 'Square root' },
        fmta(
            [[
        \sqrt<>{<><>}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'n != 2'), t(']') }), t('') }),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        )
    ),
    s(
        { trig = 'nor', dscr = 'Norm' },
        fmta(
            [[
        \norm{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'abv', dscr = 'Absolute value' },
        fmta(
            [[
        \abs{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'log', dscr = 'Log' },
        fmta(
            [[
        \log{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'ln', dscr = 'Natural log' },
        fmta(
            [[
        \ln{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'ol', wordTrig = false, dscr = 'Overline' },
        fmta(
            [[
        \overline{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'ul', wordTrig = false, dscr = 'Underline' },
        fmta(
            [[
        \overline{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'ob', dscr = 'Overbrace' },
        fmta(
            [[
        \overbrace{<><>}^{<>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
                i(2),
            }
        )
    ),
    s(
        { trig = 'ub', dscr = 'Underbrace' },
        fmta(
            [[
        \underbrace{<><>}_{<>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
                i(2),
            }
        )
    ),
    s(
        { trig = 'os', dscr = 'Overset' },
        fmta(
            [[
        \overset{<>}{<><>}
    ]],
            {
                i(1, 'text'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'symbol'),
            }
        )
    ),
    s(
        { trig = 'us', dscr = 'Underset' },
        fmta(
            [[
        \underset{<>}{<><>}
    ]],
            {
                i(1, 'text'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'symbol'),
            }
        )
    ),
    s(
        { trig = 'bar', dscr = 'Bar' },
        fmta(
            [[
        \bar{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'hat', dscr = 'Hat' },
        fmta(
            [[
        \hat{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'til', dscr = 'Tilde' },
        fmta(
            [[
        \tilde{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'dot', dscr = 'Dot' },
        fmta(
            [[
        \dot{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'cdot', wordTrig = false, dscr = 'cdot' },
        fmta(
            [[
        \cdot
    ]],
            {}
        )
    ),
    s(
        { trig = 'set', dscr = 'Set' },
        fmta(
            [[
        \{\, <><> \}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'vec', wordTrig = false, dscr = 'Vector' },
        fmta(
            [[
        (<>_{1}, <>_{2}, \ldots, <>_{<>})
    ]],
            {
                i(1),
                rep(1),
                rep(1),
                i(2, 'N'),
            }
        )
    ),
    s(
        { trig = 'seq', wordTrig = false, dscr = 'Sequence' },
        fmta(
            [[
        <>_{1}, <>_{2}, \ldots, <>_{<>}
    ]],
            {
                i(1),
                rep(1),
                rep(1),
                i(2, 'N'),
            }
        )
    ),
    s(
        { trig = 'map', dscr = 'Map' },
        fmta(
            [[
        <>\colon <> \to <>
    ]],
            {
                i(1, 'f'),
                i(2, 'X'),
                i(3, 'Y'),
            }
        )
    ),

    -- Economics
    s(
        { trig = 'fco', dscr = 'First order conditions' },
        fmta(
            [[
      \begin{alignat}{2}
        (<>) &:\quad & <> & = <> <label1>\\
        (<>) &:\quad & <> & = <> <label2>
      \end{alignat}
    ]],
            {
                i(1),
                i(2),
                i(3),
                label1 = c(4, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                i(5),
                i(6),
                i(7),
                label2 = c(8, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
            }
        ),
        { condition = line_begin }
    ),
}, {
    s({ trig = '$$', wordTrig = false, dscr = 'Inline math' }, {
        t('$'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('$'),
        i(0),
    }),
    s({ trig = '__', wordTrig = false, dscr = 'Subindex' }, {
        t('_{'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('}'),
        i(0),
    }),
    s({ trig = '^&', wordTrig = false, dscr = 'Superindex' }, {
        t('^{'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('}'),
        i(0),
    }),
}
