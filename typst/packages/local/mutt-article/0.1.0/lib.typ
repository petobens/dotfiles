#import "@local/template-utils:0.1.0": *

// Typography and palette
#let _default-font-size = 11pt
#let _small-size(font-size) = font-size - 1pt
#let _footnote-size(font-size) = font-size - 2pt

#let mutt-blue = rgb("#0045FB")
#let mutt-navy = rgb("#0805AC")
#let mutt-ink = rgb("#202124")
#let mutt-muted = rgb("#666666")
#let mutt-pale-blue = rgb("#F1F5FF")

#let _default-logo = image("muttdata-logo.png", height: 70pt)

// Numbering
#let _appendix-mode = state("mutt-article-appendix", false)
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
#let _article-header(logo) = if logo != none {
  grid(
    columns: (1fr, auto),
    [], move(dx: 60pt, logo),
  )
}

#let _article-footer(footer, font-size) = context {
  grid(
    columns: (1fr, auto),
    align: (left, right),
    text(
      font: "DM Sans 9pt",
      size: font-size,
      fill: mutt-muted,
      if optional-value-present(footer) { footer },
    ),
    text(
      font: "DM Sans 9pt",
      size: _small-size(font-size),
      fill: mutt-muted,
      counter(page).display("1"),
    ),
  )
}

#let _article-title(
  title,
  subtitle,
  date,
  authors,
  audience,
  revised-date,
) = {
  let metadata = (
    [Date: #date],
    if optional-value-present(authors) { [Authors: #authors] },
    if optional-value-present(audience) { [Audience: #audience] },
    [Revised date: #revised-date],
  ).filter(it => it != none)

  block(width: 100%, breakable: false, below: 24pt)[
    #set text(hyphenate: false)
    #set par(justify: false, first-line-indent: 0pt)
    #v(10pt)
    #block(width: 100%, above: 0pt, below: 0pt)[
      #text(size: 26pt, weight: "bold", fill: mutt-blue, title)
    ]
    #if optional-value-present(subtitle) {
      v(11pt)
      block(width: 100%, above: 0pt, below: 0pt)[
        #set par(leading: 0.3em)
        #text(size: 17pt, fill: mutt-blue, subtitle)
      ]
    }
    #v(14pt)
    #block[
      #set text(font: "DM Mono", size: 11pt)
      #set par(leading: 0.1em, spacing: 0.65em)
      #metadata.join(parbreak())
    ]
  ]
}

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

#let _heading-title(it) = context {
  if it.numbering != none {
    numbering(it.numbering, ..counter(heading).at(it.location()))
    h(0.4em)
  }
  it.body
}

// Components and appendices
#let callout(body, title: none) = block(
  width: 100%,
  breakable: true,
  fill: mutt-pale-blue,
  stroke: (left: 3pt + mutt-blue),
  inset: (x: 12pt, y: 10pt),
  above: 10pt,
  below: 10pt,
)[
  #if optional-value-present(title) {
    text(weight: "bold", fill: mutt-navy, title)
    v(4pt)
  }
  #body
]

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
        message: "Mutt appendix sections must use level-two headings (`==`).",
      )
      numbering("A.1", ..levels.slice(1))
    },
  )
  body
  counter(heading).update((section, 0))
  _appendix-mode.update(false)
}

// Document template
#let mutt-article(
  language: "en",
  font-size: _default-font-size,
  title: [],
  subtitle: none,
  date: datetime.today(),
  metadata-date: auto,
  authors: "Pedro Ferrari",
  audience: [Muttdata],
  revised-date: datetime.today(),
  logo: _default-logo,
  footer: [www.muttdata.ai],
  toc: false,
  body,
) = {
  let document-authors = if optional-value-present(authors) { authors } else {
    ()
  }

  if "markdown" in sys.inputs {
    return pandoc-article(
      body,
      language: language,
      title: title,
      author: document-authors,
      date: date,
      object-numbering: n => _article-numbering(n),
      appendix-state: _appendix-mode,
      reset-object-numbering: _reset-article-numbering,
    )
  }

  let displayed-date = localized-date(date, language)
  let displayed-revised-date = localized-date(revised-date, language)

  // Document metadata and page
  set document(
    title: title,
    author: document-authors,
    date: metadata-date,
  )
  set page(
    paper: "us-letter",
    numbering: "1",
    margin: (top: 1in, bottom: 1in, left: 1.25in, right: 1.25in),
    header: _article-header(logo),
    header-ascent: 15%,
    footer: _article-footer(footer, font-size),
    footer-descent: 35%,
  )

  // Typography
  set text(
    font: "DM Sans 9pt",
    size: font-size,
    weight: "regular",
    fill: mutt-ink,
    lang: language,
    hyphenate: auto,
  )
  set smartquote(quotes: curly-double-quotes)
  show math.equation: set text(font: "New Computer Modern Math")
  show math.equation: set block(breakable: true)
  show: code-style.with(size: _footnote-size(font-size))
  show link: it => text(fill: mutt-blue, underline(it))
  show ref: number-only-reference(
    color: mutt-blue,
    supplement: _article-reference-supplement,
  )
  show cite: set text(fill: mutt-blue)
  set bibliography(style: mybibstyle)
  show bibliography: set text(size: _footnote-size(font-size))
  show bibliography: set block(spacing: bibliography-entry-spacing)
  set par(
    leading: 0.75em,
    spacing: 1.2em,
    first-line-indent: 0pt,
    justify: true,
  )
  set block(spacing: 1em)
  set list(
    marker: (
      [#text(size: 0.8em)[●]],
      [–],
      [▪],
    ),
  )
  set table(stroke: 0.5pt + mutt-muted)

  // Numbering and components
  set heading(numbering: "1.1")
  show heading.where(numbering: none): set heading(outlined: false)
  set math.equation(
    numbering: none,
    number-align: left + horizon,
    supplement: none,
  )
  set figure(numbering: n => _article-numbering(n), gap: 5pt)
  show figure.caption: show-figure-caption.with(_small-size(font-size))
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "theorem"): show-statement
  show heading.where(level: 1): it => {
    if it.numbering != none { _reset-article-numbering() }
    block(above: 22pt, below: 12pt)[
      #set text(size: 16pt, weight: "regular", fill: mutt-navy)
      #_heading-title(it)
    ]
  }
  show heading.where(level: 2): it => {
    context if _appendix-mode.get() { _reset-article-numbering() }
    block(above: 18pt, below: 11pt)[
      #set text(size: 14pt, weight: "regular", fill: mutt-navy)
      #_heading-title(it)
    ]
  }
  show heading.where(level: 3): it => block(above: 14pt, below: 9pt)[
    #set text(size: 12pt, weight: "regular", fill: mutt-navy)
    #_heading-title(it)
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

  // Front matter and content
  _article-title(
    title,
    subtitle,
    displayed-date,
    authors,
    audience,
    displayed-revised-date,
  )
  if toc {
    let contents-title = if language == "es" { [Índice] } else { [Contents] }
    document-outline(contents-title, depth: 2)
  }
  body
}
