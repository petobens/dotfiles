#import "@preview/subpar:0.2.2"

// Localization
#let curly-double-quotes = (
  double: ("“", "”"),
  single: auto,
)

#let bibliography-entry-spacing = 0.8em

#let localized(spanish, english) = context {
  if text.lang == "es" { spanish } else { english }
}

#let localized-title(title, spanish, english) = {
  if title == auto { localized(spanish, english) } else { title }
}

#let optional-value-present(value) = (
  value != none and value != [] and value != ""
)

#let format-bibliography-backrefs(links) = [
  \[#localized([Vea], [See]) #if links.len() == 1 { [p. ] } else {
    [pp. ]
  }#links.join(", ")\]
]

#let localized-date(date, language) = {
  if type(date) != datetime { date } else {
    let months = if language == "es" {
      (
        "Enero",
        "Febrero",
        "Marzo",
        "Abril",
        "Mayo",
        "Junio",
        "Julio",
        "Agosto",
        "Septiembre",
        "Octubre",
        "Noviembre",
        "Diciembre",
      )
    } else {
      (
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      )
    }
    [#months.at(date.month() - 1) #date.year()]
  }
}

// Footnotes
#let footnote-separator = line(length: 2.5cm, stroke: 0.4pt)

#let show-footnote-entry(it, size: 9pt) = context {
  set text(size: size)
  let location = it.note.location()
  h(15pt)
  counter(footnote).display(at: location, "1. ")
  it.note.body
}

// Colors and tables
#let navy = rgb("#000080")

#let number-only-reference(color: navy, supplement: auto) = it => context {
  let targets = query(it.target)
  if it.supplement == none or it.form != "normal" or targets.len() == 0 {
    text(fill: color, it)
  } else {
    let target = targets.first()
    let requested-supplement = if it.supplement != auto {
      it.supplement
    } else if type(supplement) == function {
      supplement(target)
    } else {
      supplement
    }
    let resolved-supplement = if requested-supplement == auto {
      target.supplement
    } else {
      requested-supplement
    }
    if resolved-supplement == none or resolved-supplement == [] {
      text(fill: color, it)
    } else {
      {
        show strong: it => it.body
        show emph: it => it.body
        resolved-supplement
      }
      [ ]
      {
        show strong: it => it.body
        show emph: it => it.body
        ref(it.target, supplement: none)
      }
    }
  }
}

#let show-number-only-reference = number-only-reference()

#let latex-table(
  columns: 1,
  header: (),
  rows: (),
  align: auto,
  inset: (x: 6pt, y: 3.5pt),
) = table(
  columns: columns,
  align: align,
  inset: inset,
  stroke: none,
  table.hline(stroke: 0.8pt),
  table.header(..header),
  table.hline(stroke: 0.45pt),
  ..rows.flatten(),
  table.hline(stroke: 0.8pt),
)

// Table of contents
#let show-outline-entry(it, page-number) = block(
  width: 100%,
  above: if it.level == 1 { 2em } else { 0.85em },
  below: 0.1em,
)[
  #set text(weight: if it.level == 1 { "bold" } else { "regular" })
  #h(1.5em * (it.level - 1))
  #if it.element.numbering != none {
    numbering(
      it.element.numbering,
      ..counter(heading).at(it.element.location()),
    )
    h(0.3em)
  }
  #text(fill: black, it.element.body)
  #if it.level == 1 {
    box(width: 1fr)[]
  } else {
    box(width: 1fr, inset: (x: 0.2em), repeat(gap: 0.45em)[.])
  }
  #text(fill: navy)[#link(it.element.location())[#page-number]]
]

#let document-outline(title) = {
  if title != none {
    heading(
      level: 1,
      numbering: none,
      outlined: false,
      bookmarked: true,
      title,
    )
  }
  outline(title: none)
}

// Equations
#let equation-environment(numbering-fn) = body => math.equation(
  body,
  block: true,
  numbering: numbering-fn,
)

