local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local sn = ls.snippet_node
local c = ls.choice_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep

return {
    s(
        { trig = 'up', dscr = 'Use package' },
        fmta(
            [[
        \usepackage<>{<>}
      ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'options'), t(']') }), t('') }),
                i(2, 'name'),
            }
        )
    ),
    -- Environments
    s(
        { trig = 'beg', dscr = 'Begin environment' },
        fmta(
            [[
      \begin{<>}
          <>
      \end{<>}
    ]],
            {
                i(1),
                i(2),
                rep(1),
            }
        )
    ),

    -- Sections
    s(
        { trig = 'sec', dscr = 'Section' },
        fmta(
            [[
                \section{<>}
                \label{sec:<>}

                <>
            ]],
            {
                i(1, 'section name'),
                rep(1),
                i(0),
            }
        )
    ),
    s(
        { trig = 'ss', dscr = 'Subsection' },
        fmta(
            [[
                \subsection{<>}
                \label{sub:<>}

                <>
            ]],
            {
                i(1, 'subsection name'),
                rep(1),
                i(0),
            }
        )
    ),

    -- Math
    s(
        { trig = 'equ', dscr = 'Equation' },
        fmta(
            [[
      \begin{equation}
      \label{eq:<>}
          <>
      \end{equation}
    ]],
            {
                i(1, 'label'),
                i(2),
            }
        )
    ),
    s(
        { trig = 'ueq', dscr = 'Unnumbered equation' },
        fmta(
            [[
      \begin{equation*}
          <>
      \end{equation*}
    ]],
            {
                i(1),
            }
        )
    ),
},
    {}
