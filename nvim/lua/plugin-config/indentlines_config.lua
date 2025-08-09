local hooks = require('ibl.hooks')

require('ibl').setup({
    enabled = false,
    indent = { char = '|' },
    scope = { enabled = true, char = '│', show_start = false, show_end = false },
})
hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)

vim.keymap.set('n', '<Leader>I', vim.cmd.IBLToggle, { desc = 'Toggle indent lines' })
