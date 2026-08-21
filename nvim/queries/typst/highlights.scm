; extends

; Upstream uses priority 100 for broad captures. These narrower, higher-priority
; captures preserve syntax colors where their ranges overlap

; Math

; Color math delimiters separately from their contents
((math
  "$" @punctuation.delimiter.math)
  (#set! priority 130))

; Color named calls such as frac, tilde and place
((call
  item: [
    (ident)
    (field)
  ] @function.call)
  (#set! priority 130))

; Match a code marker to the call it introduces
((code
  "#" @function.call
  (call))
  (#set! priority 130))

; Symbol names may be children of a formula, attachment, or fraction. Priority
; 140 keeps them visible inside scripts at 130. A name touching its delimiter,
; as in in(0, 1), parses as a call; write in (0, 1) to keep it a symbol
([
  (formula
    [
      (field)
      (ident)
    ] @operator.math)
  (attach
    [
      (field)
      (ident)
    ] @operator.math)
  (fraction
    [
      (field)
      (ident)
    ] @operator.math)
]
  (#set! priority 140))

; Typst parses operators such as >=, -> and |-> as shorthands
((formula
  (shorthand) @operator.math)
  (#set! priority 120))

; Only the arithmetic and relation symbols are operators
((formula
  (symbol) @operator.math)
  (#any-of? @operator.math
    "-" "+" "*" "<" ">" "=")
  (#set! priority 120))

; A fraction owns its slash directly rather than through a formula node
((fraction
  "/" @operator.math)
  (#set! priority 120))

; Color complete scripts at 130; symbol names above still win at 140
([
  (attach
    "_" @markup.math.script
    sub: (_) @markup.math.script)
  (attach
    "^" @markup.math.script
    sup: (_) @markup.math.script)
]
  (#set! priority 130))

; Labels and references

; Direct references such as @fig:name are single nodes
((ref) @markup.link.reference.typst
  (#set! priority 120))

; Labels use blue brackets and an orange name. #offset! narrows the second
; capture to leave the brackets visible from the first
((label) @punctuation.bracket.typst
  (#set! priority 110))

((label) @markup.link.label.typst
  (#offset! @markup.link.label.typst 0 1 0 -1)
  (#set! priority 120))

; A label inside ref() or cite() is a reference, not a declaration
((call
  item: (ident) @_ref
  (group
    (label) @markup.link.reference.typst))
  (#any-of? @_ref "ref" "cite")
  (#offset! @markup.link.reference.typst 0 1 0 -1)
  (#set! priority 130))
