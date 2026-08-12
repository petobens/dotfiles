#import "@preview/subpar:0.2.2"

// Numbering and localization
#let navy = rgb("#000080")
#let appendix-mode = state("latex-article-appendix", false)

#let localized(spanish, english) = context {
  if text.lang == "es" { spanish } else { english }
}

#let localized-title(title, spanish, english) = {
  if title == auto { localized(spanish, english) } else { title }
}

#let article-numbering(n, parentheses: false) = context {
  let numbers = counter(heading).get()
  let appendix = appendix-mode.get()
  let section = if appendix {
    numbers.at(1, default: 0)
  } else {
    numbers.at(0, default: 0)
  }
  let pattern = if appendix {
    if parentheses { "(A.1)" } else { "A.1" }
  } else if parentheses {
    "(1.1)"
  } else {
    "1.1"
  }
  numbering(pattern, section, n)
}

#let reset-numbering() = {
  counter(math.equation).update(0)
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(figure.where(kind: "theorem")).update(0)
}

// Page furniture and front matter
#let article-header(short-title, author) = context {
  let page-number = counter(page).get().first()
  let running-title = if calc.even(page-number) { author } else { short-title }
  if page-number > 1 and running-title != none and running-title != [] {
    if calc.even(page-number) {
      grid(
        columns: (1fr, auto, 1fr),
        align: (left, center, right),
        text(size: 9pt, numbering("1", page-number)),
        text(size: 10pt, upper(running-title)),
        [],
      )
    } else {
      grid(
        columns: (1fr, auto, 1fr),
        align: (left, center, right),
        [],
        text(size: 10pt, upper(running-title)),
        text(size: 9pt, numbering("1", page-number)),
      )
    }
  }
}

#let article-footer = context {
  if counter(page).get().first() == 1 {
    align(center, text(size: 9pt, counter(page).display("1")))
  }
}

#let article-title(title, author, author-note, date) = block(
  width: 100%,
  breakable: false,
  below: 3em,
)[
  #set text(hyphenate: false)
  #set par(justify: false, first-line-indent: 0pt)
  #align(center)[
    #text(size: 20.74pt, weight: "bold")[#title]
    #v(1.65em)
    #text(size: 14.4pt)[
      #smallcaps(author)
      #if author-note != none {
        footnote(author-note, numbering: _ => [†])
      }
    ]
    #v(1em)
    #date
  ]
]

#let article-abstract(
  abstract,
  keywords: none,
  jel: none,
  language: "es",
) = block(
  width: 100%,
  above: 0pt,
  below: 3.5em,
  inset: (x: 1.5em),
)[
  #set text(size: 9pt)
  #set par(first-line-indent: 0pt)
  #align(center)[*Abstract*]
  #v(0.5em)
  #abstract
  #if keywords != none {
    parbreak()
    v(0.45em)
    strong(if language == "es" { [Palabras Clave: ] } else { [Keywords: ] })
    emph(keywords)
  }
  #if jel != none {
    parbreak()
    strong(
      if language == "es" { [Clasificación JEL: ] } else {
        [JEL Classification: ]
      },
    )
    emph(jel)
  }
]

// Tables and subfigures
#let article-table(columns, header, rows, align: auto) = table(
  columns: columns,
  align: align,
  inset: (x: 6pt, y: 3.5pt),
  stroke: none,
  table.hline(stroke: 0.8pt),
  table.header(..header),
  table.hline(stroke: 0.45pt),
  ..rows.flatten(),
  table.hline(stroke: 0.8pt),
)

#let subfigure(body, caption: none, label: none) = (
  body: body,
  caption: caption,
  label: label,
)

#let subfigures(..children) = {
  let children = children.pos()
  grid(
    columns: array.range(children.len()).map(_ => 1fr),
    gutter: 1em,
    ..children
      .enumerate()
      .map(((index, child)) => block(width: 100%)[
        #align(center, child.body)
        #if child.caption != none {
          v(0.35em)
          align(center, text(size: 9pt)[
            (#numbering("a", index + 1)) #child.caption
          ])
        }
      ]),
  )
}

#let subfigure-grid(
  ..children,
  caption: none,
  label: none,
  placement: none,
) = {
  let children = children.pos()
  let figures = ()
  for child in children {
    figures.push(figure(child.body, caption: child.caption))
    if child.label != none { figures.push(child.label) }
  }
  subpar.grid(
    ..figures,
    columns: array.range(children.len()).map(_ => 1fr),
    caption: caption,
    label: label,
    placement: placement,
    numbering: n => article-numbering(n),
    numbering-sub: "(a)",
    numbering-sub-ref: (n, sub) => [#article-numbering(n)#numbering("a", sub)],
  )
}

// Theorem environments
#let statement(
  supplement,
  body,
  note: none,
  italic: false,
  numbered: true,
) = figure(
  if italic { emph(body) } else { body },
  kind: "theorem",
  supplement: supplement,
  numbering: if numbered { n => article-numbering(n) } else { none },
  caption: if note == none { [] } else { note },
  outlined: false,
  gap: 0.35em,
)

#let show-statement(it) = align(left, block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #strong[
    #it.supplement
    #if it.numbering != none { [ #context it.counter.display(it.numbering)] }
    #if it.caption != none and it.caption.body != [] { [ (#it.caption.body)] }
  ] #it.body
])

