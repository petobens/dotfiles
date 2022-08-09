local u = require('utils')

-- Save
u.keymap('n', '<Leader>kv', '<Cmd>qall<CR>')
u.keymap('n', '<Leader>nw', '<Cmd>noautocmd w!<CR>')
u.keymap('n', '<Leader>ps', '<Cmd>silent! source ' .. udfs.session_name() .. '<CR>')
u.keymap('n', '<Leader>w', '<Cmd>w!<CR>')
u.keymap('n', '<Leader>wc', '<Cmd>w!<CR><Cmd>silent! close<CR>')
u.keymap('n', '<Leader>wq', '<Cmd>w!<CR><Cmd>q!<CR>')
u.keymap('n', '<Leader>sw', '<Cmd>SudaWrite<CR><Cmd>q!<CR>')
u.keymap('n', '<Leader>se', '<Cmd>SudaRead<CR><Cmd>q!<CR>')

-- Buffer manipulation
u.keymap('n', '<C-n>', '<Cmd>bn<CR>')
u.keymap('n', '<C-p>', '<Cmd>bp<CR>')
u.keymap('n', '<Leader>bd', '<Cmd>bp|bd #<CR>')
u.keymap('n', '<Leader>cd', '<Cmd>lcd %:h<CR>')
u.keymap('n', '<Leader>rr', '<Cmd>checktime<CR>')
u.keymap('n', '<Leader>so', '<Cmd>update<CR>:luafile %<CR>', { silent = false })
u.keymap('n', '<Leader>wd', '<Cmd>bd<CR>')
u.keymap('n', 'gf', udfs.goto_file_insplit)

-- Window manipulation
u.keymap('n', '<A-o>', '<C-W>ozv')
u.keymap('n', '<C-A-h>', '<C-W>2<')
u.keymap('n', '<C-A-j>', '<C-W>2+')
u.keymap('n', '<C-A-k>', '<C-W>2-')
u.keymap('n', '<C-A-l>', '<C-W>2>')
u.keymap('n', '<C-c>', '<C-W>c')
u.keymap('n', '<C-h>', require('tmux').move_left)
u.keymap('n', '<C-j>', require('tmux').move_down)
u.keymap('n', '<C-k>', require('tmux').move_up)
u.keymap('n', '<C-l>', require('tmux').move_right)
u.keymap('n', '<C-x>', '<C-W>xzz')
u.keymap('n', '<Leader>hv', '<C-W>H<C-W>x') -- make horizantal vertical and viceversa
u.keymap('n', '<Leader>vh', '<C-W>K')
u.keymap('n', '<Leader>pu', '<Cmd>wincmd J<bar>15 wincmd _<CR>') -- Resize win as popup
u.keymap('n', '<Leader>sp', '<Cmd>split<CR>')
u.keymap('n', '<Leader>vs', '<Cmd>vsplit<CR>')

-- Line edit/movement
u.keymap({ 'n', 'i', 'v' }, '<down>', '<nop>')
u.keymap({ 'n', 'i', 'v' }, '<left>', '<nop>')
u.keymap({ 'n', 'i', 'v' }, '<right>', '<nop>')
u.keymap({ 'n', 'i', 'v' }, '<up>', '<nop>')
u.keymap({ 'n', 'v' }, '+', '<C-a>')
u.keymap({ 'n', 'v' }, '-', '<C-x>')
u.keymap('n', '<A-0>', 'H')
u.keymap('n', '<A-b>', 'L')
u.keymap('n', '<A-j>', '<Cmd>execute "move+" . v:count1<CR><Cmd>silent! normal! zO==<CR>')
u.keymap(
    'n',
    '<A-k>',
    '<Cmd>execute "move--" . v:count1<CR><Cmd>silent! normal! zO==<CR>'
)
u.keymap('n', '<A-m>', 'M')
u.keymap('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w') -- Split line
u.keymap('n', '<A-u>', 'mzg~iw`z', { remap = true }) -- Upper case inner word
u.keymap('n', '<Leader>mr', 'q') -- Macro recording
u.keymap({ 'n', 'v' }, 'H', '^')
u.keymap('n', 'L', '$')
u.keymap('n', 'M', [[<cmd>execute 'normal! ' . (virtcol('$')/2) . '<bar>'<CR>]])
u.keymap('n', 'j', 'gj')
u.keymap('n', 'k', 'gk')
u.keymap('n', 'J', 'mzJ`z') -- Keep the cursor in place while joining lines
u.keymap('n', 'q', '<nop>')
u.keymap('n', 'Q', 'gwap')
u.keymap('n', 'vv', '^vg_', { remap = true }) -- Visual selection excluding indentation
-- FIXME: https://github.com/neovim/neovim/issues/12544 we cannot use vim.go.scrolloff here
u.keymap('n', '<Leader>C', ':let &scrolloff=999-&scrolloff<CR>')
-- TODO: add mapping to swap words

