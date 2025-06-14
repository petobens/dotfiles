-- luacheck:ignore 631
local u = require('utils')

-- Save
vim.keymap.set('n', '<Leader>kv', '<Cmd>qall<CR>')
vim.keymap.set('n', '<Leader>rv', '<Cmd>restart<CR>')
vim.keymap.set('n', '<Leader>nw', '<Cmd>noautocmd w!<CR>')
vim.keymap.set('n', '<Leader>ps', function()
    vim.cmd('silent! source ' .. u.vim_session_file())
    -- Remove any buffer that exists and is listed but doesn't have a valid filename
    -- See https://github.com/neovim/neovim/pull/17112#issuecomment-1024923302
    for b = 1, vim.fn.bufnr('$') do
        if vim.fn.buflisted(b) ~= 0 and vim.bo[b].buftype ~= 'quickfix' then
            if vim.fn.filereadable(vim.api.nvim_buf_get_name(b)) == 0 then
                vim.cmd('bwipeout ' .. b)
            end
        end
    end
end)
vim.keymap.set('n', '<Leader>w', '<Cmd>w!<CR>')
vim.keymap.set('n', '<Leader>wc', '<Cmd>w!<CR><Cmd>silent! close<CR>')
vim.keymap.set('n', '<Leader>wq', '<Cmd>w!<CR><Cmd>q!<CR>')
vim.keymap.set('n', '<Leader>ws', '<Cmd>SudaWrite<CR>')
vim.keymap.set('n', '<Leader>rs', ':SudaRead ', { silent = false })

-- Buffer manipulation
vim.keymap.set('n', '<C-n>', '<Cmd>bn<CR>')
vim.keymap.set('n', '<C-p>', '<Cmd>bp<CR>')
vim.keymap.set('n', '<Leader>bd', '<Cmd>bp|bd #<CR>')
vim.keymap.set('n', '<Leader>cd', '<Cmd>lcd %:h<CR>')
vim.keymap.set('n', '<Leader>rr', '<Cmd>checktime<CR>')
vim.keymap.set('n', '<Leader>so', '<Cmd>update<CR>:luafile %<CR>', { silent = false })
vim.keymap.set('n', '<Leader>wd', '<Cmd>bd<CR>')
vim.keymap.set('n', 'gf', function()
    local wincmd = 'wincmd f'
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        wincmd = 'vertical ' .. wincmd
    end
    vim.cmd(wincmd)
end)

-- Window manipulation
vim.keymap.set('n', '<A-o>', '<C-W>ozv')
vim.keymap.set('n', '<C-A-h>', '<C-W>2<')
vim.keymap.set('n', '<C-A-j>', '<C-W>2+')
vim.keymap.set('n', '<C-A-k>', '<C-W>2-')
vim.keymap.set('n', '<C-A-l>', '<C-W>2>')
vim.keymap.set('n', '<C-c>', '<C-W>c')
vim.keymap.set('n', '<C-x>', '<C-W>xzz')
vim.keymap.set('n', '<Leader>hv', '<C-W>H<C-W>x') -- make horizantal vertical and viceversa
vim.keymap.set('n', '<Leader>vh', '<C-W>K')
vim.keymap.set('n', '<Leader>pu', '<Cmd>wincmd J<bar>15 wincmd _<CR>') -- Resize win as popup
vim.keymap.set('n', '<Leader>sp', '<Cmd>split<CR>')
vim.keymap.set('n', '<Leader>vs', '<Cmd>vsplit<CR>')

