local utils = require('utils')

-- Vim
utils.keymap('i', 'jj', '<ESC>')
utils.keymap('n', ';', ':', {silent = false})

-- Save
utils.keymap('n', '<Leader>kv', ':qall<CR>')
utils.keymap('n', '<Leader>nw', ':noautocmd w!<CR>')
utils.keymap('n', '<Leader>w', ':w!<CR>')
utils.keymap('n', '<Leader>wc', ':w!<CR>:silent close<CR>')
utils.keymap('n', '<Leader>wq', ':w!<CR>:q!<CR>')
utils.keymap('n', '<Leader>ps', ':silent! source ' .. _G.udfs.session_fn() .. '<CR>')

-- Buffer manipulation
utils.keymap('n', '<C-n>', ':bn<CR>')
utils.keymap('n', '<C-p>', ':bp<CR>')
utils.keymap('n', '<Leader>bd', ':bp|bd #<CR>')
utils.keymap('n', '<Leader>cd', ':lcd %:h<CR>')
utils.keymap('n', '<Leader>dd', ':e $HOME/Desktop/', {silent = false})
utils.keymap('n', '<Leader>rr', ':checktime<CR>')
utils.keymap('n', '<Leader>so', ':update<CR>:luafile %<CR>', {silent = false})
utils.keymap('n', '<Leader>wd', ':bd<CR>')

-- Window manipulation
utils.keymap('n', '<A-o>', '<C-W>ozv')
utils.keymap('n', '<C-A-h>', '<C-W>2<')
utils.keymap('n', '<C-A-j>', '<C-W>2+')
utils.keymap('n', '<C-A-k>', '<C-W>2-')
utils.keymap('n', '<C-A-l>', '<C-W>2>')
utils.keymap('n', '<C-c>', '<C-W>c')
utils.keymap('n', '<C-h>', [[<cmd>lua require('tmux').move_left()<CR>]])
utils.keymap('n', '<C-j>', [[<cmd>lua require('tmux').move_down()<CR>]])
utils.keymap('n', '<C-k>', [[<cmd>lua require('tmux').move_up()<CR>]])
utils.keymap('n', '<C-l>', [[<cmd>lua require('tmux').move_right()<CR>]])
utils.keymap('n', '<C-x>', '<C-W>xzz')
utils.keymap('n', '<Leader>sp', ':split<CR>')
utils.keymap('n', '<Leader>vs', ':vsplit<CR>')

-- Line editing/movement
-- FIXME: virtcol not working
utils.keymap('n', '<down>', '<nop>')
utils.keymap('n', '<left>', '<nop>')
utils.keymap('n', '<right>', '<nop>')
utils.keymap('n', '<up>', '<nop>')
utils.keymap('n', '+', '<C-a>')
utils.keymap('n', '-', '<C-x>')
utils.keymap('n', '<A-0>', 'H')
utils.keymap('n', '<A-b>', 'L')
utils.keymap('n', '<A-j>', ':move +1<CR>')
utils.keymap('n', '<A-k>', ':move -2<CR>')
utils.keymap('n', '<A-m>', 'M')
utils.keymap('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w') -- Split line
utils.keymap('n', '<A-u>', 'mzg~iw`z', {noremap = false}) -- Upper case inner word
utils.keymap('n', '<Leader>mr', 'q') -- Macro recording
utils.keymap('n', '<tab>', '%',  {noremap = false})
utils.keymap('n', 'H', '^')
utils.keymap('n', 'L', '$')
utils.keymap('n', 'M', [[:execute 'normal! ' . (virtcol('$')/2) . '\|'<CR>]], {silent = false, noremap = false})
utils.keymap('n', 'j', 'gj')
utils.keymap('n', 'k', 'gk')
utils.keymap('n', 'q', '<nop>')
utils.keymap('n', 'vv', '^vg_', {noremap = false}) -- Visual selection excluding indentation

