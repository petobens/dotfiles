local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local rep = extras.rep
local postfix = require('luasnip.extras.postfix').postfix
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'mwe', dscr = 'MWE template' },
        fmta(
            [[
\documentclass{<>}
\begin{document}
<><>
\end{document}
]],
            {
                i(1, 'article'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    -- Preamble
    s(
        { trig = 'ip', dscr = 'Input' },
        fmta(
            [[
        \input{<>}
    ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ic', dscr = 'Include' },
        fmta(
            [[
        \include{<>}
    ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'io', dscr = 'Includeonly' },
        fmta(
            [[
        \includeonly{<>}
    ]],
            {
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'up', dscr = 'Use package' },
        fmta(
            [[
        \usepackage<>{<name>}
      ]],
            {
                name = i(1),
                c(2, { sn(nil, { t('['), i(1, 'options'), t(']') }), t('') }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'nc', dscr = 'New command' },
        fmta(
            [[
                \<>newcommand*{\<>}<>{\<>}
            ]],
            {
                c(1, { t(''), t('re') }),
                i(2, 'new_cmd'),
                c(3, { sn(nil, { t('['), i(1, 'nr_args>1'), t(']') }), t('') }),
                i(4, 'real_cmd'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ne', dscr = 'New environment' },
        fmta(
            [[
                \newenvironment*{<>}<>
                  {<>}<>
            ]],
            {
                i(1, 'name'),
                c(2, { sn(nil, { t('['), i(1, 'nr_args>1'), t(']') }), t('') }),
                i(3, 'before'),
                c(4, { sn(nil, { t({ '', '  {' }), i(1, 'after'), t('}') }), t('') }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dmo', dscr = 'Declare math operator' },
        fmta(
            [[
                \DeclareMathOperator*{\<>}{<>}
            ]],
            {
                i(1, 'new_operator'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),

    -- Environments & Commands
    s(
        { trig = 'env', dscr = 'Generic environment' },
        fmta(
            [[
      \begin{<>}
        <><>
      \end{<>}
    ]],
            {
                i(1),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
                rep(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'end', dscr = 'End environment' },
        fmta(
            [[
            \end{<>}
        ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'cmd', dscr = 'Generic cmd' },
        fmta(
            [[
        \<><>
    ]],
            {
                i(1),
                c(2, {
                    sn(
                        nil,
                        { t('{'), f(_G.LuaSnipConfig.visual_selection), i(1), t('}') }
                    ),
                    t(''),
                }),
            }
        )
    ),
    postfix({ trig = 'kk', snippetType = 'autosnippet', dscr = 'Postfix cmd' }, {
        d(1, function(_, parent)
            return sn(nil, {
                t('\\' .. parent.env.POSTFIX_MATCH),
                c(1, {
                    sn(
                        nil,
                        { t('{'), f(_G.LuaSnipConfig.visual_selection), i(1), t('}') }
                    ),
                    t(''),
                }),
            })
        end),
    }),

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
    -- Linting
    s(
        { trig = 'ctd', dscr = 'Chktex disable' },
        fmta(
            [[
            % chktex <>
        ]],
            { i(1) }
        )
    ),
}, {
    s({ trig = 'itm', wordTrig = false, dscr = '\\item' }, {
        t('\\item '),
        f(_G.LuaSnipConfig.visual_selection),
        i(1),
    }),
}
