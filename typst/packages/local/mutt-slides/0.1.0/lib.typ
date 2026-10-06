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
#let border-gray = rgb("#D9E0ED")
#let muted = rgb("#53627A")

// Images in assets/ come from the Muttdata Google Slides template
// 1_dE4_JqjIfj-aL30WJvxpV0YCgoPbJsQHOr8z1gJHCo

// Section and appendix numbering
#let _appendix-mode = state("mutt-slides-appendix", false)

#let _slide-section-info(location) = {
  let sections = query(heading.where(level: 1).before(location))
  if sections.len() == 0 {
    return (heading: none, appendix: false, number: 0)
  }
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

// Chips, slide titles, and footers
#let chip(body, accent: mutt-blue) = box(
  fill: accent.lighten(92%),
  inset: (x: 10pt, y: 5pt),
  radius: 20pt,
)[#text(size: 10pt, weight: "bold", fill: accent, body)]

// Metadata keeps the chip in the header without taking body space
#let slide-chip(body) = [#metadata(body) <mutt-slide-chip>]

#let _slide-title(self, font-size: _default-font-size) = context {
  let chips = query(<mutt-slide-chip>).filter(
    it => it.location().page() == here().page(),
  )
  let has-chip = chips.len() > 0
  block(width: 100%, height: 60pt)[
    #set align(top + left)
    #grid(
      columns: if has-chip { (28pt, 1fr, auto) } else { (28pt, 1fr) },
      column-gutter: 9pt,
      align: left + top,
      move(dy: 3pt, image("assets/toggle.png", width: 28pt)),
      text(
        size: _scaled-size(24pt, font-size),
        weight: "bold",
        fill: mutt-blue,
        utils.display-current-heading(level: 2, depth: self.slide-level),
      ),
      ..if has-chip { (chip(chips.first().value),) } else { () },
    )
  ]
}

#let _deck-footer(font-size, slide-numbers: false) = context {
  grid(
    columns: if slide-numbers { (1fr, auto, auto) } else { (1fr, auto) },
    column-gutter: 12pt,
    align: left + horizon,
    line(length: 100%, stroke: 0.6pt + mutt-blue),
    // The source image includes transparent padding around the wordmark
    block(width: 64pt, height: 11pt, clip: true)[
      #place(top + left, dx: -36.7pt, dy: -33.3pt)[
        #box(width: 137.4pt, height: 77.3pt)[
          #image("assets/wordmark.png", width: 100%)
        ]
      ]
    ],
    ..if slide-numbers {
      (
        text(size: _scaled-size(8pt, font-size), fill: muted)[
          #utils.slide-counter.display()/#utils.last-slide-number
        ],
      )
    } else { () },
  )
}

#let _vertical-center(..bodies) = align(
  horizon,
  bodies.pos().sum(default: none),
)

// Agenda and section dividers
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
        font: "DM Mono",
        size: _scaled-size(23pt, font-size),
        fill: if cover { muted } else { mutt-blue },
        label,
      ),
      text(
        size: _scaled-size(22pt, font-size),
        weight: if cover { "regular" } else { "bold" },
        fill: if cover { muted } else { mutt-blue },
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

#let _agenda-body(
  font-size: _default-font-size,
  title: auto,
  progressive: false,
) = grid(
  columns: (0.75fr, 1.7fr),
  gutter: 30pt,
  align: top + left,
  text(size: _scaled-size(30pt, font-size), weight: "bold", fill: mutt-blue)[
    #localized-title(title, [Agenda], [Agenda]) ›
  ],
  if progressive {
    components.progressive-outline(
      level: 1,
      alpha: 100%,
      transform: _agenda-entry.with(font-size: font-size),
      title: none,
      depth: 1,
    )
  } else [
    #show outline.entry: it => _agenda-entry(font-size: font-size, it)
    #outline(title: none, depth: 1)
  ],
)

