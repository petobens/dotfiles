;; extends

; From https://github.com/ribru17/nvim/commit/b75c2e776bed8a28e4d84198d5702cd272503c8e#r132581072
((shortcut_link)
 @markup.todo.doing.conceal
 (#eq? @markup.todo.doing.conceal "[_]")
 (#offset! @markup.todo.doing.conceal 0 -2 0 0)
 (#set! conceal "󰄮"))
((shortcut_link)
 @markup.todo.wontdo.conceal
 (#eq? @markup.todo.wontdo.conceal "[~]")
 (#offset! @markup.todo.wontdo.conceal 0 -2 0 0)
 (#set! conceal "󰅗"))
