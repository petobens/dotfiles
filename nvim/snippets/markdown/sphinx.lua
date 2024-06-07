local ls = require('luasnip')

local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Docs
    s(
        { trig = 'stc', dscr = 'Sphinx TOC' },
        fmta(
            [[
            ```{toctree}<><>

            <>
            ```
        ]],
            {
                c(1, { sn(nil, { t({ '', '' }), i(1, ':hidden:') }), t('') }),
                c(2, { sn(nil, { t({ '', '' }), i(1, ':caption: '), i(1) }), t('') }),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ser', dscr = 'Sphinx eval-rst' },
        fmta(
            [[
            ```{eval-rst}
            .. <>:: <>

               <>
            ```
        ]],
            {
                i(1, 'directive'),
                i(2, 'value'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'sam', dscr = 'Sphinx automodule' },
        fmta(
            [[
            ```{eval-rst}
            .. automodule:: <>
            ```
        ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    -- Math
    s(
        { trig = 'le', dscr = 'Label equation' },
        fmta(
            [[
            (eq:<>)
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
}, {}
