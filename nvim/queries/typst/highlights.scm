; extends

; Several rules can capture the same text and the highest priority wins. Upstream
; typst sits at 100, so each rule below re-captures a piece of it and outbids that.
; #offset! shrinks a capture, letting a wider, lower one show through at the edges

; Math

; $x + y$ is all @markup.math, so re-capture the $ signs alone
((math
  "$" @punctuation.delimiter.math)
  (#set! priority 130))

; Symbol names such as succ and succ.tilde. Repeated per parent because formula
; children alone miss the ones nested deeper. A symbol written against its
; delimiter, as in in(0, 1), parses as a call instead and keeps the function-call
; color on purpose: write in (0, 1) so it stays a symbol. Priority 140 lets a
; symbol inside a subscript or superscript retain this color over the broader
; script capture below
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

; Shorthands are always operators, such as >=, -> and |->
((formula
  (shorthand) @operator.math)
  (#set! priority 120))

; Symbols double as punctuation, so keep only the operator-like ones
((formula
  (symbol) @operator.math)
  (#any-of? @operator.math
    "-" "+" "*" "<" ">" "=")
  (#set! priority 120))

; The slash in 1 / 2 is anonymous, so upstream gives it the plain code @operator
((fraction
  "/" @operator.math)
  (#set! priority 120))

; Whole scripts, at 130 so x_2 and y^2 beat any operator nested inside them
([
  (attach
    "_" @markup.math.script
    sub: (_) @markup.math.script)
  (attach
    "^" @markup.math.script
    sup: (_) @markup.math.script)
]
  (#set! priority 130))

; References and labels

; @def:name is one node, so one capture does it
((ref) @markup.link.reference.typst
  (#set! priority 120))

; <def:name> wants two colors: paint all of it here, then #offset! repaints just the
; name below, leaving < and > showing this one
((label) @punctuation.bracket.typst
  (#set! priority 110))

((label) @markup.link.label.typst
  (#offset! @markup.link.label.typst 0 1 0 -1)
  (#set! priority 120))

; In ref(<def:name>) and cite(<source>) the name refers instead of declaring
((call
  item: (ident) @_ref
  (group
    (label) @markup.link.reference.typst))
  (#any-of? @_ref "ref" "cite")
  (#offset! @markup.link.reference.typst 0 1 0 -1)
  (#set! priority 130))
