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
u.keymap('n', '<Leader>rr', ':checktime<CR>')
u.keymap('n', '<Leader>so', ':update<CR>:luafile %<CR>', {silent = false})
u.keymap('n', '<Leader>wd', ':bd<CR>')
u.keymap('n', 'gf', ':call v:lua.udfs.goto_file_insplit()<CR>')

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
u.keymap('n', '<Leader>hv', '<C-W>H<C-W>x') -- make horizantal vertical and viceversa
u.keymap('n', '<Leader>vh', '<C-W>K')
u.keymap('n', '<Leader>pu', ':wincmd J<bar>15 wincmd _<CR>')  -- Resize win as popup
u.keymap('n', '<Leader>sp', ':split<CR>')
u.keymap('n', '<Leader>vs', ':vsplit<CR>')

-- Line edit/movement
u.keymap('n', '<down>', '<nop>')
u.keymap('n', '<left>', '<nop>')
u.keymap('n', '<right>', '<nop>')
u.keymap('n', '<up>', '<nop>')
u.keymap('n', '+', '<C-a>')
u.keymap('n', '-', '<C-x>')
u.keymap('n', '<A-0>', 'H')
u.keymap('n', '<A-b>', 'L')
-- FIXME: not quite working (neither count not indentation)
u.keymap('n', '<A-j>', ':execute "move+" . v:count1<CR>zO==')
u.keymap('n', '<A-k>', ':execute "move--" . v:count1<CR>zO==')
u.keymap('n', '<A-m>', 'M')
u.keymap('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w') -- Split line
u.keymap('n', '<A-u>', 'mzg~iw`z', {noremap = false}) -- Upper case inner word
u.keymap('n', '<Leader>mr', 'q') -- Macro recording
u.keymap('n', 'H', '^')
u.keymap('n', 'L', '$')
u.keymap('n', 'M', [[<cmd>execute 'normal! ' . (virtcol('$')/2) . '<bar>'<CR>]])
u.keymap('n', 'j', 'gj')
u.keymap('n', 'k', 'gk')
u.keymap('n', 'J', 'mzJ`z')  -- Keep the cursor in place while joining lines
u.keymap('n', 'q', '<nop>')
u.keymap('n', 'Q', 'gwap')
u.keymap('n', 'vv', '^vg_', {noremap = false}) -- Visual selection excluding indentation
-- FIXME: https://github.com/neovim/neovim/issues/12544 we cannot use vim.go.scrolloff here
u.keymap('n', '<Leader>C', ':let &scrolloff=999-&scrolloff<CR>')

-- Yank and paste
u.keymap('n', '<Leader>P', ':put!<CR>')
u.keymap('n', '<Leader>p', ':put<CR>', {nowait = false})
u.keymap('n', 'gp', '`[' .. vim.fn.strpart(vim.fn.getregtype(), 0, 1) .. '`]') -- Visually reselect what was just pasted
u.keymap('n', 'Y', 'y$',  {noremap = false})
u.keymap('n', 'yy', 'mz0y$`z',  {noremap = false})

-- Search, jumps and marks
u.keymap('n', '/', '/\\v', {silent = false, noremap = false})
u.keymap('n', '?', '?\\v', {silent = false, noremap = false})
u.keymap('n', '<C-o>', '<C-o>zvzz')
u.keymap('n', '<C-y>', '<C-i>zvzz') -- Jump to newer entry in jumplist
u.keymap('n', '<Leader><Space>', ':nohlsearch<CR>:call clearmatches()<CR>')
u.keymap('n', '<Leader>qr', ':cdo %s/', {silent = false})
u.keymap('n', '<Leader>sr', ':%s/', {silent = false})
u.keymap('n', 'n', 'nzzzv') -- keep matches window in the middle (while opening folds)
u.keymap('n', 'N', 'Nzzzv')
u.keymap('n', "'", '`',  {noremap = false})
u.keymap('n', '<Leader>dm', ':delmarks!<CR>:delmarks A-Z0-9<CR>')
u.keymap('n', '<tab>', '%',  {noremap = false})
u.keymap('n', '*', [[:let @/ = '\<' . expand('<cword>') . '\>'<bar>set hlsearch<CR>]], {noremap = false}) -- don't jump to first match with * and #
u.keymap('n', '#', '#``', {noremap = false})

-- Folds
u.keymap('n', '<Leader>z', 'zMzvzz')
u.keymap('n', 'zm', 'zM')
u.keymap('n', 'zr', 'zR')
u.keymap('n', '<Leader>mf', ':set foldmethod=marker<CR>zv')

