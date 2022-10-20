local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local sn = ls.snippet_node
local c = ls.choice_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep

local selected_text = function(_, snip)
    return snip.env.TM_SELECTED_TEXT or {}
end

return {
    -- Preamble
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
    s(
        { trig = 'sss', dscr = 'Subsection' },
        fmta(
            [[
                \subsubsection{<>}
                \label{ssub:<>}

                <>
            ]],
            {
                i(1, 'subsubsection name'),
                rep(1),
                i(0),
            }
        )
    ),

    -- Editing/Fonts
    s(
        { trig = 'ti', dscr = 'Textit' },
        fmta(
            [[
        \textit{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),
    s(
        { trig = 'tb', dscr = 'Text bold' },
        fmta(
            [[
        \textbf{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),
    s(
        { trig = 'mcg', dscr = 'Math caligraphic' },
        fmta(
            [[
        \mathcal{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),
    s(
        { trig = 'mbb', dscr = 'Math blackboard' },
        fmta(
            [[
        \mathbb{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),
    s(
        { trig = 'mi', dscr = 'Math italic' },
        fmta(
            [[
        \mathit{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),
    s(
        { trig = 'mr', dscr = 'Math roman' },
        fmta(
            [[
        \mathrm{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),

    -- Lists
    s(
        { trig = 'enu', dscr = 'Enumerate' },
        fmta(
            [[
      \begin{enumerate}<>
        \item <>
      \end{enumerate}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, '(i)'), t(']') }), t('') }),
                i(2),
            }
        )
    ),
    s(
        { trig = 'ite', dscr = 'Itemize' },
        fmta(
            [[
      \begin{itemize}
        \item <>
      \end{itemize}
    ]],
            {
                i(1),
            }
        )
    ),

    -- Math Environments
    s(
        { trig = 'equ', dscr = 'Equation' },
        fmta(
            [[
      \begin{equation}
      \label{eq:<>}
        <><>
      \end{equation}
    ]],
            {
                f(selected_text, {}),
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
        <><>
      \end{equation*}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),

    -- Math Operators
    s(
        { trig = 'frac', dscr = 'Fraction' },
        fmta(
            [[
        \frac{<><>}{<>}
    ]],
            {
                f(selected_text, {}),
                i(1, 'nom'),
                i(2, 'denom'),
            }
        )
    ),
    s(
        { trig = 'sum', dscr = 'Sum' },
        fmta(
            [[
        \sum_{<>}<> <>
    ]],
            {
                i(1, 't=1'),
                c(2, { sn(nil, { t('^{'), i(1, '\\infty'), t('}') }), t('') }),
                f(selected_text, {}),
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
                f(selected_text, {}),
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
                f(selected_text, {}),
                i(1),
            }
        )
    ),

    -- References
    s(
        { trig = 'fn', wordTrig = false, dscr = 'Footnote' },
        fmta(
            [[
        \footnote{<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'lab', dscr = 'Label' },
        fmta(
            [[
        \label{<><>}
    ]],
            {
                f(selected_text, {}),
                i(1),
            }
        )
    ),
    s(
        { trig = 'cre', dscr = 'Cleveref equation' },
        fmta(
            [[
        \cref{eq:<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'crt', dscr = 'Cleveref table' },
        fmta(
            [[
        \cref{tab:<>}
    ]],
            {
                i(1),
            }
        )
    ),

    -- Citations
    s(
        { trig = 'tc', wordTrig = false, dscr = 'Textcite' },
        fmta(
            [[
        \textcite{<>}
    ]],
            {
                i(1),
            }
        )
    ),
},
    {
        s({ trig = '$$', wordTrig = false, dscr = 'Inline math' }, {
            t('$'),
            f(selected_text, {}),
            i(1),
            t('$'),
            i(0),
        }),
        s({ trig = '__', wordTrig = false, dscr = 'Subindex' }, {
            t('_{'),
            f(selected_text, {}),
            i(1),
            t('}'),
            i(0),
        }),
        s({ trig = '^&', wordTrig = false, dscr = 'Superindex' }, {
            t('^{'),
            f(selected_text, {}),
            i(1),
            t('}'),
            i(0),
        }),
    }
