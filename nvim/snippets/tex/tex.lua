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
local m = extras.match
local rep = extras.rep
local line_begin = require('luasnip.extras.expand_conditions').line_begin

-- Functions
local snake_case_labels = function(node_idx)
    local str = node_idx[1][1]
    local unicode_map = {
        ['á'] = 'a',
        ['Á'] = 'A',
        ['é'] = 'e',
        ['É'] = 'E',
        ['í'] = 'i',
        ['Í'] = 'I',
        ['ó'] = 'o',
        ['Ó'] = 'O',
        ['ú'] = 'u',
        ['Ú'] = 'U',
        ['ñ'] = 'ni',
    }
    for k, v in pairs(unicode_map) do
        str = str:gsub(k, v)
    end
    -- Remove punctuation marks, lowercase and replace spaces with underscores
    str = str:gsub('[%p]', ''):lower():gsub('%s+', '_')
    return str:sub(1, 35)
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

    -- Article class
    s(
        { trig = 'tp', dscr = 'Titlepage' },
        fmta(
            [[
% Custom titlepage
\newcommand*{\maketitlepg}{%
  \renewcommand{\thepage}{\roman{page}}
  \begingroup
    \begin{center}
      \includegraphics[scale=0.03]{<logo_fn>}
    \end{center}
	\vspace{0.01\textheight}
	\begin{center}
	  \bfseries\LARGE{<institution>}\\
	  \vspace{0.02\textheight}
	  \textbf{\Large{<department>}}\\
	  \vspace{0.3\textheight}
	  \rule{\textwidth}{1.5pt}\par
	  \vspace{\baselineskip}
	  \bfseries\Huge{<title>}\par
	  \bigskip\Large{--- <subtitle> ---}\\
	  \vspace{\baselineskip}
	  \rule{\textwidth}{1.5pt}\par
      \vfill
      \textsc{\huge{<author>}}
      \vfill
	  \textbf{\Large{<date>}}
	 \end{center}
	\endgroup
	\thispagestyle{empty}\cleardoublepage
	\renewcommand{\thepage}{\arabic{page}}
	\setcounter{page}{1}
}
            ]],
            {
                logo_fn = i(1, 'logo_mutt.png'),
                institution = i(2, 'institution'),
                department = i(3, 'department'),
                title = i(4, 'title'),
                subtitle = i(5, 'subtitle'),
                author = i(6, 'author'),
                date = i(7, 'date'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'tha', dscr = 'Thanks' },
        fmta(
            [[
        \thanks{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'abs', dscr = 'Abstract' },
        fmta(
            [[
\begin{abstract}
    <>
\medskip
\keywords{<>}<>
\end{abstract}
    ]],
            {
                i(1, '\\lipsum[1]'),
                i(2),
                c(3, {
                    sn(nil, { t({ '', [[\jel{]] }), i(1, [[jel_codes]]), t('}') }),
                    t(''),
                }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'aa', dscr = 'Article appendix' },
        fmta(
            [[
                % Appendix
                \appheading
                \appendix
            ]],
            {}
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pt', dscr = 'Points (for exercises)' },
        fmta(
            [[
        \points{<>}
    ]],
            {
                i(1, 'number of points'),
            }
        )
    ),

    -- Beamer
    s(
        { trig = 'bf', dscr = 'Beamer frame' },
        fmta(
            [[
                \begin{frame}[<>]
                \frametitle{<>}
                  <><>
                \end{frame}
            ]],
            {
                c(1, { sn(nil, { i(1, 'fragile=singleslide') }), t('allowframebreaks') }),
                i(2, 'title'),
                isn(3, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ft', dscr = 'Frame title' },
        fmta(
            [[
        \frametitle{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'title'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'fs', dscr = 'Frame subtitle' },
        fmta(
            [[
        \framesubtitle{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'subtitle'),
            }
        ),
        { condition = line_begin }
    ),

    -- Book Class
    s(
        { trig = 'ind', wordTrig = false, dscr = 'Index' },
        fmta(
            [[
        \index{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
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
                f(snake_case_labels, { 1 }),
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
                f(snake_case_labels, { 1 }),
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
                f(snake_case_labels, { 1 }),
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
                f(snake_case_labels, { 1 }),
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
                f(snake_case_labels, { 1 }),
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

    -- Math theorems, propositions, etc
    s(
        { trig = 'thm', dscr = 'Theorem' },
        fmta(
            [[
      \begin{theorem}<>
      \label{thm:<>}
        <><>
      \end{theorem}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                i(2, 'label'),
                isn(3, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'uthm', dscr = 'Unnumbered theorem' },
        fmta(
            [[
      \begin{theorem*}<>
        <><>
      \end{theorem*}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pro', dscr = 'Proposition' },
        fmta(
            [[
      \begin{proposition}
      \label{pro:<>}
        <><>
      \end{proposition}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'upro', dscr = 'Unnumbered proposition' },
        fmta(
            [[
      \begin{proposition*}
        <><>
      \end{proposition*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'lem', dscr = 'Lemma' },
        fmta(
            [[
      \begin{lemma}<>
      \label{lem:<>}
        <><>
      \end{lemma}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                i(2, 'label'),
                isn(3, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ulem', dscr = 'Unnumbered lemma' },
        fmta(
            [[
      \begin{lemma*}<>
        <><>
      \end{lemma*}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'name or reference'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cor', dscr = 'Corollary' },
        fmta(
            [[
      \begin{corollary}
      \label{cor:<>}
        <><>
      \end{corollary}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ucor', dscr = 'Unnumbered corollary' },
        fmta(
            [[
      \begin{corollary*}
        <><>
      \end{corollary*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'def', dscr = 'definition' },
        fmta(
            [[
      \begin{definition}
      \label{def:<>}
        <><>
      \end{definition}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'udef', dscr = 'Unnumbered definition' },
        fmta(
            [[
      \begin{definition*}
        <><>
      \end{definition*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'exa', dscr = 'example' },
        fmta(
            [[
      \begin{example}
      \label{exa:<>}
        <><>
      \end{example}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'uexa', dscr = 'Unnumbered example' },
        fmta(
            [[
      \begin{example*}
        <><>
      \end{example*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'exac', dscr = 'Example continued' },
        fmta(
            [[
      \begin{examcont}{exa:<>}
        <><>
      \end{examcont}
    ]],
            {
                i(1, 'ref'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'exe', dscr = 'Exercise' },
        fmta(
            [[
      \begin{exercise}
      \label{exe:<>}
        <><>
      \end{exercise}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'uexe', dscr = 'Unnumbered exercise' },
        fmta(
            [[
      \begin{exercise*}
        <><>
      \end{exercise*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ps', dscr = 'Problem statement' },
        fmta(
            [[
      \begin{problem*}
        <><>
      \end{problem*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ans', dscr = 'Answer/Solution' },
        fmta(
            [[
      \begin{solution*}
        <><>
      \end{solution*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rem', dscr = 'Remark' },
        fmta(
            [[
      \begin{remark}
      \label{rem:<>}
        <><>
      \end{remark}
    ]],
            {
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'urem', dscr = 'Unnumbered remark' },
        fmta(
            [[
      \begin{remark*}
        <><>
      \end{remark*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'not', dscr = 'Notation' },
        fmta(
            [[
      \begin{notation*}
        <><>
      \end{notation*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pru', dscr = 'Proof' },
        fmta(
            [[
      \begin{proof}<>
        <><>
      \end{proof}
    ]],
            {
                c(1, {
                    sn(nil, {
                        t('['),
                        i(1, 'Prueba de '),
                        t([[\cref*{]]),
                        i(2, 'thm:'),
                        t('}]'),
                    }),
                    t(''),
                }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),

    -- Equation Environments
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
                i(1, 'label'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
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
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'be', dscr = 'Breakable equation' },
        fmta(
            [[
      \begin{dmath*}
        <><>
      \end{dmath*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ali', dscr = 'Align' },
        fmta(
            [[
      \begin{align}
        <><first_eq> <>\\
        <second_eq> <>
      \end{align}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                first_eq = i(2, 'first eq'),
                c(3, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                second_eq = i(4, 'second eq'),
                c(5, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'sit', dscr = '(Short)intertext' },
        fmta(
            [[
        \<>intertext{<>}
    ]],
            {
                c(1, { sn(nil, { i(1, 'short') }), t('') }),
                i(2),
            }
        ),
        { condition = line_begin }
    ),

    s(
        { trig = 'ua', dscr = 'Align*' },
        fmta(
            [[
      \begin{align*}
        <><> \\
        <>
      \end{align*}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2, 'first eq'),
                i(3, 'second eq'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'max', dscr = 'Max/min' },
        fmta(
            [[
      \begin{alignat}{2}
        & \<max>_{\{<variable>\}} & \, <func> <func_label>\\
        & \;\; \text{<sa>} & <constraint_1> <c1_label>\\
        & & <constraint_2> <c2_label>
      \end{alignat}
    ]],
            {
                max = c(1, { sn(nil, { i(1, 'max') }), t('min') }),
                variable = i(2),
                func = i(3, 'F(x,y) & = xy'),
                func_label = c(4, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                sa = c(5, { sn(nil, { i(1, 's.a') }), t('s.t') }),
                constraint_1 = i(6, 'constraint with &'),
                c1_label = c(7, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
                constraint_2 = i(8, 'constraint with &'),
                c2_label = c(9, {
                    sn(nil, { t([[\label{eq:]]), i(1, 'tag'), t('}') }),
                    t([[\nonumber]]),
                }),
            }
        ),
        { condition = line_begin }
    ),

    -- Within Equation Environments
    s(
        { trig = 'aed', dscr = 'Aligned' },
        fmta(
            [[
      \begin{aligned}<>
        <><> \\
        <>
      \end{aligned}
    ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'r'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3, 'first eq'),
                i(4, 'second eq'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dca', dscr = '(d)Cases' },
        fmta(
            [[
      \begin{dcases*}
        <> & <> $<>$ \\
        <> & <> $<>$
      \end{dcases*}
    ]],
            {
                i(1),
                c(2, { sn(nil, { i(1, 'if') }), t('si') }),
                i(3),
                i(4),
                rep(2),
                i(5),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mat', dscr = 'Matrix' },
        fmta(
            [[
      \begin{<>matrix*}<>
        <>
      \end{<>matrix*}
    ]],
            {
                c(1, { sn(nil, { i(1, 'p/b/v/V/B') }), t('') }),
                c(2, { sn(nil, { t('['), i(1, 'r'), t(']') }), t('') }),
                i(3),
                rep(1),
            }
        ),
        { condition = line_begin }
    ),

    -- Math Operators & Notation
    s(
        { trig = 'frac', dscr = 'Fraction' },
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
        { trig = 'ol', dscr = 'Overline' },
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
        { trig = 'ul', dscr = 'Underline' },
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
        { trig = 'cdot', dscr = 'cdot' },
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
        { trig = 'vec', dscr = 'Vector' },
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
        { trig = 'seq', dscr = 'Sequence' },
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

    -- Delimiters
    s(
        { trig = 'bc', dscr = 'Braces' },
        fmta(
            [[
        \{<><>\}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'quo', dscr = 'Quote' },
        fmta(
            [[
        \enquote{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'lr(', wordTrig = false, dscr = 'Left( Right)' },
        fmta(
            [[
        \left(<><>\right)
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'lr[', wordTrig = false, dscr = 'Left[ Right]' },
        fmta(
            [[
        \left[<><>\right]
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'lr{', wordTrig = false, dscr = 'Left{ Right}' },
        fmta(
            [[
        \left{<><>\right}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),

    -- Editing/Fonts
    s(
        { trig = 'tx', dscr = 'Text' },
        fmta(
            [[
        \text{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'ti', dscr = 'Textit' },
        fmta(
            [[
        \textit{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'emph', dscr = 'Emphasize' },
        fmta(
            [[
        \emph{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
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
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'tss', dscr = 'Text sans-serif' },
        fmta(
            [[
        \textsf{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'ttt', dscr = 'Text typewriter' },
        fmta(
            [[
        \texttt{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'muc', dscr = 'MakeUppercase' },
        fmta(
            [[
        \MakeUppercase{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
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
                f(_G.LuaSnipConfig.visual_selection),
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
                f(_G.LuaSnipConfig.visual_selection),
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
                f(_G.LuaSnipConfig.visual_selection),
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
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'mf', dscr = 'Math frak' },
        fmta(
            [[
        \mathfrak{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'msc', dscr = 'Math script' },
        fmta(
            [[
        \mathscr{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),

    -- Floats
    s(
        { trig = 'flo', dscr = 'General float' },
        fmta(
            [[
                \begin{<>}<><>
                  <><>
                \end{<>}
            ]],
            {
                c(1, { sn(nil, { i(1, 'figure') }), t('table') }),
                c(2, { sn(nil, { t('['), i(1, '!htb'), t(']') }), t('') }),
                c(3, { sn(nil, { i(1, '\\RawFloats') }), t('') }),
                f(_G.LuaSnipConfig.visual_selection),
                i(4),
                rep(1),
            }
        ),
        { condition = line_begin }
    ),
    -- Subfloats: flo (without \RawFloats) + sflo snippet sequence
    s(
        { trig = 'sflo', dscr = 'Subfloat with caption' },
        fmta(
            [[
                \begin{sub<>}[t]{<>}
                  \centering<>
                  \caption{<>}
                  \label{<>:<>}<>
                \end{sub<>}<>
            ]],
            {
                c(1, { sn(nil, { i(1, 'figure') }), t('table') }),
                i(2, '0.48\\textwidth'),
                d(3, function(args)
                    local nodes = {}
                    if args[1][1] == 'figure' then
                        nodes = {
                            t({ '', '  ' }),
                            f(_G.LuaSnipConfig.visual_selection),
                            i(1),
                        }
                    end
                    return sn(nil, nodes)
                end, { 1 }),
                i(4, 'text'),
                m(1, '^figure$', 'fig', 'tab'),
                f(snake_case_labels, { 4 }),
                d(5, function(args)
                    local nodes = {}
                    if args[1][1] == 'table' then
                        nodes = {
                            t({ '', '  ' }),
                            f(_G.LuaSnipConfig.visual_selection),
                            i(1),
                        }
                    end
                    return sn(nil, nodes)
                end, { 1 }),
                rep(1),
                c(6, { sn(nil, { i(1, '\\hfill') }), t('\\\\[1ex]'), t('') }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        -- Side-by-side floats: flo (with \RawFloats) + mp snippet sequence
        { trig = 'mp', dscr = 'Minipage' },
        fmta(
            [[
                \begin{minipage}[t]{<>}
                  \centering<>
                  \captionof{<type>}{<>}
                  \label{<>:<>}<>
                \end{minipage}<>
            ]],
            {
                type = c(1, { sn(nil, { i(1, 'figure') }), t('table') }),
                i(2, '0.48\\textwidth'),
                d(3, function(args)
                    local nodes = {}
                    if args[1][1] == 'figure' then
                        nodes = {
                            t({ '', '  ' }),
                            f(_G.LuaSnipConfig.visual_selection),
                            i(1),
                        }
                    end
                    return sn(nil, nodes)
                end, { 1 }),
                i(4, 'text'),
                m(1, '^figure$', 'fig', 'tab'),
                f(snake_case_labels, { 4 }),
                d(5, function(args)
                    local nodes = {}
                    if args[1][1] == 'table' then
                        nodes = {
                            t({ '', '  ' }),
                            f(_G.LuaSnipConfig.visual_selection),
                            i(1),
                        }
                    end
                    return sn(nil, nodes)
                end, { 1 }),
                c(6, { sn(nil, { i(1, '\\hfill') }), t('\\\\[1ex]'), t('') }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'fig', dscr = 'Figure with caption' },
        fmta(
            [[
                \begin{figure}<>
                  <><>
                  \caption{<>}
                  \label{fig:<>}
                \end{figure}
            ]],
            {
                c(1, { sn(nil, { t('['), i(1, '!htb'), t(']') }), t('') }),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
                i(3, 'text'),
                f(snake_case_labels, { 3 }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ig', dscr = 'Include graphics' },
        fmta(
            [[
                \includegraphics<>{<>}
            ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'scale=1'), t(']') }), t('') }),
                i(2),
            }
        )
    ),
    s(
        { trig = 'cg', dscr = 'Centered graph' },
        fmta(
            [[
               \begin{center}
                 \includegraphics<>{<>}
               \end{center}
            ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'scale=1'), t(']') }), t('') }),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cap', dscr = 'Caption' },
        fmta(
            [[
                \caption{<>}
                \label{<>:<>}
            ]],
            {
                i(1, 'text'),
                c(2, { sn(nil, { i(1, 'fig') }), t('tab') }),
                f(snake_case_labels, { 1 }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'tab', dscr = 'Table with caption' },
        fmta(
            [[
                \begin{table}<>
                  \ttabbox
                  {\caption{<>}
                  \label{tab:<>}}
                  {\includegraphics<>{<>}}
                \end{table}
            ]],
            {
                c(1, { sn(nil, { t('['), i(1, '!htb'), t(']') }), t('') }),
                i(2, 'text'),
                f(snake_case_labels, { 2 }),
                c(3, { sn(nil, { t('['), i(1, 'scale=1'), t(']') }), t('') }),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rt', dscr = 'Regular tabular' },
        fmta(
            [[
                \begin{tabular}{<>}
                  \toprule
                  <>
                  \midrule
                  <>
                  \bottomrule
                \end{tabular}
            ]],
            {
                i(1, 'S'),
                d(2, function(args)
                    local nodes = {}
                    local nr_cols = string.len(args[1][1]) - 1
                    local idx = 0
                    for j = 1, nr_cols do
                        idx = idx + 1
                        table.insert(nodes, i(j))
                        table.insert(nodes, t(' & '))
                    end
                    idx = idx + 1
                    table.insert(nodes, i(idx))
                    table.insert(nodes, t(' \\\\'))
                    return sn(nil, nodes)
                end, { 1 }),
                i(3, 'rxc'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = '(%d)c', regTrig = true, dscr = 'Columns' },
        fmta(
            [[
               <><> <>
            ]],
            {
                d(1, function(_, snip)
                    local nodes = {}
                    local nr_cols = snip.captures[1] - 1
                    for j = 1, nr_cols do
                        table.insert(nodes, i(j))
                        table.insert(nodes, t(' & '))
                    end
                    return sn(nil, nodes)
                end),
                i(2),
                c(3, { sn(nil, { i(1, '\\\\') }), t('') }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = '(%d)x(%d)', regTrig = true, dscr = 'Rows x columns' },
        fmta(
            [[
               <>
            ]],
            {
                d(1, function(_, snip)
                    local nodes = {}
                    local nr_rows = snip.captures[1]
                    local nr_cols = snip.captures[2] - 1
                    local idx = 0
                    for r = 1, nr_rows do
                        for _ = 1, nr_cols do
                            idx = idx + 1
                            table.insert(nodes, i(idx))
                            table.insert(nodes, t(' & '))
                        end
                        idx = idx + 1
                        table.insert(nodes, i(idx))
                        if r < tonumber(nr_rows) then
                            table.insert(nodes, t({ ' \\\\', '' }))
                        else
                            table.insert(nodes, t(' \\\\'))
                        end
                    end
                    return sn(nil, nodes)
                end),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mul', wordTrig = false, dscr = 'Multicolumn' },
        fmta(
            [[
                \multicolumn{<>}{<>}{<><>}
            ]],
            {
                i(1, '1:3'),
                i(2, 'c'),
                f(_G.LuaSnipConfig.visual_selection),
                i(3),
            }
        )
    ),
    s(
        { trig = 'mur', wordTrig = false, dscr = 'Multirow' },
        fmta(
            [[
                \multirow{<>}{<>}{<><>}
            ]],
            {
                i(1, '2'),
                i(2, '*'),
                f(_G.LuaSnipConfig.visual_selection),
                i(3),
            }
        )
    ),
    s(
        { trig = 'cmr', wordTrig = false, dscr = 'Column Mid-rule' },
        fmta(
            [[
                \cmidrule<>{<>-<>}
            ]],
            {
                c(1, { sn(nil, { t('('), i(1, 'l'), t(')') }), t('') }),
                i(2, 'col1'),
                i(3, 'col2'),
            }
        )
    ),

    -- Tikz
    s(
        { trig = 'tikz', dscr = 'Tikz picture' },
        fmta(
            [[
                \begin{tikzpicture}<>
                  <>
                \end{tikzpicture}
            ]],
            { c(1, { sn(nil, { t('[scale='), i(1, '2'), t(']') }), t('') }), i(2) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'axis', dscr = 'Axis' },
        fmta(
            [[
                \draw [big arrow] (0,0) -- (<>,0) node[below, xshift=-1mm, yshift=-0.5mm]
                  {$<>$}
                  coordinate (xaxis);
                \draw [big arrow] (0,0) -- (0,<>) node [left,yshift=-1mm, xshift=-0.5mm]
                  {$<>$}
                  coordinate (yaxis);
            ]],
            {
                i(1, '5'),
                i(2, 'x'),
                rep(1),
                i(3, 'y'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'draw', dscr = 'Draw command' },
        fmta(
            [[
                \draw<>(<>) -- (<>);
            ]],
            {
                c(1, { sn(nil, { t(' ['), i(1, 'option'), t('] ') }), t(' ') }),
                i(2, 'cor1'),
                i(3, 'cor2'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'dsc', dscr = 'Draw smooth coordinates' },
        fmta(
            [[
                \draw<> plot [smooth] coordinates {<>};
            ]],
            {
                c(1, { sn(nil, { t('['), i(1, 'option'), t('] ') }), t('') }),
                i(2, '(c1) (c2) (cn)'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'node', dscr = 'Node' },
        fmta(
            [[
                \node<>at (<>) {<>};
            ]],
            {
                c(1, { sn(nil, { t(' ['), i(1, 'option'), t('] ') }), t(' ') }),
                i(2, 'coordinate'),
                i(3, 'text'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cd', dscr = 'Coordinate' },
        fmta(
            [[
                \coordinate (<>) at (<>);
            ]],
            {
                i(1, 'name'),
                i(2, 'coordinate'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cfd', dscr = 'Circle filldraw' },
        fmta(
            [[
                \filldraw (<>) circle (1.5pt)<>
            ]],
            {
                i(1, 'coordinate'),
                c(2, {
                    sn(nil, {
                        t(' node ['),
                        i(1, 'position'),
                        t('] {'),
                        i(2, 'text'),
                        t('}'),
                        t(';'),
                    }),
                    t(';'),
                }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pin', dscr = 'Draw pin' },
        fmta(
            [[
                \node[pin={[pin distance=<>]<>:{<>}}] at (<>) {};
            ]],
            {
                i(1, '1cm'),
                i(2, 'angle'),
                i(3, 'label'),
                i(4, 'coordinate'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'is', dscr = 'Intersection' },
        fmta(
            [[
                \path [name intersections={of=<>, by=<>}]
            ]],
            {
                i(1, 'L and K'),
                i(2, 'name'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'bra', dscr = 'Draw braces' },
        fmta(
            [[
                \draw[thin, decorate,decoration={brace,amplitude=8pt}] (<>) -- (<>)
                    node [midway] {<>};
            ]],
            {
                i(1, 'c1'),
                i(2, 'c2'),
                i(3, 'text'),
            }
        ),
        { condition = line_begin }
    ),

    -- Miscellaneous packages
    s(
        { trig = 'll', dscr = 'Listings' },
        fmta(
            [[
      \begin{lstlisting}
        <><>
      \end{lstlisting}
    ]],
            {
                isn(1, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(2),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mt', dscr = 'Minted' },
        fmta(
            [[
      \begin{minted}{<>}
        <><>
      \end{minted}
    ]],
            {
                i(1, 'python'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mtc', dscr = 'Minted with captions' },
        fmta(
            [[
      \begin{listing}[H]
        \begin{minted}{<>}
            <><>
        \end{minted}
        \caption{<>}
      \end{listing}
    ]],
            {
                i(1, 'python'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'td', wordTrig = false, dscr = 'Todo' },
        fmta(
            [[
        \todo{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),

    -- References and bookmarks
    s(
        { trig = 'fn', wordTrig = false, dscr = 'Footnote' },
        fmta(
            [[
        \footnote{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
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
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
    s(
        { trig = 'nn', dscr = 'No number' },
        fmta(
            [[
        \nonumber
    ]],
            {}
        )
    ),
    s(
        { trig = 'url', dscr = 'URL' },
        fmta(
            [[
        \href{<>}{<><>}
    ]],
            {
                i(1, 'link'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
            }
        )
    ),
    s(
        { trig = 'bm', dscr = 'Bookmark' },
        fmta(
            [[
        \pdfbookmark[<>]{<>}{<>}
    ]],
            {
                i(1, 'level'),
                i(2, 'text'),
                i(3, 'label'),
            }
        )
    ),
    s(
        { trig = 'crg', dscr = 'Cleveref general' },
        fmta(
            [[
        \cref{<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'crc', dscr = 'Cleveref chapter' },
        fmta(
            [[
        \cref{cha:<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'crs', dscr = 'Cleveref section' },
        fmta(
            [[
        \cref{sec:<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'crf', dscr = 'Cleveref figure' },
        fmta(
            [[
        \cref{fig:<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'crsf', dscr = 'Cleveref subfigure' },
        fmta(
            [[
        \cref{sfig:<>}
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
        { trig = 'crm', dscr = 'Cleveref math' },
        fmta(
            [[
        \cref{<>:<>}
    ]],
            {
                c(1, { t('thm'), t('def'), t('pro'), t('lem'), t('cor') }),
                i(2),
            }
        )
    ),
    s(
        { trig = 'cri', dscr = 'Cleveref item' },
        fmta(
            [[
        \cref{item:<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'crr', dscr = 'Cleveref range' },
        fmta(
            [[
        \crefrange{<>}{<>}
    ]],
            {
                i(1),
                i(2),
            }
        )
    ),

    -- Citations
    s(
        { trig = 'tc', dscr = 'Textcite' },
        fmta(
            [[
        \textcite{<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'fc', dscr = 'Fullcite' },
        fmta(
            [[
        \fullcite{<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'ffc', wordTrig = false, dscr = 'Foot fullcite' },
        fmta(
            [[
        \footfullcite{<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'noc', dscr = 'Nocite' },
        fmta(
            [[
        \nocite{<>}
    ]],
            {
                i(1),
            }
        )
    ),
    s(
        { trig = 'pb', dscr = 'Print bibliography' },
        fmta(
            [[
        \printbibliography[heading=<>]
    ]],
            { c(1, { t('bibarticle'), t('bibbook') }) }
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
