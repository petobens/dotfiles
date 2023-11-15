;; extends

; From https://github.com/ribru17/nvim/commit/b75c2e776bed8a28e4d84198d5702cd272503c8e#r132581072
((shortcut_link)
 @text.todo.doing.conceal
 (#eq? @text.todo.doing.conceal "[_]")
 (#offset! @text.todo.doing.conceal 0 -2 0 0)
 (#set! conceal "󰄮"))
((shortcut_link)
 @text.todo.wontdo.conceal
 (#eq? @text.todo.wontdo.conceal "[~]")
 (#offset! @text.todo.wontdo.conceal 0 -2 0 0)
 (#set! conceal "󰅗"))
