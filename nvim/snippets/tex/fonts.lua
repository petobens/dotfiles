local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Fonts
    s(
        { trig = 'tx', dscr = '[T]e[x]t' },
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
        { trig = 'ti', dscr = '[T]ext[i]t' },
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
        { trig = 'emph', dscr = '[Emph]asize' },
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
        { trig = 'tb', dscr = '[T]ext [b]old' },
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
        { trig = 'tss', dscr = '[T]ext [s]ans-[s]erif' },
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
        { trig = 'ttt', dscr = '[T]ex[tt]t/typewriter' },
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
        { trig = 'muc', dscr = '[M]ake [u]pper[c]ase' },
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
        { trig = 'mcg', dscr = '[M]ath [c]alli[g]raphic' },
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
        { trig = 'mbb', dscr = '[M]ath [b]lackboard [b]old' },
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
        { trig = 'mi', dscr = '[M]ath [i]talic' },
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
        { trig = 'mr', dscr = '[M]ath [r]oman' },
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
        { trig = 'mf', dscr = '[M]ath [f]raktur' },
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
        { trig = 'msc', dscr = '[M]ath [sc]ript' },
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
}, {}
