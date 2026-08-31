#import "@preview/retrofit:0.2.0": backrefs
#import "@local/template-utils:0.1.0": *

// Font sizes: derive body roles from the base; keep title and headings fixed
#let _default-font-size = 11pt
#let _small-size(font-size) = font-size - 1pt
#let _footnote-size(font-size) = font-size - 2pt

// Numbering
#let _appendix-mode = state("latex-article-appendix", false)
// Store the section in each counter so cross-references keep their target number
#let _numbering-scale = 1000
#let _appendix-offset = _numbering-scale * _numbering-scale

#let _article-numbering(n, parentheses: false) = {
  let appendix = n >= _appendix-offset
  let encoded = if appendix { n - _appendix-offset } else { n }
  let section = calc.floor(encoded / _numbering-scale)
  let number = calc.rem(encoded, _numbering-scale)
  let pattern = if appendix {
    if parentheses { "(A.1)" } else { "A.1" }
  } else if parentheses {
    "(1.1)"
  } else {
    "1.1"
  }
  numbering(pattern, section, number)
}

#let _reset-article-numbering() = context {
  let headings = counter(heading).get()
  let base = if _appendix-mode.get() {
    _appendix-offset + headings.at(1, default: 0) * _numbering-scale
  } else {
    headings.first() * _numbering-scale
  }
  reset-numbering(base: base)
}

#let equation = equation-environment(
  n => _article-numbering(n, parentheses: true),
)

// Page furniture and front matter
#let _article-header(short-title, author, font-size) = context {
  let page-number = counter(page).get().first()
  let running-title = if calc.even(page-number) { author } else { short-title }
  if page-number > 1 and running-title != none and running-title != [] {
    if calc.even(page-number) {
      grid(
        columns: (1fr, auto, 1fr),
        align: (left, center, right),
        text(size: _small-size(font-size), numbering("1", page-number)),
        text(size: _small-size(font-size), upper(running-title)),
        [],
      )
    } else {
      grid(
        columns: (1fr, auto, 1fr),
        align: (left, center, right),
        [],
        text(size: _small-size(font-size), upper(running-title)),
        text(size: _small-size(font-size), numbering("1", page-number)),
      )
    }
  }
}

#let _article-footer(font-size) = context {
  if counter(page).get().first() == 1 {
    align(
      center,
      text(size: _small-size(font-size), counter(page).display("1")),
    )
  }
}

#let _article-title(title, author, author-note, date) = block(
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

#let _article-abstract(
  abstract,
  font-size,
  keywords: none,
  jel: none,
) = block(
  width: 100%,
  above: 0pt,
  below: 2.5em,
  inset: (x: 2.5em),
)[
  #set text(size: _small-size(font-size))
  #set par(first-line-indent: 0pt)
  #align(center)[*#localized([Resumen], [Abstract])*]
  #v(0.5em)
  #abstract
  #if optional-value-present(keywords) {
    parbreak()
    v(0.45em)
    strong(localized([Palabras Clave: ], [Keywords: ]))
    emph(keywords)
  }
  #if optional-value-present(jel) {
    parbreak()
    strong(localized([Clasificación JEL: ], [JEL Classification: ]))
    emph(jel)
  }
]

#let _article-outline-entry(it) = context {
  let location = it.element.location()
  show-outline-entry(
    it,
    numbering("1", counter(page).at(location).first()),
    top-level-spacing: 1em,
  )
}

// Subfigures
#let _article-subfigures = subfigure-environments(n => _article-numbering(n))
#let subfigure = _article-subfigures.subfigure
#let subfigure-grid = _article-subfigures.subfigure-grid

// Theorem environments
#let _article-environments = statement-environments(n => _article-numbering(n))
#let theorem = _article-environments.theorem
#let proposition = _article-environments.proposition
#let lemma = _article-environments.lemma
#let corollary = _article-environments.corollary
#let definition = _article-environments.definition
#let example = _article-environments.example
#let continued-example = _article-environments.continued-example
#let exercise = _article-environments.exercise
#let remark = _article-environments.remark
#let notation = _article-environments.notation
#let solution = _article-environments.solution

#let _article-reference-supplement(target) = {
  if (
    target.func() == heading
      and target.level == 2
      and _appendix-mode.at(target.location())
  ) {
    localized([Apéndice], [Appendix])
  } else {
    auto
  }
}

