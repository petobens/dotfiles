#import "@preview/retrofit:0.2.0": backrefs
#import "@local/template-utils:0.1.0": *

// Numbering
#let appendix-mode = state("latex-article-appendix", false)
// Store the section in each counter so cross-references keep their target number
#let numbering-scale = 1000
#let appendix-offset = numbering-scale * numbering-scale

#let article-numbering(n, parentheses: false) = {
  let appendix = n >= appendix-offset
  let encoded = if appendix { n - appendix-offset } else { n }
  let section = calc.floor(encoded / numbering-scale)
  let number = calc.rem(encoded, numbering-scale)
  let pattern = if appendix {
    if parentheses { "(A.1)" } else { "A.1" }
  } else if parentheses {
    "(1.1)"
  } else {
    "1.1"
  }
  numbering(pattern, section, number)
}

#let reset-article-numbering() = context {
  let headings = counter(heading).get()
  let base = if appendix-mode.get() {
    appendix-offset + headings.at(1, default: 0) * numbering-scale
  } else {
    headings.first() * numbering-scale
  }
  reset-numbering(base: base)
}

#let article-equations = equation-environments(
  n => article-numbering(n, parentheses: true),
)
#let equation = article-equations.numbered
#let uequation = article-equations.unnumbered

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
  inset: (top: 4.2em),
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
) = block(
  width: 100%,
  above: 0pt,
  below: 2.5em,
  inset: (x: 2.5em),
)[
  #set text(size: 10pt)
  #set par(first-line-indent: 0pt)
  #align(center)[*#localized([Resumen], [Abstract])*]
  #v(0.5em)
  #abstract
  #if keywords != none {
    parbreak()
    v(0.45em)
    strong(localized([Palabras Clave: ], [Keywords: ]))
    emph(keywords)
  }
  #if jel != none {
    parbreak()
    strong(localized([Clasificación JEL: ], [JEL Classification: ]))
    emph(jel)
  }
]

// Tables and subfigures
#let article-table = latex-table
#let article-subfigures = subfigure-environments(n => article-numbering(n))
#let subfigure = article-subfigures.subfigure
#let subfigures = article-subfigures.subfigures
#let subfigure-grid = article-subfigures.subfigure-grid

// Theorem environments
#let article-environments = statement-environments(n => article-numbering(n))
#let statement = article-environments.statement
#let theorem = article-environments.theorem
#let proposition = article-environments.proposition
#let lemma = article-environments.lemma
#let corollary = article-environments.corollary
#let definition = article-environments.definition
#let example = article-environments.example
#let exercise = article-environments.exercise
#let remark = article-environments.remark
#let notation = article-environments.notation
#let solution = article-environments.solution

// Sections and appendices
#let appendix(title: auto, body) = {
  appendix-mode.update(true)
  heading(level: 1, numbering: none, localized-title(
    title,
    [Apéndice],
    [Appendix],
  ))
  counter(heading).update((0, 0))
  set heading(
    numbering: (..numbers) => numbering("A", numbers.pos().last()),
    supplement: localized([Apéndice], [Appendix]),
  )
  body
}

// Document template
#let latex-article(
  title: [],
  author: "Pedro Ferrari",
  author-note: none,
  date: datetime.today(),
  metadata-date: auto,
  short-title: none,
  language: "es",
  abstract: none,
  keywords: none,
  jel: none,
  toc: false,
  body,
) = {
  // Document metadata and page
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

  // Typography
  set text(
    font: "New Computer Modern",
    size: 11pt,
    lang: language,
    hyphenate: auto,
  )
  set smartquote(quotes: curly-double-quotes)
  show math.equation: set text(font: "New Computer Modern Math")
  show raw: set text(font: "DejaVu Sans Mono", size: 9pt)
  show link: set text(fill: navy)
  show ref: show-number-only-reference
  show cite: set text(fill: navy)
  show bibliography: set text(size: 9pt)
  show bibliography: set block(spacing: bibliography-entry-spacing)
  set par(
    leading: 0.55em,
    spacing: 0.55em,
    first-line-indent: 15pt,
    justify: true,
  )
  set block(spacing: 1.2em)

  // Numbering and components
  set heading(numbering: "1.1")
  set math.equation(
    numbering: none,
    number-align: left + horizon,
    supplement: none,
  )
  set figure(
    numbering: n => article-numbering(n),
    gap: 5pt,
  )
  show figure.where(kind: image): set figure(placement: top)
  show figure.where(kind: table): set figure(placement: top)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "theorem"): show-statement
  show figure.caption: show-figure-caption
  show heading.where(level: 1): it => {
    if it.numbering == none {
      v(1.5em)
      text(size: 14.4pt, weight: "bold", it)
      v(1em)
    } else {
      reset-article-numbering()
      block(above: 1.5em, below: 1em)[
        #set text(size: 14.4pt, weight: "bold")
        #heading-title(it)
      ]
    }
  }
  show heading.where(level: 2): it => {
    context if appendix-mode.get() { reset-article-numbering() }
    block(above: 1.4em, below: 0.9em)[
      #set text(size: 12pt, weight: "bold")
      #heading-title(it)
    ]
  }
  show heading.where(level: 3): it => block(above: 1.4em, below: 0.65em)[
    #set text(size: 10pt, weight: "bold")
    #heading-title(it)
  ]
  set footnote.entry(
    separator: footnote-separator,
    indent: 0pt,
  )
  show footnote.entry: show-footnote-entry
  set outline(indent: 1.5em)
  show: apply-mybibstyle
  show: backrefs.with(
    format: format-bibliography-backrefs,
    read: read-mybibstyle,
  )

  // Front matter and content
  article-title(title, author, author-note, localized-date(date, language))
  if author-note != none { counter(footnote).update(0) }
  if abstract != none {
    article-abstract(
      abstract,
      keywords: keywords,
      jel: jel,
    )
  }
  if toc {
    outline()
  }
  body
}
