#import "@preview/touying:0.7.4": *
#import "@preview/retrofit:0.2.0": backrefs
#import themes.simple: *
#import "@local/template-utils:0.1.0": *

// Font sizes: scale all text roles from the 14pt baseline
#let _default-font-size = 14pt
#let _scaled-size(size, font-size) = size / _default-font-size * font-size

// Palette
#let mutt-blue = rgb("#0045FB")
#let mutt-navy = rgb("#001237")
#let mutt-cyan = rgb("#00ECFF")
#let mutt-purple = rgb("#886AFF")
#let pale-blue = mutt-blue.lighten(93%)
#let pale-cyan = mutt-cyan.lighten(88%)
#let pale-purple = mutt-purple.lighten(91%)
#let soft-gray = rgb("#F3F5F8")
#let chip-gray = rgb("#D9DEE7")
#let border-gray = rgb("#D9E0ED")
#let muted = rgb("#53627A")

// Slide chrome
#let _appendix-mode = state("mutt-slides-appendix", false)

#let _slide-section-info(location) = {
  let sections = query(heading.where(level: 1).before(location))
  let current = sections.last()
  let appendix = _appendix-mode.at(current.location())
  let number = sections
    .filter(
      section => _appendix-mode.at(section.location()) == appendix,
    )
    .len()
  (heading: current, appendix: appendix, number: number)
}

#let _slide-numbering(n, parentheses: false, location: none) = context {
  let target = if location == none { here() } else { location }
  let section = _slide-section-info(target)
  let pattern = if section.appendix {
    if parentheses { "(A.1)" } else { "A.1" }
  } else if parentheses {
    "(1.1)"
  } else {
    "1.1"
  }
  numbering(pattern, section.number, n)
}

#let equation = equation-environment(
  n => _slide-numbering(n, parentheses: true),
)

#let _toggle-icon = box(
  width: 23pt,
  height: 13pt,
  stroke: 1.5pt + mutt-blue,
  radius: 7pt,
  inset: 1.5pt,
)[
  #align(right + horizon)[#circle(radius: 4.5pt, fill: mutt-blue)]
]

#let _section-chip-width = 128pt

#let _section-chip(self, font-size) = block(
  width: _section-chip-width,
  fill: chip-gray,
  inset: (x: 7pt, y: 5pt),
  radius: 6pt,
  stroke: 0.9pt + border-gray.darken(8%),
)[
  #align(center)[
    #text(
      size: _scaled-size(9pt, font-size),
      weight: "bold",
      fill: mutt-navy,
      context {
        let section = _slide-section-info(here())
        if section.appendix {
          [#localized([Apéndice], [Appendix]) #numbering(
              "A.",
              section.number,
            ) #section.heading.body]
        } else {
          section.heading.body
        }
      },
    )
  ]
]

#let _slide-title(self, font-size: _default-font-size) = move(dy: 25pt, block(
  width: 100%,
  height: 26.4pt,
)[
  #set align(top + left)
  #grid(
    columns: (auto, 1fr, _section-chip-width),
    column-gutter: 8pt,
    align: (left + top, left + top, right + top),
    move(dy: 4pt, _toggle-icon),
    text(
      size: _scaled-size(23pt, font-size),
      weight: "bold",
      fill: mutt-blue,
      utils.display-current-heading(level: 2, depth: self.slide-level),
    ),
    move(dy: 4pt, _section-chip(self, font-size)),
  )
])

#let _deck-footer(font-size) = context {
  box(width: 100%)[
    #move(dy: -4pt)[
      #grid(
        columns: (1fr, auto),
        column-gutter: 4pt,
        align: (left + top, right + top),
        move(
          dy: 6pt,
          line(length: 100%, stroke: 1pt + mutt-blue),
        ),
        [
          #align(right)[
            #text(
              size: _scaled-size(14pt, font-size),
              weight: "medium",
              tracking: 0.2pt,
              fill: mutt-blue,
            )[Muttdata]
            #linebreak()
            #text(size: _scaled-size(9pt, font-size), fill: mutt-navy)[
              #utils.slide-counter.display()/#utils.last-slide-number
            ]
          ]
        ],
      )
    ]
  ]
}

