local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Images and figures
    s(
        { trig = 'ig', dscr = '[I]nclude [g]raphics: image' },
        fmta('#image("<>", width: <>%)<>', {
            i(1),
            i(2, '100'),
            i(0),
        })
    ),
    s(
        { trig = 'fig', dscr = '[Fig]ure' },
        fmta(
            [[
#figure(
  image("<>", width: <>%),
  caption: [<>],
) <<fig:<>>>

<>
            ]],
            {
                i(1),
                i(2, '100'),
                i(3, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 3 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'flo', dscr = '[Flo]at: general figure' },
        fmta(
            [[
#figure(
  [<>],
  caption: [<>],
) <<fig:<>>>

<>
            ]],
            {
                i(1, 'Figure content'),
                i(2, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'sflo', dscr = '[S]ub[flo]at: referenceable subfigures' },
        fmta(
            [[
#subfigure-grid(
  subfigure(
    image("<>", width: 100%, height: 100%, fit: "contain"),
    caption: [<>],
    label: <<sfig:<>>>,
  ),
  subfigure(
    image("<>", width: 100%, height: 100%, fit: "contain"),
    caption: [<>],
    label: <<sfig:<>>>,
  ),
  caption: [<>],
  label: <<fig:<>>>,
  panel-height: <>cm,
)

<>
            ]],
            {
                i(1),
                i(2, 'First panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(3),
                i(4, 'Second panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 4 }),
                i(5, 'Combined caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 5 }),
                i(6, '5'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cg', dscr = '[C]entered [g]raphics: image' },
        fmta('#align(center)[#image("<>", width: <>%)]<>', {
            i(1),
            i(2, '100'),
            i(0),
        })
    ),
    s(
        { trig = 'mp', dscr = '[M]ini[p]age: fixed-width block' },
        fmta('#block(width: <>%)[<><>]<>', {
            i(1, '50'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2),
            i(0),
        })
    ),

    -- Tables
    s(
        { trig = 'tab', dscr = '[Tab]le from image' },
        fmta(
            [[
#figure(
  image("<>"),
  kind: table,
  caption: [<>],
) <<tab:<>>>

<>
            ]],
            {
                i(1),
                i(2, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rt', dscr = '[R]egular [t]able (native)' },
        fmta(
            [[
#latex-table(
  columns: <>,
  align: <>,
  header: ([<>], [<>], [<>]),
  rows: (
    ([<>], [<>], [<>]),
  ),
)

<>
            ]],
            {
                i(1, '(2fr, 1fr, 1fr)'),
                i(2, '(left, right, right)'),
                i(3, 'Indicator'),
                i(4, '2020'),
                i(5, '2025'),
                i(6, 'Productivity'),
                i(7, '100'),
                i(8, '114'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'mul', wordTrig = false, dscr = '[Mul]ticolumn: spanning table cell' },
        fmta('table.cell(colspan: <>)[<>]<>', { i(1, '2'), i(2), i(0) })
    ),
    s({
        trig = 'mur',
        wordTrig = false,
        dscr = '[Mu]lti[r]ow: spanning table row',
    }, fmta('table.cell(rowspan: <>)[<>]<>', { i(1, '2'), i(2), i(0) })),
}, {}
