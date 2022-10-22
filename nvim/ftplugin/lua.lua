local u = require('utils')

u.keymap(
    'n',
    '<Leader>rf',
    '<Cmd>update<CR>:luafile %<CR>',
    { silent = false, buffer = true }
)
