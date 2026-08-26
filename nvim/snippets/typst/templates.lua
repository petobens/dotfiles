local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    -- Minimal working example
    s(
        { trig = 'mwe', dscr = '[M]inimal [w]orking [e]xample' },
        fmta(
            [[
#import "@local/latex-article:0.1.0": *

#show: latex-article.with(
  title: [<>],
  abstract: none,
)

= <>
<<sec:<>>>

<>
            ]],
            {
                i(1, 'Article title'),
                i(2, 'Section'),
                f(_G.LuaSnipConfig.snake_case_labels, { 2 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Article
    s(
        { trig = 'lat', dscr = '[L]aTeX [a]rticle [t]emplate' },
        fmta(
            [[
#import "@local/latex-article:0.1.0": *

#show: latex-article.with(
  language: "<>",
  title: [<>],
  author: "<>",
  author-note: <>,
  date: datetime.today(),
  short-title: <>,
  abstract: <>,
  keywords: <>,
  jel: <>,
  toc: <>,
)

= <>
<<sec:<>>>

<>
            ]],
            {
                c(1, { t('es'), t('en') }),
                i(2, 'Article title'),
                i(3, 'Pedro Ferrari'),
                c(4, {
                    t('none'),
                    sn(nil, { t('['), i(1, 'Author affiliation or note'), t(']') }),
                }),
                c(5, {
                    t('none'),
                    sn(nil, { t('['), i(1, 'Short article title'), t(']') }),
                }),
                c(6, { t('none'), sn(nil, { t('['), i(1, 'Abstract'), t(']') }) }),
                c(7, { t('none'), sn(nil, { t('"'), i(1, 'Keywords'), t('"') }) }),
                c(8, { t('none'), sn(nil, { t('['), i(1, 'JEL codes'), t(']') }) }),
                i(9, 'false'),
                i(10, 'Introduction'),
                f(_G.LuaSnipConfig.snake_case_labels, { 10 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Book
    s(
        { trig = 'lbt', dscr = '[L]aTeX-style [b]ook [t]emplate' },
        fmta(
            [[
#import "@local/latex-book:0.1.0": *

#show: latex-book.with(
  language: "<>",
  title: [<>],
  subtitle: <>,
  author: "<>",
  date: datetime.today(),
  institution: <>,
  department: <>,
  logo: <>,
  copyright: <>,
  dedication: <>,
  toc: <>,
  preface: <>,
  index: <>,
)

= <>
<<cha:<>>>

== <>
<<sec:<>>>

<>
            ]],
            {
                c(1, { t('es'), t('en') }),
                i(2, 'Book title'),
                c(3, { t('none'), sn(nil, { t('['), i(1, 'Subtitle'), t(']') }) }),
                i(4, 'Pedro Ferrari'),
                c(5, { t('none'), sn(nil, { t('['), i(1, 'Institution'), t(']') }) }),
                c(6, { t('none'), sn(nil, { t('['), i(1, 'Department'), t(']') }) }),
                c(7, {
                    t('none'),
                    sn(nil, {
                        t('read("'),
                        i(1),
                        t('", encoding: none)'),
                    }),
                }),
                c(8, {
                    t('none'),
                    sn(nil, {
                        t('['),
                        i(1, '© Pedro Ferrari. All rights reserved.'),
                        t(']'),
                    }),
                }),
                c(9, { t('none'), sn(nil, { t('['), i(1, 'Dedication'), t(']') }) }),
                i(10, 'true'),
                c(11, {
                    t('none'),
                    sn(nil, { t('include "'), i(1, 'preface.typ'), t('"') }),
                }),
                i(12, 'false'),
                i(13, 'First chapter'),
                f(_G.LuaSnipConfig.snake_case_labels, { 13 }),
                i(14, 'First section'),
                f(_G.LuaSnipConfig.snake_case_labels, { 14 }),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Mutt slides
    s(
        { trig = 'mst', dscr = '[M]utt [s]lides [t]emplate' },
        fmta(
            [[
#import "@local/mutt-slides:0.1.0": *

#show: mutt-slides.with(
  language: "<>",
  title: [<>],
  subtitle: [<>],
  author: [<>],
  eyebrow: [<>],
  date: datetime.today(),
)

= <>

== <>

<>
            ]],
            {
                c(1, { t('es'), t('en') }),
                i(2, 'Presentation title'),
                i(3, 'Subtitle'),
                i(4, 'Pedro Ferrari'),
                i(5, 'MUTTDATA × CLIENT'),
                i(6, 'Section'),
                i(7, 'Slide title'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Standalone figure
    s(
        { trig = 'sft', dscr = '[S]tandalone CeTZ [f]igure [t]emplate' },
        fmta(
            [[
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
                i(1, 'auto'),
                i(2, '3pt'),
                i(3, 'none'),
                i(4, 'line((0, 0), (4, 0), stroke: rgb("#000080") + 1.5pt)'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),

    -- Standalone table
    s(
        { trig = 'stt', dscr = '[St]andalone [t]able template' },
        fmta(
            [[
#import "@local/standalone:0.1.0": *
#import "@local/template-utils:0.1.0": latex-table

#show: standalone.with(
  width: <>,
  margin: <>,
  fill: <>,
)

#latex-table(
  columns: <>,
  align: <>,
  inset: (x: 6pt, y: 3.5pt),
  header: ([<>], [<>], [<>]),
  rows: (
    ([<>], [<>], [<>]),
  ),
)
            ]],
            {
                i(1, '14cm'),
                i(2, '3pt'),
                i(3, 'none'),
                i(4, '(2fr, 1fr, 1fr)'),
                i(5, '(left, right, right)'),
                i(6, 'Indicator'),
                i(7, '2020'),
                i(8, '2025'),
                i(9, 'Productivity'),
                i(10, '100'),
                i(0, '114'),
            }
        ),
        { condition = line_begin }
    ),
}, {}
