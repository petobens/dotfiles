local u = require('utils')

-- Options
vim.opt_local.formatoptions = 'jcql'

-- Mappings
u.keymap(
    'n',
    '<Leader>rf',
    '<Cmd>update<CR>:luafile %<CR>',
    { silent = false, buffer = true }
)