#let _vertical-center(..bodies) = align(
  horizon,
  bodies.pos().sum(default: none),
)

// Agenda and title slides
#let _agenda-entry(font-size: _default-font-size, cover: false, ..args, it) = {
  let sections = query(heading.where(level: 1, outlined: true))
  let is-appendix(section) = _appendix-mode.at(section.location())
  let appendices = sections.filter(is-appendix)
  let number = (
    sections.position(section => (
      section.location() == it.element.location()
    ))
      + 1
  )
  let label = if is-appendix(it.element) {
    let appendix-number = (
      appendices.position(section => (
        section.location() == it.element.location()
      ))
        + 1
    )
    numbering("A.", appendix-number)
  } else {
    numbering("01.", number)
  }
  link(it.element.location(), block(
    width: 100%,
    inset: (y: 8pt),
    stroke: (bottom: 0.8pt + mutt-navy.lighten(85%)),
  )[
    #grid(
      columns: (42pt, 1fr),
      column-gutter: 12pt,
      align: (left + horizon, left + horizon),
      text(
        font: "DejaVu Sans Mono",
        size: _scaled-size(23pt, font-size),
        fill: if cover { mutt-navy.lighten(45%) } else { mutt-blue },
        label,
      ),
      text(
        size: _scaled-size(22pt, font-size),
        weight: if cover { "regular" } else { "bold" },
        fill: if cover { mutt-navy.lighten(45%) } else { mutt-blue },
        it.element.body,
      ),
    )
  ])
}

#let appendix(body) = {
  _appendix-mode.update(true)
  body
  _appendix-mode.update(false)
}

#let _section-divider(
  config: (:),
  body,
  font-size: _default-font-size,
) = centered-slide(
  config: utils.merge-dicts(config, config-page(fill: white, header: none)),
  [
    #reset-numbering()
    #grid(
      columns: (0.75fr, 1.7fr),
      gutter: 38pt,
      align: (top + left, top + left),
      [
        #text(
          size: _scaled-size(34pt, font-size),
          weight: "bold",
          fill: mutt-blue,
        )[Agenda]
        #h(12pt)
        #text(
          size: _scaled-size(34pt, font-size),
          weight: "bold",
          fill: mutt-blue,
        )[›]
      ],
      components.progressive-outline(
        level: 1,
        alpha: 100%,
        transform: _agenda-entry.with(font-size: font-size),
        title: none,
        depth: 1,
      ),
    )
    #body
  ],
)

#let _branded-title-slide(
  title: [],
  subtitle: [],
  eyebrow: [MUTTDATA],
  date: datetime.today(),
  font-size: _default-font-size,
) = title-slide[
  #block(
    width: 100%,
    height: 100%,
    fill: rgb("#F7F8FA"),
    inset: 28pt,
  )[
    #place(top + left, dx: -120pt, dy: -120pt)[
      #rect(width: 1100pt, height: 750pt, fill: rgb("#F7F8FA"))
    ]
    #grid(
      columns: (1.45fr, 0.7fr),
      rows: (1fr,),
      gutter: 20pt,
      grid(
        columns: (1fr,),
        rows: (auto, 1fr, auto),
        align(left)[
          #text(
            size: _scaled-size(17pt, font-size),
            weight: "bold",
            fill: mutt-navy,
          )[#eyebrow]
        ],
        align(left + horizon)[
          #text(
            size: _scaled-size(50pt, font-size),
            weight: "bold",
            fill: mutt-blue,
          )[#title]
          #v(22pt)
          #text(
            font: "DejaVu Sans Mono",
            size: _scaled-size(18pt, font-size),
            fill: mutt-blue,
          )[#subtitle]
        ],
        align(left)[
          #text(
            size: _scaled-size(11pt, font-size),
            weight: "bold",
            fill: mutt-blue,
          )[#date]
        ],
      ),
      align(center + horizon)[
        #box(width: 220pt, height: 300pt)[
          #place(top + left, dx: 42pt, dy: 14pt)[
            #rotate(
              38deg,
              rect(
                width: 125pt,
                height: 68pt,
                radius: 18pt,
                fill: chip-gray,
              ),
            )
          ]
          #place(top + left, dx: 58pt, dy: 92pt)[
            #rotate(
              -38deg,
              rect(
                width: 120pt,
                height: 70pt,
                radius: 18pt,
                fill: pale-purple.darken(5%),
              ),
            )
          ]
          #place(top + left, dx: 30pt, dy: 190pt)[
            #rect(
              width: 175pt,
              height: 92pt,
              radius: 22pt,
              fill: mutt-blue,
            )
          ]
        ]
      ],
    )
  ]
]