-- Diffs
u.keymap('n', '<Leader>de', ':diffoff!<CR>')
u.keymap('n', '<Leader>ds', ':call v:lua.udfs.diff_file_split()<CR>')
u.keymap('n', '<Leader>du', ':diffupdate<CR>')
u.keymap('n', '[h', "&diff ? '[c' : '[h'", {expr = true})
u.keymap('n', ']h', "&diff ? ']c' : ']h'", {expr = true})

-- Bookmarks
u.keymap('n', '<Leader>ev', ':e $MYVIMRC<CR>')
u.keymap('n', '<Leader>ew', ':e ' .. vim.env.DOTVIM .. '/spell/custom-dictionary.utf-8.add<CR>')
u.keymap('n', '<Leader>etm', ':e ' .. vim.env.HOME .. '/OneDrive/varios/todos_mutt.md<CR>')
u.keymap('n', '<Leader>ets', ':e ' .. vim.env.HOME .. '/OneDrive/varios/todos_coding_setup.md<CR>')
u.keymap('n', '<Leader>dd', ':e $HOME/Desktop/', {silent = false})
u.keymap('n', '<Leader>sb', ':e  ' .. vim.fn.expand('%:p:h') .. '/scratch/', {silent = false})

-- Misc
u.keymap('n', '<Leader>dt', ':call v:lua.udfs.delete_trailing_whitespace()<CR>')
u.keymap('n', '<Leader>ol', ':call v:lua.udfs.open_links("n")<CR>')
u.keymap('v', '<Leader>ol', ':call v:lua.udfs.open_links("v")<CR>')
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
u.keymap('i', '<C-e>', 'pumvisible() ? "<C-e>" : "<C-o>$"', {expr = true})
u.keymap('i', '<C-h>', '<C-o>h')
u.keymap('i', '<C-l>', '<C-o>l')

-- Visual mode
u.keymap('v', '<down>', '<nop>')
u.keymap('v', '<left>', '<nop>')
u.keymap('v', '<right>', '<nop>')
u.keymap('v', '<up>', '<nop>')
u.keymap('v', '+', '<C-a>')
u.keymap('v', '-', '<C-x>')
u.keymap('v', '/', '/\\v', {silent = false, noremap = false})
u.keymap('v', '?', '?\\v', {silent = false, noremap = false})
u.keymap('v', '<', '<gv')
u.keymap('v', '>', '>gv')
u.keymap('v', '<A-j>', ":m '>+1<CR>gv=gv")
u.keymap('v', '<A-k>', ":m '<-2<CR>gv=gv")
u.keymap('v', '<ESC>', '"+ygv<C-c>') -- mimicks autoselect
u.keymap('v', '<Leader>sa', ':sort i<CR>')
u.keymap('v', '<Leader>sr', ':%s/', {silent = false})
u.keymap('v', 'G', 'G$')
u.keymap('v', 'H', '^')
u.keymap('v', 'L', 'g_')
u.keymap('v', 'M', [[<cmd>execute 'normal! gv ' . (virtcol('$')/2) . '<bar>'<CR>]])
u.keymap('v', 'Q', 'gq')
u.keymap('v', '.', ':normal .<CR>')
u.keymap('x', '*', ':<C-U>call v:lua.udfs.visual_search("/")<CR>', {silent = false})

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
u.keymap('c', '%%', "getcmdtype() == ':' ? expand('%:p:h') . '/' : '%%'", {silent = false, expr = true})

-- Terminal mode
u.keymap('t', '<C-A-n>', '<C-\\><C-n>:bn<CR>')
u.keymap('t', '<C-A-p>', '<C-\\><C-n>:bp<CR>')
u.keymap('t', '<C-h>', '<C-\\><C-n><C-W>h')
u.keymap('t', '<C-j>', '<C-\\><C-n><C-W>j')
u.keymap('t', '<C-k>', '<C-\\><C-n><C-W>k')
u.keymap('t', '<C-l>', '<C-\\><C-n><C-W>l')
u.keymap('t', '<C-[>', '<C-\\><C-n>:normal! 0<CR>:call search(" ", "b")<CR>')
u.keymap('t', 'kj', '<C-\\><C-n>')

-- Commented plugin
-- TODO: move this to its own file
u.keymap('n', '<Leader>cu', 'v:lua.require("commented").commented_line()', {expr = true})
u.keymap('v', '<Leader>cu', 'v:lua.require("commented").commented()', {expr = true})
