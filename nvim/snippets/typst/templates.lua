local ls = require('luasnip')

local c = ls.choice_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local function static_choice(value)
    return sn(nil, { t(value), i(1) })
end

return {
    -- Minimal working example
    s(
        { trig = 'mwe', dscr = '[M]inimal [w]orking [e]xample' },
        fmta(
            [[
#import "@local/latex-article:0.1.0": *

#show: latex-article.with(
  font-size: <>,
  title: [<>],
  abstract: none,
)

= <>
<<sec:<>>>

<>
            ]],
            {
                i(1, '11pt'),
                i(2, 'Article title'),
                i(3, 'Section'),
                f(_G.LuaSnipConfig.snake_case_labels, { 3 }),
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
  font-size: <>,
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
                i(2, '11pt'),
                i(3, 'Article title'),
                i(4, 'Author'),
                c(5, {
                    sn(nil, { t('['), i(1, 'Author affiliation or note'), t(']') }),
                    static_choice('none'),
                }),
                c(6, {
                    sn(nil, { t('['), i(1, 'Short article title'), t(']') }),
                    static_choice('none'),
                }),
                c(7, {
                    sn(nil, { t('['), i(1, 'Abstract'), t(']') }),
                    static_choice('none'),
                }),
                c(8, {
                    sn(nil, { t('"'), i(1, 'Keywords'), t('"') }),
                    static_choice('none'),
                }),
                c(9, {
                    sn(nil, { t('['), i(1, 'JEL codes'), t(']') }),
                    static_choice('none'),
                }),
                i(10, 'false'),
                i(11, 'Introduction'),
                f(_G.LuaSnipConfig.snake_case_labels, { 11 }),
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
  font-size: <>,
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
                i(2, '10pt'),
                i(3, 'Book title'),
                c(4, {
                    sn(nil, { t('['), i(1, 'Subtitle'), t(']') }),
                    static_choice('none'),
                }),
                i(5, 'Author'),
                c(6, {
                    sn(nil, { t('['), i(1, 'Institution'), t(']') }),
                    static_choice('none'),
                }),
                c(7, {
                    sn(nil, { t('['), i(1, 'Department'), t(']') }),
                    static_choice('none'),
                }),
                c(8, {
                    sn(nil, {
                        t('read("'),
                        i(1),
                        t('", encoding: none)'),
                    }),
                    static_choice('none'),
                }),
                c(9, {
                    sn(nil, {
                        t('['),
                        i(1, '© Author. All rights reserved.'),
                        t(']'),
                    }),
                    static_choice('none'),
                }),
                c(10, {
                    sn(nil, { t('['), i(1, 'Dedication'), t(']') }),
                    static_choice('none'),
                }),
                i(11, 'true'),
                c(12, {
                    sn(nil, { t('include "'), i(1, 'preface.typ'), t('"') }),
                    static_choice('none'),
                }),
                i(13, 'false'),
                i(14, 'First chapter'),
                f(_G.LuaSnipConfig.snake_case_labels, { 14 }),
                i(15, 'First section'),
                f(_G.LuaSnipConfig.snake_case_labels, { 15 }),
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
  font-size: <>,
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
                i(2, '14pt'),
                i(3, 'Presentation title'),
                i(4, 'Subtitle'),
                i(5, 'Presenter'),
                i(6, 'Organization'),
                i(7, 'Section'),
                i(8, 'Slide title'),
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
        { trig = 'stt', dscr = '[St]andalone [t]able (latex-table)' },
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
                i(6, 'Header 1'),
                i(7, 'Header 2'),
                i(8, 'Header 3'),
                i(9, 'Value 1'),
                i(10, 'Value 2'),
                i(0, 'Value 3'),
            }
        ),
        { condition = line_begin }
    ),
}, {}