// Subfigures
#let subfigure-environments(numbering-fn, sub-ref-numbering: "a") = {
  let subfigure(body, caption: none, label: none) = (
    body: body,
    caption: caption,
    label: label,
  )

  let subfigure-grid(
    ..children,
    caption: none,
    label: none,
    placement: top,
    columns: auto,
  ) = {
    let children = children.pos()
    let figures = ()
    for child in children {
      figures.push(figure(child.body, caption: child.caption))
      if child.label != none { figures.push(child.label) }
    }
    subpar.grid(
      ..figures,
      columns: if columns == auto {
        array.range(children.len()).map(_ => 1fr)
      } else {
        columns
      },
      caption: caption,
      label: label,
      placement: placement,
      numbering: numbering-fn,
      numbering-sub: "(a)",
      numbering-sub-ref: (n, sub) => [#numbering-fn(n)#numbering(
          sub-ref-numbering,
          sub,
        )],
      show-sub-caption: (number, caption) => [
        #text(size: 8pt)[#strong[#number] #caption.body]
      ],
    )
  }

  (
    subfigure: subfigure,
    subfigure-grid: subfigure-grid,
  )
}

// Numbering and captions
#let reset-numbering(base: 0) = {
  counter(math.equation).update(base)
  counter(figure.where(kind: image)).update(base)
  counter(figure.where(kind: table)).update(base)
  counter(figure.where(kind: "theorem")).update(base)
}

#let heading-title(it) = context {
  if it.numbering != none {
    numbering(it.numbering, ..counter(heading).at(it.location()))
    h(0.8em)
  }
  it.body
}

#let show-figure-caption(it) = {
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

// Theorem environments
#let show-statement(it) = block(width: 100%, breakable: true)[
  #set align(left)
  #set par(first-line-indent: 0pt)
  #it.supplement
  #if it.numbering != none { [ #context it.counter.display(it.numbering)] }
  #if it.caption != none and it.caption.body != [] { [ #it.caption.body] }
  #h(0.25em)
  #it.body
]

#let statement-environments(numbering-fn) = {
  let statement(
    supplement,
    body,
    note: none,
    italic: false,
    numbered: true,
    emphasized-heading: false,
  ) = figure(
    if italic { emph(body) } else { body },
    kind: "theorem",
    supplement: if emphasized-heading { emph(supplement) } else {
      strong(supplement)
    },
    numbering: if not numbered {
      none
    } else if emphasized-heading {
      n => emph(numbering-fn(n))
    } else {
      n => strong(numbering-fn(n))
    },
    caption: if note == none {
      []
    } else if emphasized-heading {
      emph([(#note)])
    } else {
      strong([(#note)])
    },
    outlined: false,
    gap: 0.35em,
  )

  let theorem(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Teorema], [Theorem]),
    body,
    note: note,
    italic: true,
    numbered: numbered,
  )
  let proposition(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Proposición], [Proposition]),
    body,
    note: note,
    italic: true,
    numbered: numbered,
  )
  let lemma(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Lema], [Lemma]),
    body,
    note: note,
    italic: true,
    numbered: numbered,
  )
  let corollary(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Corolario], [Corollary]),
    body,
    note: note,
    italic: true,
    numbered: numbered,
  )
  let definition(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Definición], [Definition]),
    body,
    note: note,
    numbered: numbered,
  )
  let example(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Ejemplo], [Example]),
    body,
    note: note,
    numbered: numbered,
  )
  let continued-example(reference, body) = statement(
    [
      #localized(
        [Continuación del Ejemplo],
        [Continuation of Example],
      ) #context {
        let target = query(reference).first()
        (target.numbering)(..target.counter.at(target.location()))
      }
    ],
    body,
    numbered: false,
  )
  let exercise(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Ejercicio], [Exercise]),
    body,
    note: note,
    numbered: numbered,
  )
  let remark(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Observación], [Remark]),
    body,
    note: note,
    numbered: numbered,
    emphasized-heading: true,
  )
  let notation(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Notación], [Notation]),
    body,
    note: note,
    numbered: numbered,
    emphasized-heading: true,
  )
  let solution(body, note: none, title: auto) = statement(
    localized-title(title, [Solución], [Solution]),
    body,
    note: note,
    numbered: false,
  )

  (
    theorem: theorem,
    proposition: proposition,
    lemma: lemma,
    corollary: corollary,
    definition: definition,
    example: example,
    continued-example: continued-example,
    exercise: exercise,
    remark: remark,
    notation: notation,
    solution: solution,
  )
}

#let proof(body, title: auto) = block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #emph(localized-title(title, [Demostración], [Proof])). #body
  #place(right, dy: -0.85em)[$square$]
]

// Bibliography
#let mybibstyle = read(
  "mybibstyle.csl",
  encoding: none,
)

#let apply-mybibstyle(body) = {
  set bibliography(style: "mybibstyle.csl")
  body
}

#let read-mybibstyle(path) = read(path)