-- Line edit/movement
vim.keymap.set({ 'n', 'i', 'v' }, '<down>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<left>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<right>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<up>', '<nop>')
vim.keymap.set({ 'n', 'v' }, '+', '<C-a>')
vim.keymap.set({ 'n', 'v' }, '-', '<C-x>')
vim.keymap.set('n', '<A-0>', 'H')
vim.keymap.set('n', '<A-b>', 'L')
vim.keymap.set(
    'n',
    '<A-j>',
    '<Cmd>execute "move+" . v:count1<CR><Cmd>silent! normal! zO<CR>'
)
vim.keymap.set(
    'n',
    '<A-k>',
    '<Cmd>execute "move--" . v:count1<CR><Cmd>silent! normal! zO<CR>'
)
vim.keymap.set('n', '<A-m>', 'M')
vim.keymap.set('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w') -- Split line
vim.keymap.set('n', '<A-u>', 'mzg~iw`z', { remap = true }) -- Upper case inner word
vim.keymap.set('n', '<Leader>mr', 'q') -- Macro recording
vim.keymap.set({ 'n', 'v' }, 'H', '^')
vim.keymap.set('n', 'L', '$')
vim.keymap.set('n', 'M', [[<cmd>execute 'normal! ' . (virtcol('$')/2) . '<bar>'<CR>]])
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', 'J', 'mzJ`z') -- Keep the cursor in place while joining lines
vim.keymap.set('n', '<Leader>oj', ']<Space>j', { remap = true })
vim.keymap.set('n', '<Leader>ok', '[<Space>k', { remap = true })
vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_get_config(0).zindex then
        vim.cmd('close')
    end
end)
vim.keymap.set('n', 'Q', 'gwap')
vim.keymap.set('n', 'vv', '^vg_', { remap = true }) -- Visual selection excluding indentation
vim.keymap.set('n', '<Leader>C', ':let &scrolloff=999-&scrolloff<CR>') -- always center
-- TODO: Try to write the following mappings to swap words in lua
vim.cmd([[
nnoremap <silent> <A-h> :execute "silent normal! ms"<CR>
            \"_yiw?\k\+\%(\k\@!\_.\)\+\%#<CR>
            \:s/\(\%#\k\+\)\(\%(\k\@!\_.\)\+\)\(\k\+\)/\3\2\1/<CR><c-l>:noh<CR>
            \:execute "silent normal! `s"<CR>
nnoremap <silent> <A-l> :execute "silent normal! ms"<CR>
            \"_yiw:s/\(\%#\k\+\)\(\%(\k\@!\_.\)\+\)\(\k\+\)/\3\2\1/
            \<CR>/\k\+\%(\k\@!\_.\)\+<CR><c-l>:noh<CR>
            \:execute "silent normal! `s"<CR>
]])

-- Yank and paste
vim.keymap.set('n', '<Leader>P', '<Cmd>put!<CR>')
vim.keymap.set('n', '<Leader>p', '<Cmd>put<CR>', { nowait = false })
vim.keymap.set('n', 'gp', '`[v`]') -- visually reselect what was just pasted
vim.keymap.set('n', 'Y', 'y$', { remap = true })
vim.keymap.set('n', 'yy', 'mz0y$`z', { remap = true })
vim.keymap.set('n', '<Leader>yd', function()
    local dir = vim.fn.expand('%:p:h')
    vim.fn.setreg('+', dir)
    vim.fn.setreg('*', dir)
    vim.notify('Yanked directory: ' .. dir)
end)
vim.keymap.set('n', '<Leader>yf', function()
    local path = vim.fn.expand('%:p')
    vim.fn.setreg('+', path)
    vim.fn.setreg('*', path)
    vim.notify('Yanked file: ' .. path)
end)

-- Search, jumps and marks
vim.keymap.set({ 'n', 'v' }, '/', '/\\v', { silent = false, remap = true })
vim.keymap.set({ 'n', 'v' }, '?', '?\\v', { silent = false, remap = true })
vim.keymap.set('n', '<C-o>', '<C-o>zvzz')
vim.keymap.set('n', '<C-y>', '<C-i>zvzz') -- Jump to newer entry in jumplist
vim.keymap.set('n', '<Leader><Space>', '<Cmd>nohlsearch<CR><Cmd>call clearmatches()<CR>')
vim.keymap.set('n', '<Leader>qr', ':cdo %s/', { silent = false })
vim.keymap.set('n', '<Leader>sr', ':%s/', { silent = false })
vim.keymap.set('n', 'n', 'nzzzv') -- keep matches window in the middle (while opening folds)
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', "'", '`', { remap = true })
vim.keymap.set('n', '<Leader>dm', '<Cmd>delmarks!<CR><Cmd>delmarks A-Z0-9<CR>')
vim.keymap.set(
    'n',
    '*',
    [[:let @/ = '\v' . expand('<cword>')<bar>set hlsearch<CR>]],
    { remap = true }
) -- don't jump to first match with * and #
vim.keymap.set('n', '#', '#``', { remap = true })
vim.keymap.set('n', '<Leader>sw', '/<><Left>', { silent = false, remap = true })
vim.keymap.set('n', '[m', '[mzz')
vim.keymap.set('n', ']m', ']mzz')

-- Folds
vim.keymap.set('n', '<Leader>zf', 'zMzvzz') -- zoom/fold focus
vim.keymap.set('n', 'l', function()
    -- Open fold from start
    local foldstart_linenr = vim.fn.foldclosed('.')
    if foldstart_linenr == -1 then
        vim.cmd('normal! l')
        return
    end
    vim.cmd('normal! zo')
    vim.cmd('normal! ' .. foldstart_linenr .. 'G^')
end)
vim.keymap.set('n', 'zm', 'zM')
vim.keymap.set('n', 'zr', 'zR')
vim.keymap.set('n', '<Leader>mf', '<Cmd>set foldmethod=marker<CR>zv')

