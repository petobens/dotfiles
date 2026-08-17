; extends

; Extend upstream captures where the parser classifies math syntax too generically
; Upstream defaults to priority 100, so 120 and 130 make narrower captures win

; Capture math delimiters that upstream leaves inside @markup.math, as in $x + y$
((math
  "$" @punctuation.delimiter.math)
  (#set! priority 130))

; Reclassify named symbols and dotted paths, such as succ and succ.tilde
((formula
  [
    (field)
    (ident)
  ] @operator.math)
  (#set! priority 120))

; Reclassify operators represented as symbols or shorthands, such as + and >=
((formula
  [
    (shorthand)
    (symbol)
  ] @operator.math)
  (#any-of? @operator.math
    "-" "+" "*" "!=" "<" "<=" ">" ">=" "=")
  (#set! priority 120))

; Give the slash nested inside fractions such as 1 / 2 a math-specific capture
((fraction
  "/" @operator.math)
  (#set! priority 120))

; Reclassify in[0, 1] and in(0, 1), which parse as application or a call
([
  (apply
    item: (ident) @operator.math)
  (call
    item: (ident) @operator.math)
]
  (#eq? @operator.math "in")
  (#set! priority 120))

; Reclassify attached symbols such as succ.tilde_i nested below the formula
((formula
  (attach
    [
      (field)
      (ident)
    ] @operator.math))
  (#set! priority 120))

; Override nested token colors for both parts of scripts such as x_2 and y^2
([
  (attach
    "_" @markup.math.script
    sub: (_) @markup.math.script)
  (attach
    "^" @markup.math.script
    sup: (_) @markup.math.script)
]
  (#set! priority 130))

; References and labels, such as @def:name and <def:name>
((ref) @markup.link.reference.typst
  (#set! priority 120))

((label) @punctuation.bracket.typst
  (#set! priority 110))

((label) @markup.link.label.typst
  (#offset! @markup.link.label.typst 0 1 0 -1)
  (#set! priority 120))

; Labels passed to ref(<def:name>) and cite(<source>)
((call
  item: (ident) @_ref
  (group
    (label) @markup.link.reference.typst))
  (#any-of? @_ref "ref" "cite")
  (#offset! @markup.link.reference.typst 0 1 0 -1)
  (#set! priority 130))