-- Yank and paste
u.keymap('n', '<Leader>P', '<Cmd>put!<CR>')
u.keymap('n', '<Leader>p', '<Cmd>put<CR>', { nowait = false })
-- FIXME: not working
u.keymap('n', 'gp', '`[' .. vim.fn.strpart(vim.fn.getregtype(), 0, 1) .. '`]') -- Visually reselect what was just pasted
u.keymap('n', 'Y', 'y$', { remap = true })
u.keymap('n', 'yy', 'mz0y$`z', { remap = true })

-- Search, jumps and marks
u.keymap({ 'n', 'v' }, '/', '/\\v', { silent = false, remap = true })
u.keymap({ 'n', 'v' }, '?', '?\\v', { silent = false, remap = true })
u.keymap('n', '<C-o>', '<C-o>zvzz')
u.keymap('n', '<C-y>', '<C-i>zvzz') -- Jump to newer entry in jumplist
u.keymap('n', '<Leader><Space>', '<Cmd>nohlsearch<CR><Cmd>call clearmatches()<CR>')
u.keymap('n', '<Leader>qr', ':cdo %s/', { silent = false })
u.keymap('n', '<Leader>sr', ':%s/', { silent = false })
u.keymap('n', 'n', 'nzzzv') -- keep matches window in the middle (while opening folds)
u.keymap('n', 'N', 'Nzzzv')
u.keymap('n', "'", '`', { remap = true })
u.keymap('n', '<Leader>dm', '<Cmd>delmarks!<CR><Cmd>delmarks A-Z0-9<CR>')
u.keymap({ 'n', 'v', 'o' }, '<tab>', '%', { remap = true })
u.keymap(
    'n',
    '*',
    [[:let @/ = '\v' . expand('<cword>')<bar>set hlsearch<CR>]],
    { remap = true }
) -- don't jump to first match with * and #
u.keymap('n', '#', '#``', { remap = true })
u.keymap('n', '<Leader>ws', '/<><Left>', { silent = false, remap = true })

-- Folds
u.keymap('n', '<Leader>z', 'zMzvzz')
u.keymap('n', 'l', udfs.open_fold_from_start)
u.keymap('n', 'zm', 'zM')
u.keymap('n', 'zr', 'zR')
u.keymap('n', '<Leader>mf', '<Cmd>set foldmethod=marker<CR>zv')

-- Diffs
u.keymap('n', '<Leader>de', '<Cmd>diffoff!<CR>')
u.keymap('n', '<Leader>ds', udfs.diff_file_split)
u.keymap('n', '<Leader>du', '<Cmd>diffupdate<CR>')

-- Misc
u.keymap('n', '<Leader>ic', '<Cmd>set list!<CR>')
u.keymap('n', '<Leader>sa', '<Cmd>sort i<CR>')
u.keymap('n', '<Leader>sc', '<Cmd>set spell!<CR>')
u.keymap('n', '<Leader>lp', ':lua put(', { silent = false })

-- Bookmarks
u.keymap('n', '<Leader>ev', '<Cmd>e $MYVIMRC<CR>')
u.keymap('n', '<Leader>em', '<Cmd>e ' .. vim.env.DOTVIM .. '/minimal.lua<CR>')
u.keymap(
    'n',
    '<Leader>ew',
    '<Cmd>e ' .. vim.env.DOTVIM .. '/spell/custom-dictionary.utf-8.add<CR>'
)
u.keymap(
    'n',
    '<Leader>etm',
    '<Cmd>e ' .. vim.env.HOME .. '/OneDrive/varios/todos_mutt.md<CR>'
)
u.keymap(
    'n',
    '<Leader>ets',
    '<Cmd>e ' .. vim.env.HOME .. '/OneDrive/varios/todos_coding_setup.md<CR>'
)
u.keymap('n', '<Leader>dd', ':e $HOME/Desktop/', { silent = false })
u.keymap(
    'n',
    '<Leader>sb',
    ':e  ' .. vim.fn.expand('%:p:h') .. '/scratch/',
    { silent = false }
)
u.keymap('n', '<Leader>eb', '<Cmd>e $HOME/.bashrc<CR>')
u.keymap('n', '<Leader>eh', '<Cmd>e $HOME/.config/i3/config<CR>')

-- UDFs
u.keymap('n', '<Leader>dt', udfs.delete_trailing_whitespace)
u.keymap('n', '<Leader>ol', function()
    udfs.open_links('n')
end)
u.keymap('v', '<Leader>ol', function()
    udfs.open_links('v')
end)
u.keymap('n', '<Leader>fm', function()
    udfs.tmux_split_cmd('ranger')
end)
for i = 1, 6 do
    u.keymap('n', '<Leader>h' .. i, function()
        udfs.highlight_word(i)
    end)
