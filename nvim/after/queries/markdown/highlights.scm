;; extends
; Mostly from: https://github.com/ribru17/nvim/blob/master/queries/markdown/highlights.scm

; Headings
((atx_h1_marker) @text.title.1.conceal (#set! conceal "󰪥"))
((atx_h2_marker) @text.title.2.conceal (#set! conceal "󰺕"))
((atx_h3_marker) @text.title.3.conceal (#set! conceal ""))
((atx_h4_marker) @text.title.4.conceal (#set! conceal ""))
((atx_h5_marker) @text.title.5.conceal (#set! conceal "○"))

; Bullets
([(list_marker_minus) (list_marker_star)]
 @punctuation.special.bullet.conceal
 (#offset! @punctuation.special.bullet.conceal 0 0 0 -1)
 (#set! conceal "○"))
(list
  (list_item
    (list
      (list_item
        ([(list_marker_minus) (list_marker_star)]
         @punctuation.special.bullet.conceal
         (#offset! @punctuation.special.bullet.conceal 0 0 0 -1)
         (#set! conceal "•"))))))
(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            ([(list_marker_minus) (list_marker_star)]
             @punctuation.special.bullet.conceal
             (#offset! @punctuation.special.bullet.conceal 0 0 0 -1)
             (#set! conceal ""))))))))
(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            (list
              (list_item
                ([(list_marker_minus) (list_marker_star)]
                 @punctuation.special.bullet.conceal
                 (#offset! @punctuation.special.bullet.conceal 0 0 0 -1)
                 (#set! conceal "-"))))))))))

; Checkboxes
((task_list_marker_unchecked)
    @text.todo.unchecked.conceal
    (#offset! @text.todo.unchecked.conceal 0 -2 0 0)
    (#set! conceal ""))
((task_list_marker_checked)
    @text.todo.checked.conceal
    (#offset! @text.todo.checked.conceal 0 -2 0 0)
    (#set! conceal ""))

; Tables
(pipe_table_header ("|") @punctuation.special (#set! conceal "│"))
(pipe_table_row ("|") @punctuation.special (#set! conceal "│"))
(pipe_table_delimiter_row ("|") @punctuation.special (#set! conceal "│"))
(pipe_table_delimiter_cell ("-") @punctuation.special (#set! conceal "─"))

; Code
((fenced_code_block_delimiter) @conceal (#set! conceal ""))

; Wiki links
([
    "["
    "["
    "]"
    "]"
 ] @conceal (#set! conceal ""))
