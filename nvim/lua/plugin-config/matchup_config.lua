local u = require('utils')

vim.g.matchup_matchparen_enabled = 0

u.keymap({ 'n', 'v', 'o' }, '<tab>', '%', { remap = true })
u.keymap({ 'n', 'v', 'o' }, '<s-tab>', 'g%', { remap = true })
