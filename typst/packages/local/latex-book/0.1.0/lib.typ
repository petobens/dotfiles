#import "@local/latex-article:0.1.0": article-table, navy

// Numbering and localization
#let book-table = article-table

#let book-phase = state("latex-book-phase", "title")
#let page-style-enabled = state("latex-book-page-style", true)
#let main-page-reset = state("latex-book-main-page-reset", false)
#let main-start-page = state("latex-book-main-start-page", none)
#let appendix-mode = state("latex-book-appendix", false)

#let localized(spanish, english) = context {
  if text.lang == "es" { spanish } else { english }
}

#let localized-title(title, spanish, english) = {
  if title == auto { localized(spanish, english) } else { title }
}

#let book-numbering(n, parentheses: false) = context {
  let numbers = counter(heading).get()
  let chapter = numbers.at(0, default: 0)
  let section = numbers.at(1, default: 0)
  let pattern = if appendix-mode.get() {
    if parentheses { "(A.1.1)" } else { "A.1.1" }
  } else if parentheses {
    "(1.1.1)"
  } else {
    "1.1.1"
  }
  numbering(pattern, chapter, section, n)
}

#let reset-numbering() = {
  counter(math.equation).update(0)
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(figure.where(kind: "theorem")).update(0)
}

// Running heads and folios
#let latest-heading(level) = {
  let headings = query(heading.where(level: level).before(here()))
  if headings.len() > 0 { headings.last() } else { none }
}

#let running-heading(level, chapter: false) = {
  let it = latest-heading(level)
  if it != none {
    if it.numbering != none {
      if chapter { localized([Capítulo], [Chapter]) + [ ] }
      numbering(it.numbering, ..counter(heading).at(it.location()))
      [. ]
    }
    it.body
  }
}

#let page-number() = context {
  let n = counter(page).get().first()
  numbering(if book-phase.get() == "front" { "i" } else { "1" }, n)
}

#let ruled-header(body) = block(width: 100%)[
  #body
  #v(0.5pt)
  #line(length: 100%, stroke: 0.4pt)
]

#let book-header = context {
  let phase = book-phase.get()
  let page = counter(page).get().first()
  let physical-page = here().page()
  let chapter-on-page = query(heading.where(level: 1)).any(
    it => it.location().page() == physical-page,
  )
  if not page-style-enabled.get() {
    none
  } else if phase == "front" {
    let heading = latest-heading(1)
    if heading != none {
      ruled-header(align(center, text(size: 8pt, smallcaps(heading.body))))
    }
  } else if phase == "main" and not chapter-on-page {
    set text(size: 9pt)
    if calc.even(page) {
      ruled-header(grid(
        columns: (auto, 1fr, auto),
        page-number(), [], smallcaps(running-heading(1, chapter: true)),
      ))
    } else {
      ruled-header(grid(
        columns: (auto, 1fr, auto),
        smallcaps(running-heading(2)), [], page-number(),
      ))
    }
  }
}

#let book-footer = context {
  let phase = book-phase.get()
  let physical-page = here().page()
  let chapter-on-page = query(heading.where(level: 1)).any(
    it => it.location().page() == physical-page,
  )
  if phase == "front" and (page-style-enabled.get() or chapter-on-page) {
    align(center, text(size: 9pt, page-number()))
  } else if phase == "main" and chapter-on-page {
    align(center, text(size: 9pt, page-number()))
  }
}

// Bibliography and contents
#let chapter-bibliographies(
  sources,
  title: auto,
  style: "harvard-cite-them-right",
) = context {
  let bibliography-location = here()
  let chapters = query(heading.where(level: 1).before(bibliography-location))
  let bibliography-title = localized-title(
    title,
    [Bibliografía],
    [Bibliography],
  )
  heading(level: 1, numbering: none, outlined: true, bibliography-title)
  for (index, chapter) in chapters.enumerate() {
    if chapter.numbering != none and not appendix-mode.at(chapter.location()) {
      let chapter-end = if index + 1 < chapters.len() {
        chapters.at(index + 1).location()
      } else {
        bibliography-location
      }
      let target = selector(cite).after(chapter.location()).before(chapter-end)
      let chapter-number = numbering(
        chapter.numbering,
        ..counter(heading).at(chapter.location()),
      )
      let chapter-title = if text.lang == "es" {
        [Referencias del Capítulo #chapter-number]
      } else {
        [References for Chapter #chapter-number]
      }
      show bibliography: set heading(offset: 1, outlined: true)
      show bibliography: set text(size: 8pt)
      bibliography(
        sources,
        title: chapter-title,
        target: target,
        style: style,
        group: none,
      )
    }
  }
}

#let book-outline-entry(it) = context {
  let location = it.element.location()
  let phase = book-phase.at(location)
  let page = if phase == "main" {
    location.page() - main-start-page.final() + 1
  } else {
    counter(page).at(location).first()
  }
  block(width: 100%)[
    #set text(weight: if it.level == 1 { "bold" } else { "regular" })
    #h(1.5em * (it.level - 1))
    #if it.element.numbering != none {
      numbering(
        it.element.numbering,
        ..counter(heading).at(location),
      )
      h(0.3em)
    }
    #text(fill: black, it.element.body)
    #box(width: 1fr, inset: (x: 0.2em), repeat(gap: 0.45em)[.])
    #text(fill: navy)[
      #link(location)[
        #numbering(
          if phase == "front" { "i" } else { "1" },
          page,
        )
      ]
    ]
  ]
}

// Front matter
#let half-title-page(title) = [
  #align(center + horizon, text(size: 20.74pt, weight: "bold", title))
  #pagebreak(to: "odd")
]

