local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Titles and context
    s(
        { trig = 'ft', dscr = '[F]rame/slide [t]itle' },
        fmta(
            [[
== <><><>]],
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

    s(
        { trig = 'chip', dscr = 'Slide context [chip]' },
        fmta('#slide-chip[<><>]<>', {
            f(_G.LuaSnipConfig.visual_selection),
            i(1, 'Context'),
            i(0),
        }),
        { condition = line_begin }
    ),

    -- Agenda
    s(
        { trig = 'agenda', dscr = 'Full slide [agenda]' },
        fmta('#agenda()<>', { i(0) }),
        { condition = line_begin }
    ),

    -- Card grids and sequences
    s(
        { trig = 'cards', dscr = '[Cards] with equal heights' },
        fmta(
            [[
#card-grid((
  (title: [<>], body: [<>]),
  (title: [<>], body: [<>]),
))<>]],
            { i(1, 'Lorem'), i(2, 'Ipsum'), i(3, 'Dolor'), i(4, 'Sit amet'), i(0) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'timeline', dscr = 'Slide [timeline]' },
        fmta(
            [[
#timeline((
  (title: [<>], body: [<>]),
  (title: [<>], body: [<>]),
))<>]],
            { i(1, 'Lorem'), i(2, 'Ipsum'), i(3, 'Dolor'), i(4, 'Sit amet'), i(0) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'process', dscr = 'Numbered slide [process]' },
        fmta(
            [[
#process((
  (title: [<>], body: [<>]),
  (title: [<>], body: [<>]),
))<>]],
            { i(1, 'Lorem'), i(2, 'Ipsum'), i(3, 'Dolor'), i(4, 'Sit amet'), i(0) }
        ),
        { condition = line_begin }
    ),

    -- Metrics, comparisons, and formula definitions
    s(
        { trig = 'metrics', dscr = 'Slide [metrics]' },
        fmta(
            [[
#metrics((
  (value: [<>], title: [<>], body: [<>]),
  (value: [<>], title: [<>], body: [<>]),
))<>]],
            {
                i(1, '00%'),
                i(2, 'Lorem'),
                i(3, 'Ipsum'),
                i(4, '000'),
                i(5, 'Dolor'),
                i(6, 'Sit amet'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'compare', dscr = 'Slide [compare] table' },
        fmta(
            [[
#comparison(
  ([<>], [<>]),
  (
    ([<>], [<>]),
    ([<>], [<>]),
  ),
)<>]],
            {
                i(1, 'Lorem'),
                i(2, 'Ipsum'),
                i(3, 'Dolor'),
                i(4, 'Sit amet'),
                i(5, 'Consectetur'),
                i(6, 'Adipiscing'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'formdefs', dscr = '[Form]ula with [def]inition[s]' },
        fmta(
            [[
#formula-definitions(
  $ <> $,
  (
    (title: [<>], body: [<>]),
    (title: [<>], body: [<>]),
  ),
)<>]],
            { i(1, 'x = y'), i(2, 'x'), i(3, 'Lorem'), i(4, 'y'), i(5, 'Ipsum'), i(0) }
        ),
        { condition = line_begin }
    ),

    -- Individual content components
    s(
        { trig = 'blo', dscr = '[Blo]ck/card' },
        fmta(
            [[
#card(
  [<>],
  [<><>],
)<>]],
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
        { trig = 'formula', dscr = '[Formula] card' },
        fmta(
            [[
#formula[
  $
    <><>
  $
]<>]],
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

    -- Columns
    s(
        { trig = 'cols', dscr = 'Two slide [col]umn[s]' },
        fmta(
            [[
#cols(columns: (1fr, 1fr), gutter: 1em)[
  <>
][
  <>
]<>]],
            { i(1, 'Left column'), i(2, 'Right column'), i(0) }
        ),
        { condition = line_begin }
    ),

    -- Overlays
    s(
        { trig = 'pause', dscr = '[Pause]: reveal following slide content' },
        fmta('#pause<>', { i(0) }),
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
