local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Parser
    s(
        { trig = 'mdt', dscr = '[M]yST [d]irec[t]ive' },
        fmta(
            [[
            :::{<>}
            <>
            :::
        ]],
            {
                i(1, 'directive'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mtc', dscr = '[M]yST [T]O[C]' },
        fmta(
            [[
            :::{toctree}<><>

            <>
            :::
        ]],
            {
                c(1, { sn(nil, { t({ '', '' }), i(1, ':hidden:') }), t('') }),
                c(2, { sn(nil, { t({ '', '' }), i(1, ':caption: '), i(1) }), t('') }),
                i(3),
            }
        ),
        { condition = line_begin }
    ),

    -- Text
    s(
        { trig = 'mfn', wordTrig = false, dscr = '[M]yST [f]oot[n]ote' },
        fmta(
            [[
        [^<>]

        [^<>]: <>
    ]],
            {
                i(1),
                rep(1),
                i(2),
            }
        )
    ),

    -- Math
    s(
        { trig = 'mlb', dscr = '[M]yST [l]a[b]el' },
        fmta(
            [[
            (<>)
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'mer', dscr = '[M]yST [e]quation [r]eference' },
        fmta(
            [[
        {eq}`eq:<>`
    ]],
            {
                i(1),
            }
        )
    ),

    -- Figures
    s(
        { trig = 'mfig', dscr = '[M]yST [fig]ure' },
        fmta(
            [[
            :::{figure} <>
            :scale: <>%
            :align: center

            <>
            :::
        ]],
            {
                i(1, 'path'),
                i(2),
                i(3, 'caption'),
            }
        ),
        { condition = line_begin }
    ),
}, {}
