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
        { trig = 'fn', wordTrig = false, dscr = '[F]oot[n]ote' },
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
        { trig = 'lab', wordTrig = false, dscr = '[Lab]el' },
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
        { trig = 'nn', wordTrig = false, dscr = '[N]o [n]umber' },
        fmta(
            [[
        \nonumber
    ]],
            {}
        )
    ),
    s(
        { trig = 'url', dscr = '[URL]' },
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
        { trig = 'bm', wordTrig = false, dscr = '[B]ook[m]ark' },
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
        { trig = 'crg', dscr = '[C]leve[r]ef [g]eneral' },
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
        { trig = 'crc', dscr = '[C]leve[r]ef [c]hapter' },
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
        { trig = 'crs', dscr = '[C]leve[r]ef [s]ection' },
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
        { trig = 'crf', dscr = '[C]leve[r]ef [f]igure' },
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
        { trig = 'crsf', dscr = '[C]leve[r]ef [s]ub[f]igure' },
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
        { trig = 'crt', dscr = '[C]leve[r]ef [t]able' },
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
        { trig = 'cre', dscr = '[C]leve[r]ef [e]quation' },
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
        { trig = 'crm', dscr = '[C]leve[r]ef [m]ath' },
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
        { trig = 'cri', dscr = '[C]leve[r]ef [i]tem' },
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
        { trig = 'crr', dscr = '[C]leve[r]ef [r]ange' },
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
        { trig = 'tc', dscr = '[T]ext[c]ite' },
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
        { trig = 'fc', dscr = '[F]ull[c]ite' },
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
        { trig = 'ffc', wordTrig = false, dscr = '[F]oot [f]ull[c]ite' },
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
        { trig = 'noc', wordTrig = false, dscr = '[Noc]ite' },
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
        { trig = 'pb', dscr = '[P]rint [b]ibliography' },
        fmta(
            [[
        \printbibliography[heading=<>]
    ]],
            { c(1, { t('bibarticle'), t('bibbook') }) }
        ),
        { condition = line_begin }
    ),
}, {}