end

-- Quickfix, Location & Preview windows
u.keymap('n', '<Leader>qf', '<Cmd>copen<CR>')
u.keymap('n', '<Leader>ll', '<Cmd>lopen<CR>')
u.keymap('n', '<Leader>qc', '<Cmd>cclose<CR>')
u.keymap('n', '<Leader>lc', '<Cmd>lclose<CR>')
u.keymap('n', '<Leader>lC', function()
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd('noautocmd windo if &buftype == "quickfix" | lclose | endif')
    vim.api.nvim_set_current_win(win_id)
end)
u.keymap('n', ']q', '<Cmd>execute v:count1 . "cnext"<CR>')
u.keymap('n', '[q', '<Cmd>execute v:count1 . "cprevious"<CR>')
u.keymap('n', ']Q', '<Cmd>clast<CR>')
u.keymap('n', '[Q', '<Cmd>cfirst<CR>')
u.keymap('n', ']l', '<Cmd>execute v:count1 . "lnext"<CR>')
u.keymap('n', '[l', '<Cmd>execute v:count1 . "lprevious"<CR>')
u.keymap('n', ']L', '<Cmd>llast<CR>')
u.keymap('n', '[L', '<Cmd>lfirst<CR>')
u.keymap('n', '<Leader>pc', '<Cmd>pclose<CR>')

-- Insert mode specific
u.keymap('i', 'jj', '<ESC>')
u.keymap('i', '<A-b>', '<C-o>b')
u.keymap('i', '<A-f>', '<C-o>w')
u.keymap('i', '<A-p>', '<C-R>"')
u.keymap('i', '<A-x>', '<C-W>')
u.keymap('i', '<C-a>', '<C-o>^')
u.keymap('i', '<C-e>', 'pumvisible() ? "<C-e>" : "<C-o>$"', { expr = true })
u.keymap('i', '<C-h>', '<C-o>h')
u.keymap('i', '<C-l>', '<C-o>l')

-- Visual mode specific
u.keymap('v', '<', '<gv')
u.keymap('v', '>', '>gv')
u.keymap('v', '<A-j>', ":m '>+1<CR>gv=gv")
u.keymap('v', '<A-k>', ":m '<-2<CR>gv=gv")
u.keymap('v', '<ESC>', '"+ygv<C-c>') -- mimicks autoselect
u.keymap('v', '<Leader>sa', ':sort i<CR>')
u.keymap('v', '<Leader>sr', ':s/', { silent = false })
u.keymap('v', 'G', 'G$')
u.keymap('v', 'L', 'g_')
u.keymap('v', 'M', [[<Cmd>execute 'normal! gv ' . (virtcol('$')/2) . '<bar>'<CR>]])
u.keymap('v', 'Q', 'gq')
u.keymap('v', '.', ':normal .<CR>')
u.keymap('x', '*', 'mz:<C-U>call v:lua.udfs.visual_search("/")<CR>/<C-R>=@/<CR><CR>`z')
u.keymap('x', '#', 'mz:<C-U>call v:lua.udfs.visual_search("?")<CR>?<C-R>=@/<CR><CR>`z')

-- Command mode specific
u.keymap('n', ';', ':', { silent = false })
u.keymap('c', '<A-b>', '<S-Left>', { silent = false })
u.keymap('c', '<A-f>', '<S-Right>', { silent = false })
u.keymap('c', '<A-p>', '<C-R>"', { silent = false })
u.keymap('c', '<A-x>', '<C-W>', { silent = false })
u.keymap('c', '<C-a>', '<home>', { silent = false })
u.keymap('c', '<C-e>', '<end>', { silent = false })
u.keymap('c', '<C-h>', '<left>', { silent = false })
u.keymap('c', '<C-l>', '<right>', { silent = false })
u.keymap('c', '<C-x>', '<C-U>', { silent = false })
u.keymap(
    'c',
    '%%',
    "getcmdtype() == ':' ? expand('%:p:h') . '/' : '%%'",
    { silent = false, expr = true }
)

-- Terminal mode specific
u.keymap('t', '<C-A-n>', '<C-\\><C-n>:bn<CR>')
u.keymap('t', '<C-A-p>', '<C-\\><C-n>:bp<CR>')
u.keymap('t', '<C-h>', '<C-\\><C-n><C-W>h')
u.keymap('t', '<C-j>', '<C-\\><C-n><C-W>j')
u.keymap('t', '<C-k>', '<C-\\><C-n><C-W>k')
u.keymap('t', '<C-l>', '<C-\\><C-n><C-W>l')
u.keymap('t', '<C-[>', '<C-\\><C-n>:normal! 0<CR>:call search(" ", "b")<CR>')
u.keymap('t', 'kj', '<C-\\><C-n>')
