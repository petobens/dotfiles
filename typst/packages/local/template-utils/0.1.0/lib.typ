// Localization
#let localized(spanish, english) = context {
  if text.lang == "es" { spanish } else { english }
}

#let localized-title(title, spanish, english) = {
  if title == auto { localized(spanish, english) } else { title }
}

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

// Colors and tables
#let navy = rgb("#000080")

#let latex-table(columns, header, rows, align: auto) = table(
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

// Numbering and captions
#let reset-numbering() = {
  counter(math.equation).update(0)
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(figure.where(kind: "theorem")).update(0)
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
#let show-statement(it) = align(left, block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #strong[
    #it.supplement
    #if it.numbering != none { [ #context it.counter.display(it.numbering)] }
    #if it.caption != none and it.caption.body != [] { [ (#it.caption.body)] }
  ] #it.body
])

#let statement-environments(numbering-fn) = {
  let statement(
    supplement,
    body,
    note: none,
    italic: false,
    numbered: true,
  ) = figure(
    if italic { emph(body) } else { body },
    kind: "theorem",
    supplement: supplement,
    numbering: if numbered { numbering-fn } else { none },
    caption: if note == none { [] } else { note },
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
  let exercise(body, note: none, title: auto, numbered: true) = statement(
    localized-title(title, [Ejercicio], [Exercise]),
    body,
    note: note,
    numbered: numbered,
  )
  let remark(body, note: none, title: auto, numbered: true) = statement(
    emph(localized-title(title, [Observación], [Remark])),
    body,
    note: note,
    numbered: numbered,
  )
  let notation(body, note: none, title: auto, numbered: true) = statement(
    emph(localized-title(title, [Notación], [Notation])),
    body,
    note: note,
    numbered: numbered,
  )
  let solution(body, note: none, title: auto) = statement(
    localized-title(title, [Solución], [Solution]),
    body,
    note: note,
    numbered: false,
  )

  (
    statement: statement,
    theorem: theorem,
    proposition: proposition,
    lemma: lemma,
    corollary: corollary,
    definition: definition,
    example: example,
    exercise: exercise,
    remark: remark,
    notation: notation,
    solution: solution,
  )
}

#let proof(body, title: auto) = block(width: 100%)[
  #set par(first-line-indent: 0pt)
  #emph(localized-title(title, [Demostración], [Proof])). #body #h(1fr) $square$
]
