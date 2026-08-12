#import "@local/latex-article:0.1.0": *

#show: latex-article.with(
  title: [Article title],
  author: "Author",
  date: datetime.today().display(),
  short-title: [Short article title],
  language: "es",
  abstract: [Write the abstract here.],
  keywords: "keyword one, keyword two",
  jel: [A10, C10],
  toc: false,
)

= Introduction

The first paragraph after a heading is not indented, matching the traditional
LaTeX article style. It is justified and hyphenated according to the selected
language.

The following paragraphs have a 15-point first-line indent and no additional
vertical separation. This creates the continuous texture of a typeset article.

== A subsection

Displayed equations use New Computer Modern Math and place their numbers on
the left:

$ x^2 + y^2 = z^2 $ <pythagoras>
