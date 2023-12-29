;; extends

; To make it work inside injected languages
; https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/131#issuecomment-950532657
(fenced_code_block (code_fence_content) @class.inner) @class.outer
(paragraph) @function.outer @function.inner
