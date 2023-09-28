local hooks = require('ibl.hooks')
local ibl = require('ibl')
local u = require('utils')

ibl.setup({
    enabled = false,
    indent = { char = '|' },
    scope = { enabled = true, char = '│', show_start = false, show_end = false },
})
hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)

u.keymap('n', '<Leader>I', '<Cmd>IBLToggle<CR>')
