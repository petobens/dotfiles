local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local c = ls.choice_node
local f = ls.function_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep
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
