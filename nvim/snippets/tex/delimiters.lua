local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta

return {
    -- Delimiters
    s(
        { trig = 'bc', wordTrig = false, dscr = 'Braces' },
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
    s(
        { trig = 'vs', dscr = 'vspace' },
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