-- Yanking and pasting
utils.keymap('n', '<Leader>P', ':put!<CR>')
-- utils.keymap('n', '<Leader>p', ':put<CR>')
utils.keymap('n', 'Y', 'y$',  {noremap = false})
utils.keymap('n', 'yy', 'mz0y$`z',  {noremap = false})

-- Search and jumps
utils.keymap('n', '/', '/\\v', {silent = false, noremap = false})
utils.keymap('n', '?', '?\\v', {silent = false, noremap = false})
utils.keymap('n', '<C-y>', '<C-i>') -- Jump to newer entry in jumplist
utils.keymap('n', '<Leader><Space>', ':set hlsearch!<CR>')
utils.keymap('n', '<Leader>qr', ':cdo %s/', {silent = false})
utils.keymap('n', '<Leader>sr', ':%s/', {silent = false})
utils.keymap('n', 'n', 'nzzzv', {noremap = false})
utils.keymap('n', 'N', 'Nzzzv', {noremap = false})

-- Bookmarks
utils.keymap('n', '<Leader>ev', ':e $MYVIMRC<CR>')

-- Misc commands
utils.keymap('n', '<Leader>ic', ':set list!<CR>')
utils.keymap('n', '<Leader>sa', ':sort i<CR>')
utils.keymap('n', '<Leader>sc', ':set spell!<CR>')

-- Insert mode
utils.keymap('i', '<A-b>', '<C-o>b')
utils.keymap('i', '<A-f>', '<C-o>w')
utils.keymap('i', '<A-p>', '<C-R>"')
utils.keymap('i', '<A-x>', '<C-W>')
utils.keymap('i', '<C-a>', '<C-o>^')
utils.keymap('i', '<C-h>', '<C-o>h')
utils.keymap('i', '<C-l>', '<C-o>l')
utils.keymap('i', '<down>', '<nop>')
utils.keymap('i', '<left>', '<nop>')
utils.keymap('i', '<right>', '<nop>')
utils.keymap('i', '<up>', '<nop>')

-- Visual mode
utils.keymap('v', '/', '/\\v', {silent = false, noremap = false})
utils.keymap('v', '?', '?\\v', {silent = false, noremap = false})
utils.keymap('v', '<', '<gv')
utils.keymap('v', '>', '>gv')
utils.keymap('v', '<A-j>', ":m '>+1<CR>gv=gv")
utils.keymap('v', '<A-k>', ":m '<-2<CR>gv=gv")
utils.keymap('v', '<ESC>', '"+ygv<C-c>') -- mimicks autoselect
utils.keymap('v', '<Leader>sa', ':sort i<CR>')
utils.keymap('v', 'G', 'G$')
utils.keymap('v', 'H', '^')
utils.keymap('v', 'L', 'g_')
utils.keymap('v', 'Q', 'gq')

-- Command mode
utils.keymap('c', '<A-b>', '<S-Left>', {silent = false})
utils.keymap('c', '<A-f>', '<S-Right>', {silent = false})
utils.keymap('c', '<A-p>', '<C-R>"', {silent = false})
utils.keymap('c', '<A-x>', '<C-W>', {silent = false})
utils.keymap('c', '<C-a>', '<home>', {silent = false})
utils.keymap('c', '<C-e>', '<end>', {silent = false})
utils.keymap('c', '<C-h>', '<left>', {silent = false})
utils.keymap('c', '<C-l>', '<right>', {silent = false})
utils.keymap('c', '<C-x>', '<C-U>', {silent = false})

-- Terminal mode
utils.keymap('t', '<C-A-n>', '<C-\\><C-n>:bn<CR>')
utils.keymap('t', '<C-A-p>', '<C-\\><C-n>:bp<CR>')
utils.keymap('t', '<C-h>', '<C-\\><C-n><C-w>h')
utils.keymap('t', '<C-j>', '<C-\\><C-n><C-w>j')
utils.keymap('t', '<C-k>', '<C-\\><C-n><C-w>k')
utils.keymap('t', '<C-l>', '<C-\\><C-n><C-w>l')
utils.keymap('t', 'kj', '<C-\\><C-n>')
