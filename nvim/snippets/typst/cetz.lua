local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Canvas
    s(
        { trig = 'tikz', dscr = '[TikZ]-style CeTZ canvas' },
        fmta(
            [[
#import "@preview/cetz:0.5.2"

#cetz.canvas({
  import cetz.draw: *

  <><>
})

<>
            ]],
            {
                f(_G.LuaSnipConfig.visual_selection),
                i(1, 'line((0, 0), (4, 0), stroke: 1pt + black)'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Drawing primitives
    s(
        { trig = 'axis', dscr = '[Axis] (CeTZ)' },
        fmta(
            [[
line((0, 0), (<>, 0), mark: (end: ">>"), stroke: 0.8pt + black)
content((<>, -0.25), [$<>$])
line((0, 0), (0, <>), mark: (end: ">>"), stroke: 0.8pt + black)
content((-0.25, <>), [$<>$])
<>
            ]],
            {
                i(1, '5'),
                i(2, '5.25'),
                i(3, 'x'),
                i(4, '5'),
                i(5, '5.25'),
                i(6, 'y'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'draw', dscr = '[Draw] line (CeTZ)' },
        fmta('line((<>), (<>), stroke: <>)<>', {
            i(1, '0, 0'),
            i(2, '1, 1'),
            i(3, '1pt + black'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'dsc', dscr = '[D]raw [s]mooth [c]urve (CeTZ)' },
        fmta('hobby(<>, stroke: <>)<>', {
            i(1, '(0, 0), (1, 1), (2, 0)'),
            i(2, '1pt + black'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'node', dscr = 'CeTZ content [node]' },
        fmta('content((<>), [<>], anchor: "<>")<>', {
            i(1, '0, 0'),
            i(2, 'Text'),
            i(3, 'center'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'cd', dscr = '[C]oor[d]inate (named, CeTZ)' },
        fmta('anchor("<>", (<>))<>', { i(1, 'name'), i(2, '0, 0'), i(0) }),
        { condition = line_begin }
    ),
    s(
        { trig = 'cfd', dscr = '[C]ircle [f]ill[d]raw: filled point (CeTZ)' },
        fmta('circle((<>), radius: <>, fill: <>, stroke: none)<>', {
            i(1, '0, 0'),
            i(2, '0.08'),
            i(3, 'black'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'pin', dscr = '[Pin] label (CeTZ)' },
        fmta(
            [[
line((<>), (<>), stroke: 0.6pt + black)
content((<>), [<>], anchor: "<>")
<>
            ]],
            {
                i(1, '0, 0'),
                i(2, '1, 1'),
                i(3, '1, 1'),
                i(4, 'Label'),
                i(5, 'south-west'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'is', dscr = 'CeTZ [i]nter[s]ections' },
        fmta('intersections("<>", "<>", "<>")<>', {
            i(1, 'intersection'),
            i(2, 'first'),
            i(3, 'second'),
            i(0),
        }),
        { condition = line_begin }
    ),
    s(
        { trig = 'bra', dscr = '[Bra]ce (CeTZ)' },
        fmta(
            [[
cetz.decorations.brace((<>), (<>), name: "brace")
content("brace.content", [<>])
<>
            ]],
            { i(1, '0, 0'), i(2, '2, 0'), i(3, 'Text'), i(0) }
        ),
        { condition = line_begin }
    ),
}, {}