// Sections and appendices
#let appendix(title: auto, body) = context {
  let section = counter(heading).get().first()
  let appendix-title = if title == auto {
    if text.lang == "es" { [Apéndice] } else { [Appendix] }
  } else {
    title
  }
  _appendix-mode.update(true)
  heading(level: 1, numbering: none, outlined: true, appendix-title)
  counter(heading).update((0, 0))
  set heading(
    numbering: (..numbers) => {
      let levels = numbers.pos()
      assert(
        levels.len() >= 2,
        message: "Article appendix sections must use level-two headings (`==`).",
      )
      numbering("A.1", ..levels.slice(1))
    },
  )
  body
  counter(heading).update((section, 0))
  _appendix-mode.update(false)
}

// Document template
#let latex-article(
  language: "es",
  font-size: _default-font-size,
  title: [],
  author: "Pedro Ferrari",
  author-note: none,
  date: datetime.today(),
  metadata-date: auto,
  short-title: none,
  abstract: none,
  keywords: none,
  jel: none,
  toc: false,
  // Overridden at the document call site for filename-based bibliographies
  bibliography-read: read-mybibstyle,
  body,
) = {
  // Document metadata and page
  set document(
    title: title,
    author: author,
    description: abstract,
    keywords: if optional-value-present(keywords) { keywords } else { () },
    date: metadata-date,
  )
  set page(
    paper: "a4",
    binding: left,
    numbering: "1",
    margin: (top: 3.7cm, bottom: 4.7cm, inside: 3.5cm, outside: 3.5cm),
    header: _article-header(short-title, author, font-size),
    header-ascent: 25%,
    footer: _article-footer(font-size),
    footer-descent: 30%,
  )

  // Typography
  set text(
    font: "New Computer Modern",
    size: font-size,
    lang: language,
    hyphenate: auto,
  )
  set smartquote(quotes: curly-double-quotes)
  show math.equation: set text(font: "New Computer Modern Math")
  show math.equation: set block(breakable: true)
  show: code-style.with(size: _footnote-size(font-size))
  show link: set text(fill: navy)
  show ref: number-only-reference(
    supplement: _article-reference-supplement,
  )
  show cite: set text(fill: navy)
  show bibliography: set text(size: _footnote-size(font-size))
  show bibliography: set block(spacing: bibliography-entry-spacing)
  set par(
    leading: 0.53em,
    spacing: 0.55em,
    first-line-indent: 15pt,
    justify: true,
  )
  set block(spacing: 1.2em)

  // Numbering and components
  set heading(numbering: "1.1")
  show heading.where(numbering: none): set heading(outlined: false)
  set math.equation(
    numbering: none,
    number-align: left + horizon,
    supplement: none,
  )
  set figure(
    numbering: n => _article-numbering(n),
    gap: 5pt,
  )
  show figure.caption: show-figure-caption.with(_small-size(font-size))
  show figure.where(kind: image): set figure(placement: top)
  show figure.where(kind: table): set figure(placement: top)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "theorem"): show-statement
  show heading.where(level: 1): it => {
    if it.numbering != none { _reset-article-numbering() }
    if it.numbering != none or _appendix-mode.at(it.location()) {
      block(above: 1.5em, below: 1em)[
        #set text(size: 14.4pt, weight: "bold")
        #heading-title(it)
      ]
    } else {
      v(1.5em)
      text(size: 14.4pt, weight: "bold", it)
      v(1em)
    }
  }
  show heading.where(level: 2): it => {
    context if _appendix-mode.get() { _reset-article-numbering() }
    block(above: 1.4em, below: 0.9em)[
      #set text(size: 12pt, weight: "bold")
      #heading-title(it)
    ]
  }
  show heading.where(level: 3): it => block(above: 1.4em, below: 1em)[
    #set text(size: 11pt, weight: "bold")
    #heading-title(it)
  ]
  set footnote.entry(
    separator: footnote-separator,
    clearance: footnote-rule-spacing,
    indent: 0pt,
  )
  show footnote.entry: it => show-footnote-entry(
    it,
    size: _footnote-size(font-size),
  )
  show outline.entry: _article-outline-entry
  show: apply-mybibstyle
  // The backrefs plugin costs about a second per compile, so Neovim's forward
  // search skips it by passing `--input sync=1`
  show: if "sync" in sys.inputs { doc => doc } else {
    backrefs.with(
      format: format-bibliography-backrefs,
      read: retrofit-reader(bibliography-read),
    )
  }

  // Front matter and content
  _article-title(title, author, author-note, localized-date(date, language))
  if author-note != none { counter(footnote).update(0) }
  if abstract != none {
    _article-abstract(
      abstract,
      font-size,
      keywords: keywords,
      jel: jel,
    )
  }
  if toc {
    let contents-title = if language == "es" { [Índice] } else { [Contents] }
    document-outline(contents-title, depth: 2)
  }
  body
}