-- Diffs
vim.keymap.set('n', '<Leader>de', '<Cmd>bd #<CR>zz')
vim.keymap.set('n', '<Leader>ds', function()
    local save_pwd = vim.fn.getcwd()
    vim.cmd('lcd %:p:h')
    local win_id = vim.fn.win_getid()
    vim.ui.input(
        { prompt = 'Input file for diffing: ', completion = 'file' },
        function(other_file)
            if not other_file or other_file == '' then
                return
            else
                local diff_cmd = 'diffsplit '
                if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
                    diff_cmd = 'vertical ' .. diff_cmd
                end
                vim.cmd(diff_cmd .. other_file)
            end
            vim.fn.win_gotoid(win_id)
            vim.cmd('normal gg]h') -- move to first hunk
        end
    )
    vim.cmd('lcd ' .. save_pwd)
end)
vim.keymap.set('n', '<Leader>du', '<Cmd>diffupdate<CR>')

-- Misc
vim.keymap.set('n', '<Leader>mg', '<Cmd>messages<CR>')
vim.keymap.set('n', '<Leader>mp', 'g<', { remap = true })
vim.keymap.set('n', '<Leader>ic', '<Cmd>set list!<CR>')
vim.keymap.set('n', '<Leader>sa', '<Cmd>sort i<CR>')
vim.keymap.set('n', '<Leader>sc', '<Cmd>set spell!<CR>')
vim.keymap.set('n', '<Leader>lp', ':lua vim.print(', { silent = false })
vim.keymap.set('n', '<Leader>lr', ':=', { silent = false })
vim.keymap.set('n', '<Leader>ci', function()
    vim.cmd('Inspect')
    vim.cmd('normal! g<')
end)
vim.keymap.set(
    'n',
    '<Leader>cw',
    ':lua vim.print("Words: " .. vim.fn.wordcount().words)<CR>'
)

-- Commenting
vim.keymap.set('n', '<Leader>cc', 'gcc', { remap = true })
vim.keymap.set('n', '<Leader>cu', 'gcc', { remap = true })
vim.keymap.set('v', '<Leader>cc', 'gc', { remap = true })
vim.keymap.set('v', '<Leader>cu', 'gc', { remap = true })

-- Bookmarks
vim.keymap.set('n', '<Leader>ev', '<Cmd>e $MYVIMRC<CR>')
vim.keymap.set('n', '<Leader>em', '<Cmd>e ' .. vim.env.DOTVIM .. '/minimal.lua<CR>')
vim.keymap.set(
    'n',
    '<Leader>ew',
    '<Cmd>e ' .. vim.env.DOTVIM .. '/spell/custom-dictionary.utf-8.add<CR>'
)
vim.keymap.set(
    'n',
    '<Leader>etm',
    '<Cmd>e ' .. vim.env.HOME .. '/git-repos/private/notes/mutt/todos_mutt.md<CR>'
)
vim.keymap.set(
    'n',
    '<Leader>ets',
    '<Cmd>e '
        .. vim.env.HOME
        .. '/git-repos/private/notes/programming/todos_coding_setup.md<CR>'
)
vim.keymap.set(
    'n',
    '<Leader>dd',
    ':e ' .. vim.fn.expand('$HOME') .. '/Desktop/',
    { silent = false }
)
vim.keymap.set('n', '<Leader>sb', function()
    vim.api.nvim_input(':e ' .. vim.fn.expand('%:p:h') .. '/scratch/')
end, { silent = false })
vim.keymap.set('n', '<Leader>eb', '<Cmd>e $HOME/.bashrc<CR>')
vim.keymap.set(
    'n',
    '<Leader>eh',
    -- FIXME: defining the symlink here doesn't preserve make/load view
    '<Cmd>e $HOME/git-repos/private/dotfiles/arch/config/i3/config<CR>'
)

-- Links & Filemanager
vim.keymap.set({ 'n', 'v' }, '<Leader>ol', 'gx', { remap = true })
vim.keymap.set('n', '<Leader>fm', function()
    vim.cmd('silent! !tmux split-window -l 20 -c ' .. vim.fn.getcwd() .. ' ranger')
end)
for i = 1, 6 do
    vim.keymap.set('n', '<Leader>h' .. i, function()
        vim.cmd('normal! mz')
        vim.cmd('normal! "zyiw')
        local mid = 86750 + i -- arbitrary match id
        vim.cmd('silent! call matchdelete(' .. mid .. ')')
        local pat = '\\V\\<' .. vim.fn.escape(vim.fn.getreg('z'), '\\') .. '\\>'
        vim.fn.matchadd('HlWord' .. i, pat, 1, mid)
        vim.cmd('normal! `z')
    end)
