local u = require('utils')

vim.g.indent_blankline_enabled = false
vim.g.indent_blankline_use_treesitter = true
vim.g.indent_blankline_char = '|'

u.keymap('n', '<Leader>I', ':IndentBlanklineToggle<CR>')