#let title-page(
  title,
  subtitle,
  author,
  date,
  institution,
  department,
  logo,
) = [
  #set par(first-line-indent: 0pt, justify: false)
  #align(center)[
    #if logo != none {
      image(logo, height: 1.8cm)
      v(0.7em)
    }
    #if institution != none {
      text(size: 17.28pt, weight: "bold", institution)
      v(0.4em)
    }
    #if department != none {
      text(size: 14.4pt, weight: "bold", department)
    }
    #v(1fr)
    #line(length: 100%, stroke: 1.5pt)
    #v(1em)
    #text(size: 24.88pt, weight: "bold", title)
    #if subtitle != none and subtitle != [] {
      v(0.7em)
      text(size: 17.28pt)[— #subtitle —]
    }
    #v(1em)
    #line(length: 100%, stroke: 1.5pt)
    #v(1fr)
    #text(size: 20.74pt, smallcaps(author))
    #v(1fr)
    #text(size: 14.4pt, weight: "bold", date)
  ]
  #pagebreak()
]

#let copyright-page(copyright) = [
  #set text(size: 8pt)
  #set par(first-line-indent: 0pt)
  #v(1fr)
  #copyright
  #pagebreak()
]

#let dedication-page(dedication) = [
  #pagebreak(weak: true, to: "odd")
  #align(center + horizon, text(size: 12pt, style: "italic", dedication))
  #pagebreak(to: "odd")
]

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
  numbering: if numbered { n => book-numbering(n) } else { none },
  caption: if note == none { [] } else { note },
  outlined: false,
  gap: 0.35em,
)

#let show-statement(it) = align(left, block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #strong[
    #it.supplement
    #if it.numbering != none { [ #context it.counter.display(it.numbering)] }
    #if it.caption != none and it.caption.body != [] { [ (#it.caption.body)] }.
  ] #it.body
])

#let theorem(body, note: none, title: auto, numbered: true) = statement(
  localized-title(title, [Teorema], [Theorem]),
  body,
  note: note,
  italic: true,
  numbered: numbered,
)
#let proposition(body, note: none, title: auto, numbered: true) = statement(
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
#let corollary(body, note: none, title: auto, numbered: true) = statement(
  localized-title(title, [Corolario], [Corollary]),
  body,
  note: note,
  italic: true,
  numbered: numbered,
)
#let definition(body, note: none, title: auto, numbered: true) = statement(
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
  appendix-mode.update(true)
  counter(heading).update(0)
  set heading(numbering: (..numbers) => numbering("A.1.1", ..numbers))
  body
}

// Document template
#let latex-book(
  title: [],
  subtitle: none,
  author: "Pedro Ferrari",
  date: datetime.today().display(),
  metadata-date: auto,
  language: "es",
  institution: none,
  department: none,
  logo: none,
  half-title: true,
  copyright: none,
  dedication: none,
  toc: true,
  preface: none,
  preface-title: auto,
  body,
) = {
  set document(title: title, author: author, date: metadata-date)
  set page(
    paper: "a4",
    binding: left,
    numbering: "i",
    margin: (top: 3.7cm, bottom: 4.7cm, inside: 3.5cm, outside: 3.5cm),
    header: book-header,
    header-ascent: 25%,
    footer: book-footer,
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
  set par(
    leading: 0.55em,
    spacing: 0.55em,
    first-line-indent: 15pt,
    justify: true,
  )
  set block(spacing: 1.2em)
  set heading(numbering: "1.1.1")
  set math.equation(
    numbering: n => book-numbering(n, parentheses: true),
    number-align: left + horizon,
    supplement: none,
  )
  set figure(numbering: n => book-numbering(n), gap: 5pt)
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
    page-style-enabled.update(false)
    pagebreak(weak: true, to: "odd")
    page-style-enabled.update(true)
    context if main-page-reset.get() {
      counter(page).update(1)
      main-start-page.update(here().page())
      main-page-reset.update(false)
    }
    reset-numbering()
    block(width: 100%, above: 2em, below: 3em)[
      #set text(weight: "bold")
      #align(center)[
        #line(length: 100%, stroke: 1.5pt)
        #v(1.2em)
        #if it.numbering != none {
          text(size: 17.28pt)[
            #localized([Capítulo], [Chapter]) #context counter(heading).display(
              it.numbering,
            )
          ]
          v(0.7em)
        }
        #text(size: 20.74pt, it.body)
        #v(1.2em)
        #line(length: 100%, stroke: 1.5pt)
      ]
    ]
  }
  show heading.where(level: 2): it => {
    reset-numbering()
    block(above: 1.5em, below: 0.8em)[
      #set text(size: 14.4pt, weight: "bold")
      #heading-title(it)
    ]
  }
  show heading.where(level: 3): it => block(above: 1.4em, below: 0.65em)[
    #set text(size: 12pt, weight: "bold")
    #heading-title(it)
  ]
  set footnote.entry(indent: 15pt)
  show footnote.entry: set text(size: 8pt)
  set outline(indent: 1.5em)
  show outline.entry: book-outline-entry

  if half-title { half-title-page(title) }
  title-page(title, subtitle, author, date, institution, department, logo)
  if copyright != none { copyright-page(copyright) }
  if dedication != none { dedication-page(dedication) }

  book-phase.update("front")
  counter(page).update(1)
  if toc {
    outline(title: localized([Índice General], [Contents]))
  }
  if preface != none {
    heading(
      level: 1,
      numbering: none,
      localized-title(preface-title, [Prefacio], [Preface]),
    )
    preface
  }

  pagebreak()
  book-phase.update("main")
  set page(numbering: "1")
  main-page-reset.update(true)
  counter(heading).update(0)
  body
}
