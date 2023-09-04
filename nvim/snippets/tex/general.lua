local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local rep = extras.rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Preamble
    s(
        { trig = 'mwe', dscr = 'MWE template' },
        fmta(
            [[
\documentclass{<>}
\begin{document}
    <>
\end{document}
]],
            {
                i(1, 'article'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
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
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'env', dscr = 'Generic environment' },
        fmta(
            [[
      \begin{<>}
        <><>
      \end{<>}
    ]],
            {
                i(1, 'env_name'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
                rep(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cmd', dscr = 'Generic cmd' },
        fmta(
            [[
        \<>{<><>}
    ]],
            {
                i(1),
                i(2),
                f(_G.LuaSnipConfig.visual_selection),
            }
        )
    ),

    -- Section environments
    s(
        { trig = 'part', dscr = 'Part' },
        fmta(
            [[
                \part{<>}
                \label{part:<>}

                <>
            ]],
            {
                i(1, 'part name'),
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cha', dscr = 'Chapter' },
        fmta(
            [[
                \chapter{<>}
                \label{cha:<>}

                <>
            ]],
            {
                i(1, 'chapter name'),
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
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
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                i(0),
            }
        ),
        { condition = line_begin }
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
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                i(0),
            }
        ),
        { condition = line_begin }
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
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Lists
    s(
        { trig = 'enu', dscr = 'Enumerate' },
        fmta(
            [[
      \begin{enumerate}<>
        \item <><>
      \end{enumerate}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, '(i)'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ite', dscr = 'Itemize' },
        fmta(
            [[
      \begin{itemize}
        \item <><>
      \end{itemize}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ste', dscr = 'Steps' },
        fmta(
            [[
      \begin{steps}
        \item <><>
      \end{steps}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
}, {}
