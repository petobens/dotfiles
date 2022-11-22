local ls = require('luasnip')
local c = ls.choice_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node
local p = require('luasnip.extras').partial
local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
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
        { trig = 'sat', dscr = 'Standalone table' },
        fmta(
            [[
                \documentclass{standalone}

                %-----------------------+
                % Clean auxiliary files |
                %-----------------------+
                % arara: clean: {files: [<>.aux, <>.log, <>.synctex.gz]}

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
                p(vim.fn.expand, '%:t:r'),
                p(vim.fn.expand, '%:t:r'),
                p(vim.fn.expand, '%:t:r'),
                c(1, { sn(nil, { i(1, '%') }), t('') }),
                i(2, 'S'),
                i(3),
                i(4),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'saf', dscr = 'Standalone figure' },
        fmta(
            [[
                \documentclass{standalone}

                %-----------------------+
                % Clean auxiliary files |
                %-----------------------+
                % arara: clean: {files: [<>.aux, <>.log, <>.synctex.gz]}

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
                p(vim.fn.expand, '%:t:r'),
                p(vim.fn.expand, '%:t:r'),
                p(vim.fn.expand, '%:t:r'),
                i(1),
            }
        ),
        { condition = line_begin }
    ),
}, {}
