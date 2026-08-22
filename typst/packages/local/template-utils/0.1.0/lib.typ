#import "@preview/subpar:0.2.2"

// Code
#let onedark-theme = read("onedark.tmTheme", encoding: none)
#let onedark-foreground = rgb("#24272E")
#let onedark-code-block = block.with(
  stroke: 0.5pt + rgb("#D9E0ED"),
  inset: 10pt,
  radius: 4pt,
)
#let code-style(body, size: 0.8em, width: 100%) = {
  set raw(theme: onedark-theme)
  show raw: set text(font: "DejaVu Sans Mono", size: size)
  show raw.where(block: true): set text(fill: onedark-foreground)
  show raw.where(block: true): onedark-code-block.with(width: width)
  body
}

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
#let footnote-rule-spacing = 0.3cm
#let footnote-separator = block[
  #line(length: 2.5cm, stroke: 0.4pt)
  #v(footnote-rule-spacing)
]

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

// Lists
#let wide-enum = {
  let format-number = numbering
  (
    body,
    numbering: "(1)",
    // Places "(i)" at the 1.5em paragraph indent
    label-width: 2.55em,
    body-indent: 0.5em,
    above: 0.5em,
    spacing: 0pt,
  ) => {
    show enum: it => {
      let start = if it.start == auto { 1 } else { it.start }
      for (index, item) in it.children.enumerate() {
        block(
          width: 100%,
          breakable: true,
          above: if index == 0 { above } else { spacing },
        )[
          #box(
            width: label-width,
            align(right, format-number(numbering, index + start)),
          )#h(body-indent)#item.body
        ]
      }
    }
    parbreak()
    body
  }
}

#let labeled-item(label, body, indent: 1em, above: 1em) = block(
  width: 100%,
  breakable: true,
  above: above,
)[
  #par(first-line-indent: (
    amount: indent,
    all: true,
  ))[#emph[#label]. #body]
]

// Tables
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
#let show-outline-entry(it, page-number, top-level-spacing: 2em) = {
  let index = calc.min(it.level, 3) - 1
  let indents = (0em, 1.5em, 3.8em)
  let number-widths = (1.5em, 2.3em, 3.2em)
  let number = if it.element.numbering != none {
    box(width: number-widths.at(index))[
      #numbering(
        it.element.numbering,
        ..counter(heading).at(it.element.location()),
      )
    ]
  }
  block(
    width: 100%,
    above: if it.level == 1 { top-level-spacing } else { 0.65em },
    below: 0.1em,
  )[
    #set text(weight: if it.level == 1 { "bold" } else { "regular" })
    #h(indents.at(index))#number#text(fill: black, it.element.body)
    #if it.level == 1 {
      box(width: 1fr)[]
    } else {
      box(width: 1fr, inset: (x: 0.2em), repeat(gap: 0.45em)[.])
    }
    #text(fill: navy)[#link(it.element.location())[#page-number]]
  ]
}

#let document-outline(title, depth: none) = {
  if title != none {
    heading(
      level: 1,
      numbering: none,
      outlined: false,
      bookmarked: true,
      title,
    )
  }
  outline(title: none, depth: depth)
}

// Math
#let notsuccsim = math.class("relation", [≿̸])

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
    panel-height: auto,
  ) = {
    let children = children.pos()
    let figures = ()
    for child in children {
      let body = if panel-height == auto {
        child.body
      } else {
        block(width: 100%, height: panel-height)[#align(bottom, child.body)]
      }
      figures.push(figure(body, caption: child.caption))
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
      gap: 0pt,
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
#let restore-paragraph-indent = [#h(0pt)#v(-0.5em)]

#let show-statement(it) = {
  block(width: 100%, breakable: true)[
    #set align(left)
    #it.supplement
    #if it.numbering != none { [ #context it.counter.display(it.numbering)] }
    #if it.caption != none and it.caption.body != [] { [ #it.caption.body] }
    #h(0.25em)
    #it.body
  ]
  restore-paragraph-indent
}

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
    localized-title(title, [Notación.], [Notation.]),
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

#let proof(body, title: auto) = {
  block(width: 100%, breakable: true, above: 0.8em)[
    #emph(localized-title(title, [Demostración], [Proof])). #body
    #place(right, dy: -0.85em)[$square$]
  ]
  restore-paragraph-indent
}

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
