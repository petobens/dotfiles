;; extends

; Headings
((atx_h1_marker) @text.title.1.conceal (#set! conceal "󰪥"))
((atx_h2_marker) @text.title.2.conceal (#set! conceal "󰺕"))
((atx_h3_marker) @text.title.3.conceal (#set! conceal ""))
((atx_h4_marker) @text.title.4.conceal (#set! conceal ""))
((atx_h5_marker) @text.title.5.conceal (#set! conceal "○"))

; Lists
; FIXME: no space between symbol and text https://github.com/MDeiml/tree-sitter-markdown/issues/41#issuecomment-1788150743
((list_marker_minus) @punctuation.special.list_minus.conceal (#set! conceal "•"))

; Checkboxes
(list_item [
  (list_marker_minus)
  (list_marker_star)
] @punctuation.special [
    (task_list_marker_checked)
    (task_list_marker_unchecked)
](#set! conceal ""))
((task_list_marker_checked) @text.todo.checked.conceal (#set! conceal ""))
((task_list_marker_unchecked) @text.todo.unchecked.conceal (#set! conceal ""))

; Code
((fenced_code_block_delimiter) @conceal (#set! conceal ""))

; Wiki links
([
    "["
    "["
    "]"
    "]"
 ] @conceal (#set! conceal ""))
