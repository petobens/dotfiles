local ls = require('luasnip')

local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Documents
    s(
        { trig = 'msl', dscr = 'Mutt Slides' },
        fmta(
            [[
#import "@local/mutt-slides:0.1.0": *

#show: mutt-slides.with(
  title: [<>],
  subtitle: [<>],
  author: [<>],
  eyebrow: [<>],
  date: [<>],
)

= <>

== <>

<>
            ]],
            {
                i(1, 'Presentation title'),
                i(2, 'Subtitle'),
                i(3, 'Pedro Ferrari'),
                i(4, 'MUTTDATA × CLIENT'),
                i(5, 'Date'),
                i(6, 'Section'),
                i(7, 'Slide title'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'art', dscr = 'LaTeX-style article' },
        fmta(
            [[
#import "@local/latex-article:0.1.0": *

#show: latex-article.with(
  title: [<>],
  author: "<>",
  date: [<>],
  short-title: [<>],
  language: "<>",
  abstract: [<>],
  keywords: "<>",
  jel: [<>],
  toc: <>,
)

= <>

<>
            ]],
            {
                i(1, 'Article title'),
                i(2, 'Pedro Ferrari'),
                i(3, 'Date'),
                i(4, 'Short article title'),
                i(5, 'es'),
                i(6, 'Abstract'),
                i(7, 'Keywords'),
                i(8, 'JEL codes'),
                i(9, 'false'),
                i(10, 'Introduction'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'bok', dscr = 'LaTeX-style book' },
        fmta(
            [[
#import "@local/latex-book:0.1.0": *

#show: latex-book.with(
  title: [<>],
  subtitle: [<>],
  author: "<>",
  date: [<>],
  language: "<>",
  institution: [<>],
  department: [<>],
  copyright: [<>],
  dedication: [<>],
  toc: <>,
)

= <>

== <>

<>
            ]],
            {
                i(1, 'Book title'),
                i(2, 'Subtitle'),
                i(3, 'Pedro Ferrari'),
                i(4, 'Date'),
                i(5, 'en'),
                i(6, 'Institution'),
                i(7, 'Department'),
                i(8, '© Pedro Ferrari. All rights reserved.'),
                i(9, 'Dedication'),
                i(10, 'true'),
                i(11, 'First chapter'),
                i(12, 'First section'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    -- Standalone outputs
    s(
        { trig = 'sfig', dscr = 'Standalone CeTZ figure' },
        fmta(
            [[
// output: <>
#import "@local/standalone:0.1.0": *
#import "@preview/cetz:0.5.2"

#show: standalone.with(
  width: <>,
  margin: <>,
  fill: <>,
)

#cetz.canvas({
  import cetz.draw: *

  <>
})

<>
            ]],
            {
                i(1, 'figure.pdf'),
                i(2, 'auto'),
                i(3, '3pt'),
                i(4, 'none'),
                i(5, 'line((0, 0), (4, 0), stroke: rgb("#000080") + 1.5pt)'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'stab', dscr = 'Standalone table' },
        fmta(
            [[
// output: <>
#import "@local/standalone:0.1.0": *

#show: standalone.with(
  width: <>,
  margin: <>,
  fill: <>,
)

#table(
  columns: <>,
  align: <>,
  inset: (x: 6pt, y: 3.5pt),
  stroke: none,
  table.hline(stroke: 0.8pt),
  table.header([<>], [<>], [<>]),
  table.hline(stroke: 0.45pt),
  [<>], [<>], [<>],
  table.hline(stroke: 0.8pt),
)
            ]],
            {
                i(1, 'table.pdf'),
                i(2, '14cm'),
                i(3, '3pt'),
                i(4, 'none'),
                i(5, '(2fr, 1fr, 1fr)'),
                i(6, '(left, right, right)'),
                i(7, 'Indicator'),
                i(8, '2020'),
                i(9, '2025'),
                i(10, 'Productivity'),
                i(11, '100'),
                i(0, '114'),
            }
        ),
        { condition = line_begin }
    ),
}, {}
