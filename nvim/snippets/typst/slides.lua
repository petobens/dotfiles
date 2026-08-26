local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Slide headings
    s(
        { trig = 'ft', dscr = '[F]rame/slide [t]itle' },
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
        { trig = 'fs', dscr = '[F]rame/[s]lide subtitle' },
        fmta('#slide-subtitle[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Subtitle'),
            i(0),
        }),
        { condition = line_begin }
    ),

    -- Mutt slide components
    s(
        { trig = 'blo', dscr = '[Blo]ck/card' },
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

    s(
        { trig = 'callout', dscr = '[Callout]' },
        fmta('#callout([<><>])<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Callout'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'formula', dscr = '[Formula] card' },
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
        { trig = 'small', dscr = '[Small] slide text' },
        fmta('#small[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Text'),
            i(0),
        })
    ),
    s(
        { trig = 'cols', dscr = 'Two slide [col]umn[s]' },
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
    s(
        { trig = 'pause', dscr = '[Pause]: reveal following slide content' },
        fmta('#pause\n\n<>', { i(0) }),
        { condition = line_begin }
    ),
    s(
        { trig = 'uncover', dscr = '[Uncover]: reveal while preserving space' },
        fmta('#uncover("<>-")[<><>]<>', {
            i(1, '2'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, 'Content'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'only', dscr = '[Only]: show without preserving hidden space' },
        fmta('#only("<>")[<><>]<>', {
            i(1, '2'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2, 'Content'),
            i(0),
        }),
        { condition = line_begin }
    ),
}, {}
