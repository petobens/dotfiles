local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Images and figures
    s(
        { trig = 'ig', dscr = 'Image' },
        fmta('#image("<>", width: <>%)<>', {
            i(1, 'image.pdf'),
            i(2, '100'),
            i(0),
        })
    ),
    s(
        { trig = 'fig', dscr = 'Figure' },
        fmta(
            [[
#figure(
  image("<>", width: <>%),
  caption: [<>],
  placement: none,
) <<fig:<>>>

<>
            ]],
            {
                i(1, 'image.pdf'),
                i(2, '100'),
                i(3, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 3 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'flo', dscr = 'General figure' },
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
        { trig = 'sflo', dscr = 'Referenceable subfigures' },
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
  placement: none,
)

<>
            ]],
            {
                i(1, 'image-a.pdf'),
                i(2, 'First panel'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(3, 'image-b.pdf'),
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
        { trig = 'cg', dscr = 'Centered image' },
        fmta('#align(center)[#image("<>", width: <>%)]<>', {
            i(1, 'image.pdf'),
            i(2, '100'),
            i(0),
        })
    ),
    s(
        { trig = 'mp', dscr = 'Fixed-width block' },
        fmta('#block(width: <>%)[<><>]<>', {
            i(1, '50'),
            f(_G.LuaSnipConfig.visual_selection),
            i(2),
            i(0),
        })
    ),

    -- Tables
    s(
        { trig = 'tab', dscr = 'Table from image' },
        fmta(
            [[
#figure(
  image("<>"),
  kind: table,
  caption: [<>],
  placement: none,
) <<tab:<>>>

<>
            ]],
            {
                i(1, 'table.pdf'),
                i(2, 'Caption'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'rt', dscr = 'Native table' },
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
        { trig = 'mul', wordTrig = false, dscr = 'Spanning table cell' },
        fmta('table.cell(colspan: <>)[<>]<>', { i(1, '2'), i(2), i(0) })
    ),
    s(
        { trig = 'mur', wordTrig = false, dscr = 'Spanning table row' },
        fmta('table.cell(rowspan: <>)[<>]<>', { i(1, '2'), i(2), i(0) })
    ),
}, {}