// Content components
#let _theorem-card(title, body) = block(
  width: 100%,
  fill: white,
  inset: 13pt,
  radius: 7pt,
  stroke: 1.4pt + mutt-blue.lighten(25%),
)[
  #align(left)[
    #set text(fill: mutt-navy)
    #line(length: 26pt, stroke: 3pt + mutt-blue)
    #v(5pt)
    #text(weight: "bold", fill: mutt-blue, title)
    #v(5pt)
    #body
  ]
]

#let theorem(body, note: none, title: auto, numbered: true) = figure(
  body,
  kind: "theorem",
  supplement: localized-title(title, [Teorema], [Theorem]),
  numbering: if numbered { n => _slide-numbering(n) } else { none },
  caption: note,
  outlined: false,
)

#let solution(body, note: none, title: auto) = theorem(
  body,
  note: note,
  title: localized-title(title, [Solución], [Solution]),
  numbered: false,
)

#let proof(body, title: auto) = block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #text(weight: "bold", fill: mutt-navy)[
    #localized-title(title, [Demostración], [Proof]).
  ] #body #h(1fr) $square$
]

#let card(
  title,
  body,
  fill: pale-blue,
  accent: mutt-blue,
  height: auto,
  variant: "outline",
) = {
  let rule-color = if fill == soft-gray { muted } else { accent }
  let border-color = rule-color.lighten(25%)
  let surface = if variant == "soft" {
    fill.lighten(35%)
  } else {
    white
  }
  let frame = if variant == "bar" {
    (
      top: 6pt + rule-color,
      right: 1.4pt + border-color,
      bottom: 1.4pt + border-color,
      left: 1.4pt + border-color,
    )
  } else if variant == "open" {
    1.2pt + rule-color.lighten(15%)
  } else {
    1.4pt + border-color
  }
  let padding = if variant == "open" { (x: 5pt, y: 3pt) } else { 13pt }
  block(
    width: 100%,
    height: height,
    fill: surface,
    inset: padding,
    radius: 7pt,
    stroke: frame,
  )[
    #align(top)[
      #set text(fill: mutt-navy)
      #show strong: set text(fill: mutt-navy)
      #if variant == "outline" or variant == "soft" or variant == "open" {
        line(length: 26pt, stroke: 3pt + rule-color)
        v(5pt)
      }
      #text(weight: "bold", fill: rule-color)[#title]
      #v(5pt)
      #body
    ]
  ]
}

#let callout(body, fill: soft-gray, accent: mutt-blue) = {
  let surface = if fill == soft-gray { white } else { fill.lighten(48%) }
  block(
    width: 100%,
    fill: surface,
    inset: 15pt,
    radius: 6pt,
    stroke: (left: 4pt + accent),
  )[
    #show strong: it => text(weight: "bold", fill: accent, it.body)
    #body
  ]
}

#let formula(body) = block(
  width: 100%,
  fill: rgb("#F8F9FC"),
  inset: 12pt,
  radius: 6pt,
  stroke: 1.5pt + rgb("#AEB8C8"),
)[#align(center)[#body]]

#let slide-subtitle(body) = text(
  size: 18em / 14,
  weight: "bold",
  fill: muted,
  body,
)

