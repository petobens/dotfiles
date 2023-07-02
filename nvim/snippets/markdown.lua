local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local line_begin = require('luasnip.extras.expand_conditions').line_begin
local fmta = require('luasnip.extras.fmt').fmta

return {
    s(
        { trig = 'url', wordTrig = false, dscr = 'Link' },
        fmta(
            [[
                [<>](<><>)
            ]],
            {
                i(1),
                i(2),
                f(_G.LuaSnipConfig.visual_selection),
            }
        )
    ),
    s(
        { trig = 'ph', dscr = 'Pandoc Header' },
        fmta(
            [[
                ---
                fontsize: 12pt
                geometry: margin=3cm
                ---
            ]],
            {}
        ),
        { condition = line_begin }
    ),
}, {}
