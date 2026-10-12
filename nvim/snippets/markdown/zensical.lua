local ls = require('luasnip')

local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Blocks
    s(
        { trig = 'zad', dscr = '[Z]ensical [ad]monition' },
        fmta(
            [[
            !!! <>

                <>
        ]],
            {
                i(1, 'note'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'zcd', dscr = '[Z]ensical [c]ollapsible [d]etails' },
        fmta(
            [[
            ??? <>

                <>
        ]],
            {
                i(1, 'note'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ztb', dscr = '[Z]ensical [t]a[b]' },
        fmta(
            [[
            === "<>"

                <>
        ]],
            {
                i(1, 'title'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),

    -- Math
    s(
        { trig = 'zeq', dscr = '[Z]ensical numbered [eq]uation' },
        fmta(
            [[
            $$
            \begin{equation}
            \label{eq:<>}
            <>
            \end{equation}
            $$
        ]],
            {
                i(1),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'zer', dscr = '[Z]ensical [e]quation [r]eference' },
        fmta(
            [[
        $\eqref{eq:<>}$
    ]],
            {
                i(1),
            }
        )
    ),
}, {}
