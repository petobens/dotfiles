local u = require('utils')

vim.g.matchup_matchparen_enabled = 0

u.keymap({ 'n', 'v', 'o', 'x' }, '<Tab>', '<Plug>(matchup-%)')
