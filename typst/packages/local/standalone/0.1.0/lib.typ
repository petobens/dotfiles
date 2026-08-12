#let standalone(
  body,
  width: auto,
  margin: 3pt,
  fill: none,
  font: "New Computer Modern",
  math-font: "New Computer Modern Math",
  font-size: 10pt,
  language: "es",
) = {
  set page(
    width: width,
    height: auto,
    margin: margin,
    fill: fill,
  )
  set text(
    font: font,
    size: font-size,
    lang: language,
  )
  show math.equation: set text(font: math-font)
  show raw: set text(font: "DejaVu Sans Mono", size: 0.9em)
  set par(first-line-indent: 0pt)

  body
}
