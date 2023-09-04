local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
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
}, {}