#let small(body) = text(size: 11.5em / 14, fill: muted, body)

// Document template
#let mutt-slides(
  language: "es",
  font-size: _default-font-size,
  title: [],
  subtitle: [],
  author: [Pedro Ferrari],
  eyebrow: [MUTTDATA],
  date: datetime.today(),
  // Overridden at the document call site for filename-based bibliographies
  bibliography-read: read-mybibstyle,
  body,
) = {
  let date = localized-date(date, language)

  // Theme
  show: simple-theme.with(
    aspect-ratio: "16-9",
    header: _slide-title.with(font-size: font-size),
    header-right: none,
    footer: _deck-footer(font-size),
    footer-right: none,
    subslide-preamble: none,
    config-page(
      margin: (top: 3em, bottom: 2.3em, left: 2.2em, right: 2.6em),
      footer-descent: 0em,
    ),
    config-common(
      new-section-slide-fn: _section-divider.with(font-size: font-size),
      default-composer: _vertical-center,
      reset-page-counter-to-slide-counter: false,
    ),
    config-colors(
      primary: mutt-blue,
      secondary: mutt-cyan,
      tertiary: mutt-purple,
      neutral-lightest: white,
      neutral-darkest: mutt-navy,
    ),
    config-info(
      title: title,
      subtitle: subtitle,
      author: author,
      date: date,
    ),
  )

  // Content styling
  set text(font: "Arial", fill: mutt-navy, size: font-size, lang: language)
  set smartquote(quotes: curly-double-quotes)
  show: apply-mybibstyle
  show: backrefs.with(
    format: format-bibliography-backrefs,
    read: retrofit-reader(bibliography-read),
  )
  show bibliography: set text(font: "New Computer Modern")
  show bibliography: set block(spacing: bibliography-entry-spacing)
  show: code-style.with(size: _scaled-size(13pt, font-size))
  show strong: set text(fill: mutt-blue)
  show emph: set text(fill: muted)
  show ref: it => context {
    let targets = query(it.target)
    if targets.len() == 0 {
      text(fill: mutt-blue, it)
    } else if targets.first().func() in (math.equation, figure) {
      let target = targets.first()
      let target-counter = if target.func() == math.equation {
        counter(math.equation)
      } else {
        target.counter
      }
      let n = target-counter.at(target.location()).last()
      let prefix = if target.func() == figure { target.supplement + [ ] } else {
        []
      }
      prefix
      link(
        target.location(),
        text(
          fill: mutt-blue,
          _slide-numbering(
            n,
            parentheses: target.func() == math.equation,
            location: target.location(),
          ),
        ),
      )
    } else {
      text(fill: mutt-blue, it)
    }
  }
  set list(indent: 17pt, body-indent: 8pt, spacing: 5pt)
  set enum(indent: 19pt, body-indent: 8pt, spacing: 5pt)
  set footnote.entry(separator: none)
  show footnote.entry: set text(size: _scaled-size(9pt, font-size))
  show footnote.entry: it => move(dy: 21pt, it)
  set table(stroke: 1pt + rgb("#CBD3E1"), inset: 7pt)
  show table: it => align(center, it)
  set figure(numbering: n => _slide-numbering(n), gap: 5pt)
  show figure.caption: none
  set math.equation(
    numbering: n => _slide-numbering(n, parentheses: true),
    number-align: left + horizon,
    supplement: none,
  )
  show figure.where(kind: "theorem"): it => _theorem-card(
    [
      #it.supplement
      #if it.numbering != none {
        [ #context it.counter.display(it.numbering)]
      }
      #if it.caption != none and it.caption.body != [] { [ (#it.caption.body)] }
    ],
    it.body,
  )

  // Title and slides
  _branded-title-slide(
    title: title,
    subtitle: subtitle,
    eyebrow: eyebrow,
    date: date,
    font-size: font-size,
  )
  body
}
