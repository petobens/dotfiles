local u = require('utils')

-- Save
u.keymap('n', '<Leader>kv', ':qall<CR>')
u.keymap('n', '<Leader>nw', ':noautocmd w!<CR>')
u.keymap('n', '<Leader>ps', ':silent! source ' .. udfs.session_name() .. '<CR>')
u.keymap('n', '<Leader>w', ':w!<CR>')
u.keymap('n', '<Leader>wc', ':w!<CR>:silent close<CR>')
u.keymap('n', '<Leader>wq', ':w!<CR>:q!<CR>')

-- Buffer manipulation
u.keymap('n', '<C-n>', ':bn<CR>')
u.keymap('n', '<C-p>', ':bp<CR>')
u.keymap('n', '<Leader>bd', ':bp|bd #<CR>')
u.keymap('n', '<Leader>cd', ':lcd %:h<CR>')
u.keymap('n', '<Leader>dd', ':e $HOME/Desktop/', {silent = false})
u.keymap('n', '<Leader>rr', ':checktime<CR>')
u.keymap('n', '<Leader>so', ':update<CR>:luafile %<CR>', {silent = false})
u.keymap('n', '<Leader>wd', ':bd<CR>')

-- Window manipulation
u.keymap('n', '<A-o>', '<C-W>ozv')
u.keymap('n', '<C-A-h>', '<C-W>2<')
u.keymap('n', '<C-A-j>', '<C-W>2+')
u.keymap('n', '<C-A-k>', '<C-W>2-')
u.keymap('n', '<C-A-l>', '<C-W>2>')
u.keymap('n', '<C-c>', '<C-W>c')
u.keymap('n', '<C-h>', [[<cmd>lua require('tmux').move_left()<CR>]])
u.keymap('n', '<C-j>', [[<cmd>lua require('tmux').move_down()<CR>]])
u.keymap('n', '<C-k>', [[<cmd>lua require('tmux').move_up()<CR>]])
u.keymap('n', '<C-l>', [[<cmd>lua require('tmux').move_right()<CR>]])
u.keymap('n', '<C-x>', '<C-W>xzz')
u.keymap('n', '<Leader>sp', ':split<CR>')
u.keymap('n', '<Leader>vs', ':vsplit<CR>')

-- Line edit/movement
-- FIXME: virtcol not working
u.keymap('n', '<down>', '<nop>')
u.keymap('n', '<left>', '<nop>')
u.keymap('n', '<right>', '<nop>')
u.keymap('n', '<up>', '<nop>')
u.keymap('n', '+', '<C-a>')
u.keymap('n', '-', '<C-x>')
u.keymap('n', '<A-0>', 'H')
u.keymap('n', '<A-b>', 'L')
u.keymap('n', '<A-m>', 'M')
u.keymap('n', '<A-j>', ':move +1<CR>')
u.keymap('n', '<A-k>', ':move -2<CR>')
u.keymap('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w') -- Split line
u.keymap('n', '<A-u>', 'mzg~iw`z', {noremap = false}) -- Upper case inner word
u.keymap('n', '<Leader>mr', 'q') -- Macro recording
u.keymap('n', 'H', '^')
u.keymap('n', 'L', '$')
u.keymap('n', 'M', [[:execute 'normal! ' . (virtcol('$')/2) . '\|'<CR>]], {silent = false, noremap = false})
u.keymap('n', 'j', 'gj')
u.keymap('n', 'k', 'gk')
u.keymap('n', 'q', '<nop>')
u.keymap('n', 'vv', '^vg_', {noremap = false}) -- Visual selection excluding indentation

-- Yank and paste
u.keymap('n', '<Leader>P', ':put!<CR>')
u.keymap('n', '<Leader>p', ':put<CR>', {nowait = false})
u.keymap('n', 'Y', 'y$',  {noremap = false})
u.keymap('n', 'yy', 'mz0y$`z',  {noremap = false})

