local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Operators and functions
    s(
        { trig = 'frac', wordTrig = false, dscr = 'Fraction' },
        fmta('frac(<><>, <>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'numerator'),
            i(2, 'denominator'),
            i(0),
        })
    ),
    s(
        { trig = 'sum', dscr = 'Sum or product' },
        fmta('<>_(<>)^(<>) <><>', {
            c(1, { t('sum'), t('product') }),
            i(2, 't = 1'),
            i(3, 'oo'),
            f(_G.LuaSnipConfig.visual_selection),
            i(0),
        })
    ),
    s(
        { trig = 'lim', dscr = 'Limit' },
        fmta('lim_(<> arrow.r <>) <>', {
            i(1, 'x'),
            i(2, 'oo'),
            i(0),
        })
    ),
    s(
        { trig = 'pd', dscr = 'Partial derivative' },
        fmta('frac(partial <><>, partial <>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'f'),
            i(2, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'int', dscr = 'Integral' },
        fmta('integral<> <><> upright(d) <><>', {
            c(1, {
                sn(nil, { t('_('), i(1, 'a'), t(')^('), i(2, 'b'), t(')') }),
                t(''),
            }),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, 'f(x)'),
            i(3, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'sr', dscr = 'Square root' },
        c(1, {
            sn(nil, {
                t('sqrt('),
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'x'),
                t(')'),
            }),
            sn(nil, {
                t('root('),
                i(1, 'n'),
                t(', '),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'x'),
                t(')'),
            }),
        })
    ),
    s(
        { trig = 'nor', dscr = 'Norm' },
        fmta('norm(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'abv', dscr = 'Absolute value' },
        fmta('abs(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'log', dscr = 'Logarithm' },
        fmta('log(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'ln', dscr = 'Natural logarithm' },
        fmta('ln(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),

    -- Decorations and annotations
    s(
        { trig = 'ol', wordTrig = false, dscr = 'Overline' },
        fmta('overline(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'ul', wordTrig = false, dscr = 'Underline' },
        fmta('underline(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'ob', dscr = 'Overbrace' },
        fmta('overbrace(<><>, <>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'expression'),
            i(2, 'annotation'),
            i(0),
        })
    ),
    s(
        { trig = 'ub', dscr = 'Underbrace' },
        fmta('underbrace(<><>, <>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'expression'),
            i(2, 'annotation'),
            i(0),
        })
    ),
    s(
        { trig = 'os', dscr = 'Overset' },
        fmta('attach(<><>, t: <>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'symbol'),
            i(2, 'annotation'),
            i(0),
        })
    ),
    s(
        { trig = 'us', dscr = 'Underset' },
        fmta('attach(<><>, b: <>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'symbol'),
            i(2, 'annotation'),
            i(0),
        })
    ),
    s(
        { trig = 'bar', dscr = 'Bar' },
        fmta('macron(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'hat', dscr = 'Hat' },
        fmta('hat(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'til', dscr = 'Tilde' },
        fmta('tilde(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'dot', dscr = 'Dot' },
        fmta('dot(<><>)<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s({ trig = 'cdot', wordTrig = false, dscr = 'Centered dot' }, t('dot.op')),

    -- Common structures
    s(
        { trig = 'set', dscr = 'Set' },
        fmta('{ <><> }<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'x'),
            i(0),
        })
    ),
    s(
        { trig = 'vec', wordTrig = false, dscr = 'Vector' },
        fmta('(<>_1, <>_2, dots.h, <>_(<>))<>', {
            i(1, 'x'),
            rep(1),
            rep(1),
            i(2, 'N'),
            i(0),
        })
    ),
    s(
        { trig = 'seq', wordTrig = false, dscr = 'Sequence' },
        fmta('<>_1, <>_2, dots.h, <>_(<>)<>', {
            i(1, 'x'),
            rep(1),
            rep(1),
            i(2, 'N'),
            i(0),
        })
    ),
    s(
        { trig = 'map', dscr = 'Map' },
        fmta('<> : <> arrow.r <><>', {
            i(1, 'f'),
            i(2, 'X'),
            i(3, 'Y'),
            i(0),
        })
    ),
}, {
    -- Inline math and scripts
    s({ trig = '$$', wordTrig = false, dscr = 'Inline math' }, {
        t('$'),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t('$'),
        i(0),
    }),
    s({ trig = '__', wordTrig = false, dscr = 'Subscript' }, {
        t('_('),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t(')'),
        i(0),
    }),
    s({ trig = '^&', wordTrig = false, dscr = 'Superscript' }, {
        t('^('),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
        t(')'),
        i(0),
    }),
}