#let _section-divider(
  config: (:),
  body,
  font-size: _default-font-size,
  style: "agenda",
) = if style == "agenda" {
  centered-slide(
    config: utils.merge-dicts(config, config-page(fill: white, header: none)),
    [
      #reset-numbering()
      #_agenda-body(font-size: font-size, progressive: true)
      #body
    ],
  )
} else {
  centered-slide(
    config: utils.merge-dicts(config, config-page(
      margin: 0pt,
      header: none,
      footer: none,
      background: image(
        "assets/divider-background.png",
        width: 100%,
        height: 100%,
      ),
    )),
    [
      #reset-numbering()
      #place(top + left, dx: 32pt, dy: 74pt)[
        #text(size: 34pt, fill: white)[›]
        #context {
          let section = _slide-section-info(here())
          if section.appendix {
            text(size: _scaled-size(22pt, font-size), fill: white)[
              #localized([Apéndice], [Appendix])
              #numbering("A", section.number)
            ]
          }
        }
      ]
      #place(top + left, dx: 32pt, dy: 133pt)[
        #block(width: 440pt)[
          #set align(left)
          #text(
            size: _scaled-size(38pt, font-size),
            fill: white,
            utils.display-current-heading(level: 1, depth: 1),
          )
        ]
      ]
      #body
    ],
  )
}

#let agenda(title: auto) = centered-slide(
  config: config-page(fill: white, header: none),
  context _agenda-body(font-size: text.size, title: title),
)

// Cover slide
#let _branded-title-slide(
  title: none,
  subtitle: none,
  cover-chip: none,
  eyebrow: none,
  date: none,
  font-size: _default-font-size,
) = title-slide(
  config: utils.merge-dicts(
    config-common(freeze-slide-counter: false),
    config-page(margin: 0pt, header: none, footer: none),
  ),
)[
  #place(top + left)[
    #image("assets/cover-background.png", width: 100%, height: 330pt)
  ]
  #place(top + right)[#image("assets/cover-art.png", height: 405pt)]
  #place(top + left, dx: 28pt, dy: 0pt)[
    #image("assets/logo.png", width: 150pt)
  ]
  // The date sits at the bottom of the text block and moves down only when a
  // long title and subtitle would otherwise overlap it
  #place(top + left, dx: 32pt, dy: 118pt)[
    #block(width: 440pt, height: 257pt)[
      #set align(left)
      // Use only the explicit gaps below between cover elements
      #set par(spacing: 0pt)
      #if optional-value-present(eyebrow) {
        text(size: 11pt, weight: "bold", fill: mutt-navy, eyebrow)
        v(16pt)
      }
      #text(
        size: _scaled-size(38pt, font-size),
        weight: "bold",
        fill: mutt-blue,
        title,
      )
      #if optional-value-present(cover-chip) {
        v(20pt)
        chip(cover-chip)
      }
      #if optional-value-present(subtitle) {
        v(18pt)
        text(size: _scaled-size(17pt, font-size), fill: mutt-navy, subtitle)
      }
      #if optional-value-present(date) {
        v(1fr)
        text(size: 10pt, fill: mutt-blue, date)
      }
    ]
  ]
]

// Theorems, solutions, and proofs
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
  caption: if optional-value-present(note) { note } else { none },
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

// Cards, callouts, and text helpers
#let card(
  title,
  body,
  fill: pale-blue,
  accent: mutt-blue,
  height: auto,
  variant: "rounded",
) = {
  let rule-color = if fill == soft-gray { muted } else { accent }
  let surface = if variant == "soft" {
    fill.lighten(35%)
  } else {
    white
  }
  let frame = if variant == "bar" {
    (
      top: 6pt + rule-color,
      right: 1.4pt + rule-color,
      bottom: 1.4pt + rule-color,
      left: 1.4pt + rule-color,
    )
  } else if variant == "open" {
    1.2pt + rule-color.lighten(15%)
  } else {
    1.4pt + rule-color
  }
  let padding = if variant == "open" { (x: 5pt, y: 3pt) } else if (
    variant == "panel"
  ) {
    (x: 16pt, top: 28pt, bottom: 16pt)
  } else { 13pt }
  block(
    width: 100%,
    height: height,
    fill: surface,
    inset: padding,
    radius: if variant == "rounded" {
      (top-left: 12pt, top-right: 48pt, bottom-left: 48pt, bottom-right: 12pt)
    } else { 14pt },
    stroke: frame,
  )[
    #align(top)[
      #set text(fill: mutt-navy)
      #show strong: set text(fill: mutt-navy)
      #if variant == "panel" {
        place(top + center, dy: -40pt, box(
          width: 82%,
          fill: white,
          stroke: 1.4pt + rule-color,
          radius: 20pt,
          inset: (x: 10pt, y: 6pt),
          align(center, text(weight: "bold", fill: rule-color, title)),
        ))
        body
      } else {
        stack(
          dir: ttb,
          spacing: 10pt,
          ..if variant in ("outline", "soft", "open") {
            (line(length: 26pt, stroke: 3pt + rule-color), 8pt)
          } else { () },
          text(size: 16em / 14, weight: "bold", fill: rule-color, title),
          body,
        )
      }
      #if variant == "rounded" {
        place(bottom + right, text(size: 22pt, fill: rule-color)[↘])
      }
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
  fill: pale-blue,
  inset: 18pt,
  radius: 12pt,
)[
  #align(center)[#body]
]

