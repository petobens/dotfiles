local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Familiar Beamer triggers
    s(
        { trig = 'bf', dscr = 'Slide' },
        fmta(
            [[
== <>

<><>

<>
            ]],
            {
                i(1, 'Slide title'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'ft', dscr = 'Slide title' },
        fmta(
            [[
== <><>

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'Slide title'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'fs', dscr = 'Slide subtitle' },
        fmta('#slide-subtitle[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Subtitle'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'blo', dscr = 'Card' },
        fmta(
            [[
#card(
  [<>],
  [<><>],
)

<>
            ]],
            {
                i(1, 'Title'),
                f(_G.LuaSnipConfig.visual_selection),
                i(2, 'Body'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Mutt slide components
    s(
        { trig = 'callout', dscr = 'Callout' },
        fmta('#callout([<><>])<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Callout'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'formula', dscr = 'Formula card' },
        fmta(
            [[
#formula[
  $
    <><>
  $
]

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'x = y'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'small', dscr = 'Small slide text' },
        fmta('#small[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Text'),
            i(0),
        })
    ),
    s(
        { trig = 'cols', dscr = 'Two slide columns' },
        fmta(
            [[
#cols(columns: (1fr, 1fr), gutter: 1em)[
  <>
][
  <>
]

<>
            ]],
            { i(1, 'Left column'), i(2, 'Right column'), i(0) }
        ),
        { condition = line_begin }
    ),
}, {}