-- Search, jumps and marks
u.keymap('n', '/', '/\\v', {silent = false, noremap = false})
u.keymap('n', '?', '?\\v', {silent = false, noremap = false})
u.keymap('n', '<C-o>', '<C-o>zvzz')
u.keymap('n', '<C-y>', '<C-i>') -- Jump to newer entry in jumplist
u.keymap('n', '<Leader><Space>', ':nohlsearch<CR>:call clearmatches()<CR>')
u.keymap('n', '<Leader>qr', ':cdo %s/', {silent = false})
u.keymap('n', '<Leader>sr', ':%s/', {silent = false})
u.keymap('n', 'n', 'nzzzv') -- keep matches window middle (opening folds)
u.keymap('n', 'N', 'Nzzzv')
u.keymap('n', "'", '`',  {noremap = false})
u.keymap('n', '<Leader>dm', ':delmarks!<CR>:delmarks A-Z0-9<CR>')
u.keymap('n', '<tab>', '%',  {noremap = false})

-- Folding
u.keymap('n', '<Leader>z', 'zMzvzz')
u.keymap('n', 'zm', 'zM')
u.keymap('n', 'zr', 'zR')
u.keymap('n', '<Leader>mf', ':set foldmethod=marker<CR>zv')

-- Bookmarks
u.keymap('n', '<Leader>ev', ':e $MYVIMRC<CR>')

-- Misc commands
u.keymap('n', '<Leader>ic', ':set list!<CR>')
u.keymap('n', '<Leader>sa', ':sort i<CR>')
u.keymap('n', '<Leader>sc', ':set spell!<CR>')

-- Insert mode
u.keymap('i', 'jj', '<ESC>')
u.keymap('i', '<down>', '<nop>')
u.keymap('i', '<left>', '<nop>')
u.keymap('i', '<right>', '<nop>')
u.keymap('i', '<up>', '<nop>')
u.keymap('i', '<A-b>', '<C-o>b')
u.keymap('i', '<A-f>', '<C-o>w')
u.keymap('i', '<A-p>', '<C-R>"')
u.keymap('i', '<A-x>', '<C-W>')
u.keymap('i', '<C-a>', '<C-o>^')
u.keymap('i', '<C-h>', '<C-o>h')
u.keymap('i', '<C-l>', '<C-o>l')

-- Visual mode
u.keymap('v', '<down>', '<nop>')
u.keymap('v', '<left>', '<nop>')
u.keymap('v', '<right>', '<nop>')
u.keymap('v', '<up>', '<nop>')
u.keymap('v', '/', '/\\v', {silent = false, noremap = false})
u.keymap('v', '?', '?\\v', {silent = false, noremap = false})
u.keymap('v', '<', '<gv')
u.keymap('v', '>', '>gv')
u.keymap('v', '<A-j>', ":m '>+1<CR>gv=gv")
u.keymap('v', '<A-k>', ":m '<-2<CR>gv=gv")
u.keymap('v', '<ESC>', '"+ygv<C-c>') -- mimicks autoselect
u.keymap('v', '<Leader>sa', ':sort i<CR>')
u.keymap('v', 'G', 'G$')
u.keymap('v', 'H', '^')
u.keymap('v', 'L', 'g_')
u.keymap('v', 'Q', 'gq')

-- Command mode
u.keymap('n', ';', ':', {silent = false})
u.keymap('c', '<A-b>', '<S-Left>', {silent = false})
u.keymap('c', '<A-f>', '<S-Right>', {silent = false})
u.keymap('c', '<A-p>', '<C-R>"', {silent = false})
u.keymap('c', '<A-x>', '<C-W>', {silent = false})
u.keymap('c', '<C-a>', '<home>', {silent = false})
u.keymap('c', '<C-e>', '<end>', {silent = false})
u.keymap('c', '<C-h>', '<left>', {silent = false})
u.keymap('c', '<C-l>', '<right>', {silent = false})
u.keymap('c', '<C-x>', '<C-U>', {silent = false})

-- Terminal mode
u.keymap('t', '<C-A-n>', '<C-\\><C-n>:bn<CR>')
u.keymap('t', '<C-A-p>', '<C-\\><C-n>:bp<CR>')
u.keymap('t', '<C-h>', '<C-\\><C-n><C-w>h')
u.keymap('t', '<C-j>', '<C-\\><C-n><C-w>j')
u.keymap('t', '<C-k>', '<C-\\><C-n><C-w>k')
u.keymap('t', '<C-l>', '<C-\\><C-n><C-w>l')
u.keymap('t', 'kj', '<C-\\><C-n>')


-- Commented
-- u.keymap('n', '<Leader>cu', 'v:lua.require("commented").commented()', {expr = true})
vim.api.nvim_set_keymap('n', '<Leader>xx', "v:lua.require'commented'.commented()", {
				expr = true,
				silent = true,
				noremap = true,
			})