#let slide-subtitle(body) = text(
  size: 18em / 14,
  weight: "bold",
  fill: muted,
  body,
)

#let small(body) = text(size: 11.5em / 14, fill: muted, body)

// Card grids and sequences
#let card-grid(items, columns: auto, variant: "rounded", height: 230pt) = {
  let count = items.len()
  let columns = if columns == auto {
    if count <= 3 { count } else if count == 4 { 2 } else { 3 }
  } else { columns }
  let rows = calc.ceil(count / columns)
  block(width: 100%, height: height)[
    #grid(
      columns: (1fr,) * columns,
      rows: (1fr,) * rows,
      gutter: 16pt,
      ..items.map(item => card(
        item.title,
        item.body,
        accent: item.at("accent", default: mutt-blue),
        fill: item.at("fill", default: pale-blue),
        variant: variant,
        height: 100%,
      )),
    )
  ]
}

#let timeline(items) = grid(
  columns: (1fr,) * items.len(),
  column-gutter: 8pt,
  ..items
    .enumerate()
    .map(((i, item)) => {
      let accent = (mutt-blue, mutt-purple, rgb("#1700B5")).at(calc.rem(i, 3))
      stack(
        dir: ttb,
        spacing: 14pt,
        align(center, box(
          width: 80%,
          fill: accent,
          radius: 20pt,
          inset: 5pt,
          align(center, text(fill: white, weight: "bold", item.title)),
        )),
        block(width: 100%, height: 14pt)[
          #place(left + horizon)[
            #line(length: 100%, stroke: 4pt + accent)
          ]
          #place(center + horizon)[
            #circle(radius: 6pt, fill: accent, stroke: 2pt + white)
          ]
        ],
        block(inset: (x: 8pt), item.body),
      )
    }),
)

#let process(items, height: 200pt) = {
  let cells = ()
  for (i, item) in items.enumerate() {
    if i > 0 {
      cells.push(box(height: height, align(horizon, text(
        size: 22pt,
        fill: mutt-blue,
      )[›])))
    }
    cells.push(block(
      width: 100%,
      height: height,
      fill: pale-blue,
      radius: 12pt,
      inset: 14pt,
    )[
      #circle(radius: 16pt, fill: mutt-blue)[
        #align(center + horizon, text(fill: white, weight: "bold", str(i + 1)))
      ]
      #v(16pt)
      #text(size: 16em / 14, weight: "bold", fill: mutt-blue, item.title)
      #v(10pt)
      #item.body
    ])
  }
  grid(
    columns: (1fr,) + (16pt, 1fr) * (items.len() - 1),
    gutter: 8pt,
    align: top + left,
    ..cells,
  )
}

// Metrics, comparisons, and formula definitions
#let metric(value, title, body: none, accent: mutt-blue) = block(
  width: 100%,
  fill: accent.lighten(94%),
  radius: 12pt,
  inset: 18pt,
)[
  #text(size: 36em / 14, weight: "bold", fill: accent, value)
  #v(12pt)
  #text(weight: "bold", fill: mutt-navy, title)
  #if optional-value-present(body) {
    v(8pt)
    small(body)
  }
]

#let metrics(items) = grid(
  columns: (1fr,) * items.len(),
  gutter: 16pt,
  ..items.map(item => metric(
    item.value,
    item.title,
    body: item.at("body", default: none),
    accent: item.at("accent", default: mutt-blue),
  )),
)

#let comparison(headers, rows, columns: auto) = table(
  columns: if columns == auto { (1fr,) * headers.len() } else { columns },
  fill: (_, y) => if y == 0 { mutt-blue } else if calc.odd(y) {
    pale-blue
  } else { white },
  stroke: (bottom: 0.6pt + border-gray),
  inset: 12pt,
  table.header(..headers.map(it => text(weight: "bold", fill: white, it))),
  ..rows.flatten(),
)

