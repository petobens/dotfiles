local utils = require('utils')

utils.keymap('i', 'jj', '<ESC>', {noremap = false})
utils.keymap('n', ';', ':', {noremap = false, silent = false})

-- Save
utils.keymap('n', '<Leader>w', ':w!<CR>')
utils.keymap('n', '<Leader>kv', ':qall<CR>')
utils.keymap('n', '<Leader>wc', ':w!<CR>:silent close<CR>')
utils.keymap('n', '<Leader>wq', ':w!<CR>:q!<CR>')

-- Window buffer manipulation
utils.keymap('n', '<Leader>wd', ':bd<CR>')
utils.keymap('n', '<Leader>bd', ':bp|bd #<CR>')
utils.keymap('n', '<C-n>', ':bn<CR>')
utils.keymap('n', '<C-p>', ':bp<CR>')

-- Window movement
utils.keymap('n', '<Leader>vs', ':vsplit<CR>')
utils.keymap('n', '<Leader>sp', ':split<CR>')
utils.keymap('n', '<c-h>', '<C-W>h')
utils.keymap('n', '<c-j>', '<C-W>j')
utils.keymap('n', '<c-k>', '<C-W>k')
utils.keymap('n', '<c-l>', '<C-W>l')
utils.keymap('n', '<c-c>', '<C-W>c')

-- Line/Editing Movement
utils.keymap('n', 'H', '0',  {noremap = false})
utils.keymap('n', 'L', 'g_',  {noremap = false})
utils.keymap('v', 'L', 'g_',  {noremap = false})
utils.keymap('n', '<tab>', '%',  {noremap = false})
utils.keymap('n', '<A-j>', ':move +1<CR>')
utils.keymap('n', '<A-k>', ':move -2<CR>')
utils.keymap('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w')

-- Yanking pasting
utils.keymap('n', 'Y', 'y$',  {noremap = false})
utils.keymap('n', '<Leader>p', ':put<CR>',  {noremap = false})
utils.keymap('n', '<Leader>P', ':put!<CR>',  {noremap = false})

-- Search
utils.keymap('n', '<Leader><Space>', ':set hlsearch!<CR>')


-- Commented
-- FIXME
utils.keymap('n', '<Leader>cp', ":lua require('commented').toggle_comment('n')<CR>")
