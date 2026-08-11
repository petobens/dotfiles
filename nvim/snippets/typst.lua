local ls = require('luasnip')

local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet

local fmta = require('luasnip.extras.fmt').fmta
local line_begin = require('luasnip.extras.expand_conditions').line_begin

return {
    s(
        { trig = 'presentation', dscr = 'Muttdata Touying presentation' },
        fmta(
            [[
#import "@preview/touying:0.7.4": *
#import themes.metropolis: *

#let mutt-blue = rgb("#0045FB")
#let mutt-navy = rgb("#001237")
#let mutt-cyan = rgb("#00ECFF")
#let mutt-purple = rgb("#886AFF")

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-colors(
    primary: mutt-blue,
    secondary: mutt-navy,
    tertiary: mutt-purple,
    neutral-lightest: white,
    neutral-darkest: mutt-navy,
  ),
  config-info(
    title: [<>],
    subtitle: [<>],
    author: [<>],
    date: datetime.today(),
  ),
)

#set text(font: "Arial", fill: mutt-navy)
#show raw: set text(font: "Source Code Pro")
#show strong: set text(fill: mutt-blue)

#title-slide()

= <>

== <>

<>
            ]],
            {
                i(1, 'Presentation title'),
                i(2, 'Subtitle'),
                i(3, 'Muttdata'),
                i(4, 'Section'),
                i(5, 'Slide title'),
                i(0),
            }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'slide', dscr = 'Touying slide' },
        fmta(
            [[
== <>

<><>
            ]],
            { i(1, 'Slide title'), f(_G.LuaSnipConfig.visual_selection), i(0) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'section', dscr = 'Touying section' },
        fmta(
            [[
= <>
            ]],
            { i(1, 'Section') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'cols', dscr = 'Touying two-column layout' },
        fmta(
            [[
#cols(
  columns: (1fr, 1fr),
  gutter: 1em,
)[
  <>
][
  <>
]
            ]],
            { i(1, 'Left column'), i(2, 'Right column') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'card', dscr = 'Muttdata card' },
        fmta(
            [[
#block(
  fill: mutt-blue.lighten(92%),
  inset: 18pt,
  radius: 10pt,
)[
  *<>*

  <>
]
            ]],
            { i(1, 'Card title'), i(2, 'Card content') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'speaker', dscr = 'Touying speaker notes' },
        fmta(
            [[
#speaker-note[
  - <>
]
            ]],
            { i(1, 'Speaker note') }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'pause', dscr = 'Touying incremental reveal' },
        fmta(
            [[
#pause
<>
            ]],
            { i(0) }
        ),
        { condition = line_begin }
    ),
    s(
        { trig = 'fig', dscr = 'Typst figure' },
        fmta(
            [[
#figure(
  image("<>", width: <>%),
  caption: [<>],
)
            ]],
            { i(1, 'image.png'), i(2, '80'), i(3, 'Caption') }
        ),
        { condition = line_begin }
    ),
}, {}