#let theorem(body, note: none, title: auto, numbered: true) = statement(
  localized-title(title, [Teorema], [Theorem]),
  body,
  note: note,
  italic: true,
  numbered: numbered,
)
#let proposition(
  body,
  note: none,
  title: auto,
  numbered: true,
) = statement(
  localized-title(title, [Proposición], [Proposition]),
  body,
  note: note,
  italic: true,
  numbered: numbered,
)
#let lemma(body, note: none, title: auto, numbered: true) = statement(
  localized-title(title, [Lema], [Lemma]),
  body,
  note: note,
  italic: true,
  numbered: numbered,
)
#let corollary(
  body,
  note: none,
  title: auto,
  numbered: true,
) = statement(
  localized-title(title, [Corolario], [Corollary]),
  body,
  note: note,
  italic: true,
  numbered: numbered,
)
#let definition(
  body,
  note: none,
  title: auto,
  numbered: true,
) = statement(
  localized-title(title, [Definición], [Definition]),
  body,
  note: note,
  numbered: numbered,
)
#let example(body, note: none, title: auto, numbered: true) = statement(
  localized-title(title, [Ejemplo], [Example]),
  body,
  note: note,
  numbered: numbered,
)
#let exercise(body, note: none, title: auto, numbered: true) = statement(
  localized-title(title, [Ejercicio], [Exercise]),
  body,
  note: note,
  numbered: numbered,
)
#let remark(body, note: none, title: auto, numbered: true) = statement(
  emph(localized-title(title, [Observación], [Remark])),
  body,
  note: note,
  numbered: numbered,
)
#let notation(body, note: none, title: auto, numbered: true) = statement(
  emph(localized-title(title, [Notación], [Notation])),
  body,
  note: note,
  numbered: numbered,
)

#let solution(body, note: none, title: auto) = statement(
  localized-title(title, [Solución], [Solution]),
  body,
  note: note,
  numbered: false,
)

#let proof(body, title: auto) = block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #emph(localized-title(title, [Demostración], [Proof])). #body #h(1fr) $square$
]

// Sections and appendices
#let heading-title(it) = context {
  if it.numbering != none {
    numbering(it.numbering, ..counter(heading).at(it.location()))
    h(0.8em)
  }
  it.body
}

#let appendix(title: auto, body) = {
  pagebreak(weak: true)
  appendix-mode.update(true)
  heading(level: 1, numbering: none, localized-title(
    title,
    [Apéndice],
    [Appendix],
  ))
  counter(heading).update((0, 0))
  set heading(numbering: (..numbers) => numbering("A", numbers.pos().last()))
  body
}

// Document template
#let latex-article(
  title: [],
  author: "Pedro Ferrari",
  author-note: none,
  date: datetime.today().display(),
  metadata-date: auto,
  short-title: none,
  language: "es",
  abstract: none,
  keywords: none,
  jel: none,
  toc: false,
  body,
) = {
  set document(
    title: title,
    author: author,
    description: abstract,
    keywords: if keywords == none { () } else { keywords },
    date: metadata-date,
  )
  set page(
    paper: "a4",
    binding: left,
    numbering: "1",
    margin: (top: 3.7cm, bottom: 5cm, inside: 3.5cm, outside: 3.5cm),
    header: article-header(short-title, author),
    header-ascent: 25%,
    footer: article-footer,
    footer-descent: 30%,
  )
  set text(
    font: "New Computer Modern",
    size: 10pt,
    lang: language,
    hyphenate: auto,
  )
  show math.equation: set text(font: "New Computer Modern Math")
  show raw: set text(font: "DejaVu Sans Mono", size: 9pt)
  show link: set text(fill: navy)
  show ref: set text(fill: navy)
  show cite: set text(fill: navy)
  show bibliography: set text(size: 9pt)
  set par(
    leading: 0.55em,
    spacing: 0.55em,
    first-line-indent: 15pt,
    justify: true,
  )
  set block(spacing: 1.2em)
  set heading(numbering: "1.1")
  set math.equation(
    numbering: n => article-numbering(n, parentheses: true),
    number-align: left + horizon,
    supplement: none,
  )
  set figure(numbering: n => article-numbering(n), gap: 5pt)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "theorem"): show-statement
  show figure.caption: it => {
    set text(size: 9pt)
    if it.kind == table {
      align(center)[
        #strong[#it.supplement #context it.counter.display(it.numbering)]
        #linebreak()
        #it.body
      ]
    } else if it.kind != "theorem" {
      align(center)[
        #strong[#it.supplement #context it.counter.display(it.numbering)]
        #h(1em)
        #it.body
      ]
    }
  }
  show heading.where(level: 1): it => {
    reset-numbering()
    block(above: 1.5em, below: 1em)[
      #set text(size: 14.4pt, weight: "bold")
      #heading-title(it)
    ]
  }
  show heading.where(level: 2): it => {
    context if appendix-mode.get() { reset-numbering() }
    block(above: 1.4em, below: 0.65em)[
      #set text(size: 12pt, weight: "bold")
      #heading-title(it)
    ]
  }
  show heading.where(level: 3): it => block(above: 1.4em, below: 0.65em)[
    #set text(size: 10pt, weight: "bold")
    #heading-title(it)
  ]
  set footnote.entry(indent: 15pt)
  show footnote.entry: set text(size: 8pt)
  set outline(indent: 1.5em)

  article-title(title, author, author-note, date)
  if author-note != none { counter(footnote).update(0) }
  if abstract != none {
    article-abstract(
      abstract,
      keywords: keywords,
      jel: jel,
      language: language,
    )
  }
  if toc {
    outline()
  }
  body
}
