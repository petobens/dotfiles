; extends

(begin
  command: _ @markup.environment
  name: (curly_group_text
    (text) @markup.environment.name
    (#set! "priority" 1000)))

(end
  command: _ @markup.environment
  name: (curly_group_text
    (text) @markup.environment.name)
  (#set! "priority" 1000))

(inline_formula
  "$" @md_latex_equation_dollar)

(displayed_equation
  "$$" @md_latex_equation_double_dollar)
