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
                \begin{frame}[fragile=singleslide]
                \frametitle{<>}
                  <><>
                \end{frame}
            ]],
            {
                i(1, 'title'),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ft', dscr = 'Frametitle' },
        fmta(
            [[
        \frame{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'title'),
            }
        ),
        { condition = line_begin }
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
        ),
        { condition = line_begin }
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

    -- Editing/Fonts
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

    -- Math Operators and Delimiters
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
        { trig = 'sum', dscr = 'Sum' },
        fmta(
            [[
        \sum_{<>}<> <>
    ]],
            {
                i(1, 't=1'),
                c(2, { sn(nil, { t('^{'), i(1, '\\infty'), t('}') }), t('') }),
                f(_G.LuaSnipConfig.visual_selection),
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
