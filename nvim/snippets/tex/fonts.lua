local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Fonts
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
}, {}
