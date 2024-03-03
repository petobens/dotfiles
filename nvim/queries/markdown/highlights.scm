;; extends
; From: https://github.com/ribru17/.dotfiles/blob/master/.config/nvim/queries/markdown/highlights.scm

; Headings
((atx_h1_marker) @markup.heading.1 (#set! conceal "󰪥"))
((atx_h2_marker) @markup.heading.2 (#set! conceal "󰺕"))
((atx_h3_marker) @markup.heading.3 (#set! conceal ""))
((atx_h4_marker) @markup.heading.4 (#set! conceal ""))
((atx_h5_marker) @markup.heading.5 (#set! conceal ""))

; Bullets (using custom offset directive)
([
  (list_marker_minus)
  (list_marker_plus)
  (list_marker_star)
] @markup.list
  (#offset-first-n! @markup.list 1)
  (#set! conceal "○"))

(list
  (list_item
    (list
      (list_item
        ([
          (list_marker_minus)
          (list_marker_plus)
          (list_marker_star)
        ] @markup.list
          (#offset-first-n! @markup.list 1)
          (#set! conceal "•"))))))

(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            ([
              (list_marker_minus)
              (list_marker_plus)
              (list_marker_star)
            ] @markup.list
              (#offset-first-n! @markup.list 1)
              (#set! conceal ""))))))))

(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            (list
              (list_item
                ([
                  (list_marker_minus)
                  (list_marker_plus)
                  (list_marker_star)
                ] @markup.list
                  (#offset-first-n! @markup.list 1)
                  (#set! conceal "-"))))))))))

; Checkboxes
((task_list_marker_unchecked)
    @markup.todo.unchecked.conceal
    (#offset! @markup.todo.unchecked.conceal 0 -2 0 0)
    (#set! conceal ""))
((task_list_marker_checked)
    @markup.todo.checked.conceal
    (#offset! @markup.todo.checked.conceal 0 -2 0 0)
    (#set! conceal ""))

; Tables
(pipe_table_header ("|") @punctuation.special (#set! conceal "│"))
(pipe_table_row ("|") @punctuation.special (#set! conceal "│"))
(pipe_table_delimiter_row ("|") @punctuation.special (#set! conceal "│"))
(pipe_table_delimiter_cell ("-") @punctuation.special (#set! conceal "─"))

; Code
((fenced_code_block_delimiter) @conceal (#set! conceal ""))

; Block quotes
((block_quote_marker) @punctuation.special.block.conceal
  (#offset! @punctuation.special.block.conceal 0 0 0 -1)
  (#set! conceal "▐"))

((block_continuation) @punctuation.special.block.conceal
  (#lua-match? @punctuation.special.block.conceal "^>")
  (#offset-first-n! @punctuation.special.block.conceal 1)
  (#set! conceal "▐"))

; Wiki links
([
    "["
    "["
    "]"
    "]"
 ] @conceal (#set! conceal ""))

; Comments
((html_block) @markup.comment)

; YAML front matter
((minus_metadata) @front_matter)
