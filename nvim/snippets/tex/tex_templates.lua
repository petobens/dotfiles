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
}, {}
