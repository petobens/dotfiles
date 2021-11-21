local u = require('utils')

require('commented').setup({
    comment_padding = " ",
    keybindings = {
        n = "<Leader>cc",
        v = "<Leader>cc",
        nl = "<Leader>cc"
    }

})


u.keymap('n', '<Leader>cu', 'v:lua.require("commented").commented_line()', {expr = true})
u.keymap('v', '<Leader>cu', 'v:lua.require("commented").commented()', {expr = true})
