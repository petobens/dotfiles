local ls = require('luasnip')

local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Text and math
    s(
        { trig = 'lorem', dscr = 'Lorem ipsum text' },
        fmta('#lorem(<>)<>', { i(1, '100'), i(0) }),
        { condition = line_begin }
    ),
    s(
        { trig = 'eq', dscr = 'Numbered equation' },
        fmta(
            [[
$ <> $ <<<>>>

<>
            ]],
            { i(1, 'equation'), i(2, 'label'), i(0) }
        ),
        { condition = line_begin }
    ),
    -- References
    s({ trig = 'ref', dscr = 'Reference' }, fmta('@<><>', { i(1, 'label'), i(0) })),
    s(
        { trig = 'refp', dscr = 'Page reference' },
        fmta('#ref(<<<>>>, form: "page")<>', { i(1, 'label'), i(0) })
    ),
    s(
        { trig = 'cite', dscr = 'Citation' },
        fmta('@<><>', { i(1, 'citation-key'), i(0) })
    ),
    s(
        { trig = 'bib', dscr = 'Bibliography' },
        fmta(
            [[
#bibliography(
  "<>",
  title: [<>],
  style: "<>",
)

<>
            ]],
            {
                i(1, 'references.bib'),
                i(2, 'Referencias'),
                i(3, 'harvard-cite-them-right'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s({ trig = 'lab', dscr = 'Label' }, fmta('<<<>>><>', { i(1, 'label'), i(0) })),
    -- Figures and tables
    s(
        { trig = 'fig', dscr = 'Figure' },
        fmta(
            [[
#figure(
  image("<>", width: <>%),
  placement: <>,
  caption: [<>],
) <<<>>>

<>
            ]],
            {
                i(1, 'image.svg'),
                i(2, '100'),
                i(3, 'auto'),
                i(4, 'Caption'),
                i(5, 'figure-label'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'subf', dscr = 'Referenceable subfigures' },
        fmta(
            [[
#subfigure-grid(
  subfigure(
    image("<>", width: 100%),
    caption: [<>],
    label: <<<>>>,
  ),
  subfigure(
    image("<>", width: 100%),
    caption: [<>],
    label: <<<>>>,
  ),
  caption: [<>],
  label: <<<>>>,
  placement: <>,
)

<>
            ]],
            {
                i(1, 'image-a.svg'),
                i(2, 'First panel'),
                i(3, 'figure-a'),
                i(4, 'image-b.svg'),
                i(5, 'Second panel'),
                i(6, 'figure-b'),
                i(7, 'Combined caption'),
                i(8, 'figure-label'),
                i(9, 'auto'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'tab', dscr = 'Table' },
        fmta(
            [[
#figure(
  table(
    columns: <>,
    align: <>,
    table.header([<>], [<>], [<>]),
    [<>], [<>], [<>],
  ),
  placement: <>,
  caption: [<>],
) <<<>>>

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
                i(9, 'auto'),
                i(10, 'Caption'),
                i(11, 'table-label'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    -- Statements
    s(
        { trig = 'thm', dscr = 'Theorem' },
        fmta(
            [[
#theorem(
  title: <>,
  note: [<>],
  numbered: <>,
)[
  <>
] <<<>>>

<>
            ]],
            {
                i(1, 'auto'),
                i(2, 'Theorem name'),
                i(3, 'true'),
                i(4, 'Statement'),
                i(5, 'theorem-label'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'sol', dscr = 'Solution' },
        fmta(
            [[
#solution(title: <>)[
  <>
]

<>
            ]],
            { i(1, 'auto'), i(2, 'Solution'), i(0) }
        ),
        { condition = line_begin }
    ),
    -- Functions
    s(
        { trig = 'fn', dscr = 'Content function' },
        fmta(
            [[
#<>[
  <>
]<>
            ]],
            { i(1, 'foo'), i(2, 'content'), i(0) }
        )
    ),
    s(
        { trig = 'call', dscr = 'Function call' },
        fmta('#<>(<>)<>', { i(1, 'foo'), i(2, 'arguments'), i(0) })
    ),
}, {}