end

-- Quickfix, Location & Preview windows
vim.keymap.set('n', '<Leader>qf', '<Cmd>copen<CR>')
vim.keymap.set('n', '<Leader>ll', '<Cmd>lopen<CR>')
vim.keymap.set('n', '<Leader>qc', '<Cmd>cclose<CR>')
vim.keymap.set('n', '<Leader>lc', '<Cmd>lclose<CR>')
vim.keymap.set('n', '<Leader>lC', function()
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd('noautocmd windo if &buftype == "quickfix" | lclose | endif')
    vim.api.nvim_set_current_win(win_id)
end)
vim.keymap.set('n', ']q', '<Cmd>execute v:count1 . "cnext"<CR>')
vim.keymap.set('n', '[q', '<Cmd>execute v:count1 . "cprevious"<CR>')
vim.keymap.set('n', ']Q', '<Cmd>clast<CR>')
vim.keymap.set('n', '[Q', '<Cmd>cfirst<CR>')
vim.keymap.set('n', ']l', '<Cmd>execute v:count1 . "lnext"<CR>')
vim.keymap.set('n', '[l', '<Cmd>execute v:count1 . "lprevious"<CR>')
vim.keymap.set('n', ']L', '<Cmd>llast<CR>')
vim.keymap.set('n', '[L', '<Cmd>lfirst<CR>')
vim.keymap.set('n', '<Leader>pc', '<Cmd>pclose<CR>')

-- Insert mode specific
vim.keymap.set('i', 'jj', '<ESC>')
vim.keymap.set('i', '<A-b>', '<C-o>b')
vim.keymap.set('i', '<A-f>', '<C-o>w')
vim.keymap.set('i', '<A-p>', '<C-R>"')
vim.keymap.set('i', '<A-x>', '<C-W>')
vim.keymap.set('i', '<C-a>', '<C-o>^')
vim.keymap.set('i', '<C-e>', 'pumvisible() ? "<C-e>" : "<C-o>$"', { expr = true })
vim.keymap.set('i', '<C-h>', '<C-o>h')
vim.keymap.set('i', '<C-l>', '<C-o>l')

-- Visual mode specific
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv")
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv")
vim.keymap.set('v', '<ESC>', '"+ygv<C-c>') -- mimicks autoselect
vim.keymap.set('v', '<Leader>sa', ':sort i<CR>')
vim.keymap.set('v', '<Leader>sr', ':s/', { silent = false })
vim.keymap.set('v', 'G', 'G$')
vim.keymap.set('v', 'L', 'g_')
vim.keymap.set('v', 'M', [[<Cmd>execute 'normal! gv ' . (virtcol('$')/2) . '<bar>'<CR>]])
vim.keymap.set('v', 'Q', 'gq')
vim.keymap.set('v', '.', ':normal .<CR>')
vim.keymap.set('v', '*', '*<C-o>')

-- Command mode specific
vim.keymap.set('n', ';', ':', { silent = false })
vim.keymap.set('c', '<A-b>', '<S-Left>', { silent = false })
vim.keymap.set('c', '<A-f>', '<S-Right>', { silent = false })
vim.keymap.set('c', '<A-p>', '<C-R>"', { silent = false })
vim.keymap.set('c', '<A-x>', '<C-W>', { silent = false })
vim.keymap.set('c', '<C-a>', '<home>', { silent = false })
vim.keymap.set('c', '<C-e>', '<end>', { silent = false })
vim.keymap.set('c', '<C-h>', '<left>', { silent = false })
vim.keymap.set('c', '<C-l>', '<right>', { silent = false })
vim.keymap.set('c', '<C-x>', '<C-U>', { silent = false })
vim.keymap.set(
    'c',
    '%%',
    "getcmdtype() == ':' ? expand('%:p:h') . '/' : '%%'",
    { silent = false, expr = true }
)

-- Terminal mode specific
vim.keymap.set('t', '<C-A-n>', '<C-\\><C-n>:bn<CR>')
vim.keymap.set('t', '<C-A-p>', '<C-\\><C-n>:bp<CR>')
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-W>h')
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-W>j')
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-W>k')
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-W>l')
vim.keymap.set('t', '<C-[>', '<C-\\><C-n>:normal! 0<CR>:call search(" ", "b")<CR>')
vim.keymap.set('t', 'kj', '<C-\\><C-n>')

-- Select mode (mostly for snippets)
vim.keymap.set('s', 'L', 'L')
vim.keymap.set('s', 'H', 'H')
vim.keymap.set('s', 'M', 'M')
