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
utils.keymap('n', '<C-h>', '<C-W>h')
utils.keymap('n', '<C-j>', '<C-W>j')
utils.keymap('n', '<C-k>', '<C-W>k')
utils.keymap('n', '<C-l>', '<C-W>l')
utils.keymap('n', '<C-c>', '<C-W>c')

-- Line/Editing Movement
utils.keymap('n', '<up>', '<nop>',  {noremap = false})
utils.keymap('n', '<down>', '<nop>',  {noremap = false})
utils.keymap('n', '<left>', '<nop>',  {noremap = false})
utils.keymap('n', '<right>', '<nop>',  {noremap = false})
utils.keymap('n', 'j', 'gj',  {noremap = false})
utils.keymap('n', 'k', 'gk',  {noremap = false})
utils.keymap('n', 'H', '^',  {noremap = false})
utils.keymap('n', 'L', '$',  {noremap = false})
utils.keymap('v', 'L', 'g_',  {noremap = false})
utils.keymap('n', '<tab>', '%',  {noremap = false})
utils.keymap('n', '<A-j>', ':move +1<CR>')
utils.keymap('n', '<A-k>', ':move -2<CR>')
-- FIXME: not working
utils.keymap('v', '<A-j>', ':move +1<CR>')
utils.keymap('v', '<A-k>', ':move -2<CR>')
utils.keymap('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w')
utils.keymap('n', '<Leader>ic', ':set list!<CR>')

-- Yanking pasting
utils.keymap('n', 'Y', 'y$',  {noremap = false})
utils.keymap('n', '<Leader>p', ':put<CR>')
utils.keymap('n', '<Leader>P', ':put!<CR>')

-- Search
utils.keymap('n', '<Leader><Space>', ':set hlsearch!<CR>')
utils.keymap('n', '/', '/\\v', {silent = false, noremap = false})
utils.keymap('n', '?', '?\\v', {silent = false, noremap = false})
utils.keymap('v', '/', '/\\v', {silent = false, noremap = false})
utils.keymap('v', '?', '?\\v', {silent = false, noremap = false})
utils.keymap('n', 'n', 'nzzzv', {noremap = false})
utils.keymap('n', 'N', 'Nzzzv', {noremap = false})

-- Spelling
utils.keymap('n', '<Leader>sc', ':set spell!<CR>')

-- Commented
-- FIXME
utils.keymap('n', '<Leader>cp', ":lua require('commented').toggle_comment('n')<CR>")
