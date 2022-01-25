local u = require('utils')

u.keymap('n', '<Leader>gd', '<Cmd>Gdiffsplit<CR><Cmd>wincmd x<CR>')
u.keymap('n', '<Leader>gs', '<Cmd>botright Git<CR><Cmd>wincmd J<bar>15 wincmd _<CR>')
u.keymap('n', '<Leader>gM', '<Cmd>Git! mergetool<CR>')
u.keymap('n', '<Leader>gr', ':Git rebase -i<space>', { silent = false })
u.keymap({ 'n', 'v' }, '<Leader>gb', '<Cmd>GBrowse<CR>')
u.keymap({ 'n', 'v' }, '<Leader>gB', '<Cmd>GBrowse!<CR>')
