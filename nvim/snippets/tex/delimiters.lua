local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Delimiters
    s(
        { trig = 'bc', wordTrig = false, dscr = '[B]ra[c]es' },
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
        { trig = 'quo', dscr = '[Quo]te' },
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
        { trig = 'lr(', wordTrig = false, dscr = '[L]eft/[r]ight parentheses' },
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
        { trig = 'lr[', wordTrig = false, dscr = '[L]eft/[r]ight square brackets' },
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
        { trig = 'lr{', wordTrig = false, dscr = '[L]eft/[r]ight braces' },
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
    s(
        { trig = 'vs', dscr = '[V]ertical [s]pace' },
        fmta(
            [[
        \vspace{<><>}
    ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1),
            }
        )
    ),
}, {}
