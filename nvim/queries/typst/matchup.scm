(content
  "[" @open.content
  "]" @close.content) @scope.content

(group
  "(" @open.group
  ")" @close.group) @scope.group

(block
  "{" @open.block
  "}" @close.block) @scope.block

(math
  "$" @open.math
  "$" @close.math) @scope.math

(label
  "<" @open.label
  ">" @close.label) @scope.label

(string
  "\"" @open.string
  "\"" @close.string) @scope.string
