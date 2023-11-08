local u = require('utils')

require('sniprun').setup({})

u.keymap({ 'n', 'v' }, '<Leader>br', '<Plug>SnipRun')
u.keymap('n', '<Leader>bc', '<Plug>SnipClose')
u.keymap('n', '<Leader>bw', '<Plug>SnipReset')
