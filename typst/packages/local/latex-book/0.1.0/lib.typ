#import "@preview/in-dexter:0.7.2": index, index-main, make-index
#import "@local/template-utils:0.1.0": *

// Numbering
#let book-phase = state("latex-book-phase", "title")
#let page-style-enabled = state("latex-book-page-style", true)
#let folio-enabled = state("latex-book-folio", true)
#let main-page-reset = state("latex-book-main-page-reset", false)
#let main-start-page = state("latex-book-main-start-page", none)
#let appendix-mode = state("latex-book-appendix", false)
#let numbering-scale = 1000
#let appendix-offset = numbering-scale * numbering-scale * numbering-scale

#let book-numbering(n, parentheses: false) = {
  let appendix = n >= appendix-offset
  let encoded = if appendix { n - appendix-offset } else { n }
  let chapter = calc.floor(encoded / numbering-scale / numbering-scale)
  let section = calc.floor(
    calc.rem(encoded, numbering-scale * numbering-scale) / numbering-scale,
  )
  let number = calc.rem(encoded, numbering-scale)
  let pattern = if appendix {
    if parentheses { "(1.A.1)" } else { "1.A.1" }
  } else if parentheses {
    "(1.1.1)"
  } else {
    "1.1.1"
  }
  numbering(pattern, chapter, section, number)
}

#let reset-book-numbering() = context {
  let headings = counter(heading).get()
  let chapter = headings.at(0, default: 0)
  let section = headings.at(1, default: 0)
  let base = (
    chapter * numbering-scale * numbering-scale + section * numbering-scale
  )
  if appendix-mode.get() { base += appendix-offset }
  reset-numbering(base: base)
}

// Running heads and folios
#let latest-heading(level) = {
  let headings = query(heading.where(level: level).before(here()))
  if headings.len() > 0 { headings.last() } else { none }
}

#let running-heading(level, chapter: false, page-last: false) = {
  let it = if page-last {
    let page = here().page()
    let headings = query(heading.where(level: level)).filter(
      it => it.location().page() <= page,
    )
    if headings.len() > 0 { headings.last() } else { none }
  } else {
    latest-heading(level)
  }
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
  #v(-0.75em)
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
      ruled-header(align(center, text(size: 9pt, smallcaps(heading.body))))
    }
  } else if phase == "main" and not chapter-on-page {
    set text(size: 10pt)
    if calc.even(page) {
      ruled-header(grid(
        columns: (auto, 1fr, auto),
        page-number(), [], smallcaps(running-heading(1, chapter: true)),
      ))
    } else {
      ruled-header(grid(
        columns: (auto, 1fr, auto),
        smallcaps(running-heading(2, page-last: true)), [], page-number(),
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
  if not folio-enabled.get() {
    none
  } else if phase == "front" and (page-style-enabled.get() or chapter-on-page) {
    align(center, text(size: 9pt, page-number()))
  } else if phase == "main" and chapter-on-page {
    align(center, text(size: 9pt, page-number()))
  }
}

// Bibliography and contents
#let chapter-bibliographies(
  sources,
  title: auto,
  style: mybibstyle,
) = context {
  let bibliography-location = here()
  let chapters = query(heading.where(level: 1).before(bibliography-location))
  let bibliography-title = if title == auto {
    if text.lang == "es" { [Bibliografía] } else { [Bibliography] }
  } else {
    title
  }
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
      heading(level: 2, numbering: none, outlined: true, chapter-title)
      show bibliography: set text(size: 9pt)
      bibliography(
        sources,
        title: none,
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
  show-outline-entry(
    it,
    numbering(if phase == "front" { "i" } else { "1" }, page),
  )
}

#let book-reference-supplement(target) = {
  if (
    target.func() == heading and target.level == 1 and target.numbering != none
  ) {
    localized([Capítulo], [Chapter])
  } else if (
    target.func() == heading
      and target.level == 2
      and appendix-mode.at(target.location())
  ) {
    localized([Apéndice], [Appendix])
  } else {
    auto
  }
}

// Front matter
#let half-title-page(title) = [
  #align(center, text(size: 20.74pt, weight: "bold", title))
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
  #set par(first-line-indent: 0pt, spacing: 1.2em)
  #v(1fr)
  #copyright
  #pagebreak()
]

#let dedication-page(dedication) = [
  #pagebreak(weak: true, to: "odd")
  #align(center + horizon, text(size: 12pt, style: "italic", dedication))
  #pagebreak(to: "odd")
]

// Equations
#let equation = equation-environment(
  n => book-numbering(n, parentheses: true),
)

// Subfigures
#let book-subfigures = subfigure-environments(
  n => book-numbering(n),
  sub-ref-numbering: "(a)",
)
#let subfigure = book-subfigures.subfigure
#let subfigure-grid = book-subfigures.subfigure-grid

// Theorem environments
#let book-environments = statement-environments(n => book-numbering(n))
#let theorem = book-environments.theorem
#let proposition = book-environments.proposition
#let lemma = book-environments.lemma
#let corollary = book-environments.corollary
#let definition = book-environments.definition
#let example = book-environments.example
#let continued-example = book-environments.continued-example
#let exercise = book-environments.exercise
#let remark = book-environments.remark
#let notation = book-environments.notation
#let solution = book-environments.solution

