local u = require('utils')

require('indent_blankline').setup({
    enabled = false,
    use_treesitter = true,
    char = '|',
})

u.keymap('n', '<Leader>I', ':IndentBlanklineToggle<CR>')