#let formula-definitions(expression, definitions) = stack(
  dir: ttb,
  spacing: 26pt,
  formula(text(size: 26em / 14, expression)),
  grid(
    columns: (1fr,) * definitions.len(),
    gutter: 22pt,
    ..definitions.map(item => [
      #block(
        width: 100%,
        inset: (bottom: 6pt),
        stroke: (bottom: 0.8pt + mutt-blue),
      )[
        #text(font: "DM Mono", size: 16em / 14, fill: mutt-blue, item.title)
      ]
      #v(10pt)
      #small(item.body)
    ]),
  ),
)

// Document template
#let mutt-slides(
  language: "es",
  font-size: _default-font-size,
  title: none,
  subtitle: none,
  cover-chip: none,
  slide-numbers: false,
  section-style: "agenda",
  author: [Pedro Ferrari],
  eyebrow: none,
  date: datetime.today(),
  // Overridden at the document call site for filename-based bibliographies
  bibliography-read: read-mybibstyle,
  body,
) = {
  let date = localized-date(date, language)

  // Theme and page layout
  show: simple-theme.with(
    aspect-ratio: "16-9",
    header: _slide-title.with(font-size: font-size),
    header-right: none,
    footer: _deck-footer(font-size, slide-numbers: slide-numbers),
    footer-right: none,
    subslide-preamble: none,
    config-page(
      width: 720pt,
      height: 405pt,
      margin: (top: 84pt, bottom: 44pt, left: 26pt, right: 26pt),
      header-ascent: -4pt,
      footer-descent: 12pt,
    ),
    config-common(
      new-section-slide-fn: _section-divider.with(
        font-size: font-size,
        style: section-style,
      ),
      default-composer: _vertical-center,
      // Keep theorem numbers stable across overlay pages of one slide
      frozen-counters: (counter(figure.where(kind: "theorem")),),
      show-strong-with-alert: false,
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

  // Base typography
  set text(
    font: "DM Sans 9pt",
    fill: mutt-navy,
    size: font-size,
    lang: language,
  )
  set smartquote(quotes: curly-double-quotes)

  // Bibliography and backreferences
  show: apply-mybibstyle
  // Forward search skips bibliography backreferences to keep compilation fast
  show: if "sync" in sys.inputs { doc => doc } else {
    backrefs.with(
      // Use slide numbers and merge repeated citations across overlays
      format: links => format-bibliography-backrefs(
        links
          .map(it => link(
            it.dest,
            str(utils.slide-counter.at(it.dest).first()),
          ))
          .dedup(key: it => it.body),
      ),
      read: retrofit-reader(bibliography-read),
    )
  }
  show bibliography: set heading(offset: 2, outlined: false)
  show bibliography: set block(spacing: bibliography-entry-spacing)

  // Code and emphasis
  show: code-style.with(size: _scaled-size(13pt, font-size))
  show strong: set text(fill: mutt-navy)
  show emph: set text(fill: muted)

  // Cross-references
  show ref: it => context {
    let targets = query(it.target)
    if targets.len() == 0 {
      text(fill: mutt-blue, it)
    } else if (
      it.form == "normal"
        and targets.first().func() in (math.equation, figure)
        and targets.first().numbering != none
    ) {
      let target = targets.first()
      let target-counter = if target.func() == math.equation {
        counter(math.equation)
      } else {
        target.counter
      }
      let n = target-counter.at(target.location()).last()
      let supplement = if it.supplement == auto {
        target.supplement
      } else if type(it.supplement) == function {
        (it.supplement)(target)
      } else { it.supplement }
      if optional-value-present(supplement) { supplement + [ ] }
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

  // Lists and footnotes
  set list(indent: 17pt, body-indent: 8pt, spacing: auto)
  set enum(indent: 19pt, body-indent: 8pt, spacing: auto)
  set footnote.entry(separator: none)
  show footnote.entry: set text(size: _scaled-size(9pt, font-size))

  // Tables, figures, equations, and theorems
  set table(stroke: 1pt + rgb("#CBD3E1"), inset: 7pt)
  show table: it => align(center, it)
  set figure(numbering: n => _slide-numbering(n), gap: 5pt)
  show figure.caption: none
  set math.equation(
    numbering: none,
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
    cover-chip: cover-chip,
    eyebrow: eyebrow,
    date: date,
    font-size: font-size,
  )
  body
}
