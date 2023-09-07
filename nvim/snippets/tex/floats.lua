local extras = require('luasnip.extras')
local ls = require('luasnip')

local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local isn = ls.indent_snippet_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node

local m = extras.match
local p = extras.partial
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Templates
    s(
        { trig = 'sat', dscr = 'Standalone table' },
        fmta(
            [[
%-----------------------+
% Clean auxiliary files |
%-----------------------+
% arara: clean: {files: [<base_fn>.aux, <base_fn>.log, <base_fn>.synctex.gz]}

\documentclass{standalone}

%------------------------------------+
% Language, hyphenation and encoding |
%------------------------------------+
\usepackage{lmodern}                      % Use Latin Modern fonts
<>\renewcommand{\rmdefault}{\sfdefault}   % Use beamer sans-serif font family
\usepackage[T1]{fontenc}        % Better output when a diacritic/accent is used
\usepackage[utf8]{inputenc}               % Allows to input accented characters

%----------------+
% Table packages |
%----------------+
\usepackage{array}          % Flexible column formatting
% \usepackage{spreadtab}  % Spreadsheet features
\usepackage{multirow}       % Allows table cells that span more than one row
\usepackage{booktabs}       % Enhance quality of tables
\setlength{\heavyrulewidth}{1pt}

\usepackage{siunitx}        % Typeset units correctly and define new column (S)
\sisetup{detect-all,table-auto-round,input-symbols = {()}}
% \robustify{\bfseries}     % Correct alignment of bold numbers in tables

% Table colors
\usepackage[table,x11names]{xcolor}

\begin{document}
\begin{tabular}{<>}
    \toprule
    <>
    \midrule
    <>
    \bottomrule
\end{tabular}
\end{document}
]],
            {
                base_fn = p(vim.fn.expand, '%:t:r'),
                c(1, { sn(nil, { i(1, '%') }), t('') }),
                i(2, 'S'),
                d(3, function(args)
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
                end, { 2 }),
                i(4, 'rxc'),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'saf', dscr = 'Standalone figure' },
        fmta(
            [[
%-----------------------+
% Clean auxiliary files |
%-----------------------+
% arara: clean: {files: [<base_fn>.aux, <base_fn>.log, <base_fn>.synctex.gz]}

\documentclass[tikz]{standalone}

%----------------------------------------------+
% Font, hyphenation, encoding and math symbols |
%----------------------------------------------+
\usepackage{lmodern}
% \renewcommand{\rmdefault}{\sfdefault}   % Use beamer sans-serif font family
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{amssymb}
\usepackage[eulergreek]{sansmath}

%--------+
% Graphs |
%--------+
\usepackage{pgfplots}
\pgfplotsset{compat=newest,
standard/.style={
    axis lines=middle, axis line style={-,big arrow},
    every axis x label/.style={at={(current axis.right of origin)}, anchor=
    north east, xshift=1.2mm, yshift=-0.2mm},
    every axis y label/.style={at={(current axis.above origin)}, anchor=east,
    yshift=-0.7mm},
    every tick/.style={color=black, line width=0.35pt}
}
}

\usetikzlibrary{arrows,intersections,calc,decorations.pathreplacing,
decorations.markings}
\tikzset{
big arrow/.style={
    decoration={markings,mark=at position 1 with {\arrow[scale=2.4]{latex'}}},
    postaction={decorate,draw}},
bold/.style={line width=1pt},
fopaque/.style={fill=gray, fill opacity=0.25},
every picture/.style={line width=0.5pt},
every node/.style={font=\small},
every pin/.style={font=\footnotesize},
every pin edge/.style={<<-,>>=stealth'}
}

\begin{document}
\begin{tikzpicture}
    <>
\end{tikzpicture}
\end{document}
]],
            {
                base_fn = p(vim.fn.expand, '%:t:r'),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cm', dscr = 'Choice multi' },
        fmta(
            [[
                <>
            ]],
            {
                c(1, { sn(nil, { t('foo\bar'), t('bar') }), t('') }),
            }
        ),
        { condition = line_begin }
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
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
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
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
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
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
                i(4, 'text'),
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ig', dscr = 'Include graphics' },
        fmta(
            [[
                \includegraphics<>{<path>}
            ]],
            {
                path = i(1),
                c(2, { sn(nil, { t('['), i(1, 'scale=1'), t(']') }), t('') }),
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
                f(_G.LuaSnipConfig.snake_case_labels, { 1 }),
            }
        ),
        { condition = line_begin }
    ),

    -- Tables
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
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
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
                  <><>
                \end{tikzpicture}
            ]],
            {
                c(1, { sn(nil, { t('[scale='), i(1, '2'), t(']') }), t('') }),
                isn(2, { f(_G.LuaSnipConfig.visual_selection) }, '$PARENT_INDENT\t'),
                i(3),
            }
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
}, {}
