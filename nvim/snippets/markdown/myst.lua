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
        { trig = 'mdt', dscr = 'MyST directive' },
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
        { trig = 'mtc', dscr = 'MyST TOC' },
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
        { trig = 'fn', wordTrig = false, dscr = 'Footnote' },
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
        { trig = 'lb', dscr = 'Label' },
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
        { trig = 'cre', dscr = 'Equation ref' },
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
        { trig = 'mfig', dscr = 'MyST figure' },
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
