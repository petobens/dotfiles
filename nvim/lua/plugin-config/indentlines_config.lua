local u = require('utils')

require('indent_blankline').setup({
    enabled = false,
    use_treesitter = true,
    char = '|',
    show_current_context = true,
})

u.keymap('n', '<Leader>I', '<Cmd>IndentBlanklineToggle<CR>')
