; extends

((math
  "$" @punctuation.delimiter.math)
  (#set! priority 130))

((ref) @markup.link.reference.typst
  (#set! priority 120))

((label) @punctuation.bracket.typst
  (#set! priority 110))

((label) @markup.link.label.typst
  (#offset! @markup.link.label.typst 0 1 0 -1)
  (#set! priority 120))

((call
  item: (ident) @_ref
  (group
    (label) @markup.link.reference.typst))
  (#any-of? @_ref "ref" "cite")
  (#offset! @markup.link.reference.typst 0 1 0 -1)
  (#set! priority 130))