// Sections and appendices
#let appendix(title: auto, body) = {
  appendix-mode.update(true)
  context {
    let chapter = counter(heading).get().first()
    counter(heading).update((chapter, 0))
  }
  set heading(numbering: (..numbers) => numbering("1.A.1", ..numbers))
  body
  appendix-mode.update(false)
}

// Document template
#let latex-book(
  title: [],
  subtitle: none,
  author: "Pedro Ferrari",
  date: datetime.today(),
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
  index: false,
  index-title: auto,
  body,
) = {
  let contents-title = if language == "es" { [Índice General] } else {
    [Contents]
  }
  let resolved-preface-title = if preface-title == auto {
    if language == "es" { [Prefacio] } else { [Preface] }
  } else {
    preface-title
  }
  let resolved-index-title = if index-title == auto {
    if language == "es" { [Índice Alfabético] } else { [Index] }
  } else {
    index-title
  }
  // Document metadata and page
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

  // Typography
  set text(
    font: "New Computer Modern",
    size: 10pt,
    lang: language,
    hyphenate: auto,
  )
  set smartquote(quotes: curly-double-quotes)
  show math.equation: set text(font: "New Computer Modern Math")
  show: code-style.with(size: 9pt)
  show link: set text(fill: navy)
  show ref: number-only-reference(
    supplement: book-reference-supplement,
  )
  show cite: set text(fill: navy)
  set bibliography(style: mybibstyle)
  show bibliography: set block(spacing: bibliography-entry-spacing)
  set par(
    leading: 0.53em,
    spacing: 0.55em,
    first-line-indent: 15pt,
    justify: true,
  )
  set block(spacing: 1.2em)

  // Numbering and components
  set heading(numbering: "1.1.1")
  show heading.where(numbering: none): set heading(outlined: false)
  set math.equation(
    numbering: none,
    number-align: left + horizon,
    supplement: none,
  )
  set figure(numbering: n => book-numbering(n), gap: 5pt)
  show figure.where(kind: image): set figure(placement: top)
  show figure.where(kind: table): set figure(placement: top)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "theorem"): show-statement
  show figure.caption: show-figure-caption
  show heading.where(level: 1): it => {
    page-style-enabled.update(false)
    if it.numbering != none {
      pagebreak(to: "odd")
    } else {
      pagebreak(weak: true, to: "odd")
    }
    page-style-enabled.update(true)
    context if main-page-reset.get() {
      counter(page).update(1)
      main-start-page.update(here().page())
      main-page-reset.update(false)
    }
    reset-book-numbering()
    if it.numbering != none { counter(footnote).update(0) }
    block(width: 100%, above: 2em, below: 3.2em, breakable: false)[
      #set text(weight: "bold")
      #align(center)[
        #v(
          if it.numbering != none {
            3.7em
          } else if it.body == resolved-preface-title {
            4em
          } else {
            1em
          },
        )
        #line(length: 100%, stroke: 1.5pt)
        #v(1.2em)
        #if it.numbering != none {
          text(size: 20.74pt)[
            #localized([Capítulo], [Chapter]) #context counter(
              heading,
            ).display(
              it.numbering,
            )
          ]
          v(0.7em)
        }
        #text(size: 24.88pt, it.body)
        #v(1.2em)
        #line(length: 100%, stroke: 1.5pt)
      ]
    ]
  }
  show heading.where(level: 2): it => {
    reset-book-numbering()
    block(above: 1.5em, below: 1.05em)[
      #set text(size: 14.4pt, weight: "bold")
      #heading-title(it)
    ]
  }
  show heading.where(level: 3): it => [
    #block(above: 1.4em, below: 0.9em)[
      #set text(
        size: 12pt,
        weight: if it.numbering == none { "regular" } else { "bold" },
        style: if it.numbering == none { "italic" } else { "normal" },
      )
      #heading-title(it)
    ]
  ]
  set footnote.entry(
    separator: footnote-separator,
    clearance: footnote-rule-spacing,
    indent: 0pt,
  )
  show footnote.entry: it => show-footnote-entry(it, size: 8pt)
  show outline.entry: book-outline-entry

  // Front matter
  if half-title { half-title-page(title) }
  title-page(
    title,
    subtitle,
    author,
    localized-date(date, language),
    institution,
    department,
    logo,
  )
  if optional-value-present(copyright) { copyright-page(copyright) }
  if dedication != none { dedication-page(dedication) }

  book-phase.update("front")
  if toc {
    folio-enabled.update(false)
    document-outline(contents-title)
    pagebreak()
    folio-enabled.update(true)
  }
  if optional-value-present(preface) {
    heading(
      level: 1,
      numbering: none,
      outlined: true,
      resolved-preface-title,
    )
    block[
      #set par(spacing: 1.2em)
      #preface
    ]
  }

  // Main matter
  pagebreak()
  book-phase.update("main")
  set page(numbering: "1")
  main-page-reset.update(true)
  counter(heading).update(0)
  body
  if index {
    heading(
      level: 1,
      numbering: none,
      outlined: true,
      resolved-index-title,
    )
    columns(2, gutter: 1.5em)[
      #make-index(title: none, use-page-counter: true)
    ]
  }
}
