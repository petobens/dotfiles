-- luacheck:ignore 631
local u = require('utils')

-- Save
vim.keymap.set('n', '<Leader>kv', '<Cmd>qall<CR>')
vim.keymap.set('n', '<Leader>rv', '<Cmd>restart<CR>')
vim.keymap.set('n', '<Leader>nw', '<Cmd>noautocmd w!<CR>')
vim.keymap.set('n', '<Leader>ps', function()
    vim.cmd.source({ args = { u.vim_session_file() }, mods = { silent = true } })
    -- Remove any buffer that exists and is listed but doesn't have a valid filename
    -- See https://github.com/neovim/neovim/pull/17112#issuecomment-1024923302
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_get_option(b, 'buflisted')
            and vim.bo[b].buftype ~= 'quickfix'
        then
            if vim.uv.fs_stat(vim.api.nvim_buf_get_name(b)) == nil then
                vim.cmd.bwipeout({ args = { tostring(b) } })
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
vim.keymap.set('n', '<Leader>cd', function()
    vim.api.nvim_set_current_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
end)
vim.keymap.set('n', '<Leader>rr', '<Cmd>checktime<CR>')
vim.keymap.set('n', '<Leader>so', '<Cmd>update<CR>:luafile %<CR>', { silent = false })
vim.keymap.set('n', '<Leader>wd', '<Cmd>bd<CR>')
vim.keymap.set('n', 'gf', function()
    local wincmd = 'wincmd f'
    if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
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

-- Yank and paste
vim.keymap.set('n', '<Leader>P', '<Cmd>put!<CR>')
vim.keymap.set('n', '<Leader>p', '<Cmd>put<CR>', { nowait = false })
vim.keymap.set('n', 'gp', '`[v`]') -- visually reselect what was just pasted
vim.keymap.set('n', 'Y', 'y$', { remap = true })
vim.keymap.set('n', 'yy', 'mz0y$`z', { remap = true })
vim.keymap.set('n', '<Leader>yd', function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    vim.fn.setreg('+', dir)
    vim.fn.setreg('*', dir)
    vim.notify(('Yanked directory: %s'):format(dir), vim.log.levels.INFO)
end)
vim.keymap.set('n', '<Leader>yf', function()
    local path = vim.api.nvim_buf_get_name(0)
    vim.fn.setreg('+', path)
    vim.fn.setreg('*', path)
    vim.notify(('Yanked file: %s'):format(path), vim.log.levels.INFO)
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
    local save_pwd = vim.uv.cwd()
    vim.cmd.lcd({ args = { vim.fs.dirname(vim.api.nvim_buf_get_name(0)) } })
    local win_id = vim.api.nvim_get_current_win()
    vim.ui.input(
        { prompt = 'Input file for diffing: ', completion = 'file' },
        function(other_file)
            if not other_file or other_file == '' then
                return
            else
                local diff_cmd = 'diffsplit '
                if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
                    diff_cmd = 'vertical ' .. diff_cmd
                end
                vim.cmd(diff_cmd .. other_file)
            end
            vim.api.nvim_set_current_win(win_id)
            vim.cmd.normal({ args = { 'gg]h' } }) -- move to first hunk
        end
    )
    vim.api.nvim_set_current_dir(save_pwd)
end)
vim.keymap.set('n', '<Leader>du', '<Cmd>diffupdate<CR>')

-- Misc
vim.keymap.set('n', '<Leader>mg', '<Cmd>messages<CR>')
vim.keymap.set('n', '<Leader>mm', 'g<', { remap = true })
vim.keymap.set('n', '<Leader>ic', '<Cmd>set list!<CR>')
vim.keymap.set('n', '<Leader>sa', '<Cmd>sort i<CR>')
vim.keymap.set('n', '<Leader>sc', '<Cmd>set spell!<CR>')
vim.keymap.set('n', '<Leader>lp', ':lua vim.print(', { silent = false })
vim.keymap.set('n', '<Leader>lr', ':=', { silent = false })
vim.keymap.set('n', '<Leader>ci', '<Cmd>Inspect<CR>')
vim.keymap.set('n', '<Leader>cw', function()
    vim.print(('Words: %d'):format(vim.fn.wordcount().words))
end)

-- Commenting
vim.keymap.set('n', '<Leader>cc', 'gcc', { remap = true })
vim.keymap.set('n', '<Leader>cu', 'gcc', { remap = true })
vim.keymap.set('v', '<Leader>cc', 'gc', { remap = true })
vim.keymap.set('v', '<Leader>cu', 'gc', { remap = true })

-- Bookmarks
vim.keymap.set('n', '<Leader>ev', '<Cmd>e $MYVIMRC<CR>')
vim.keymap.set(
    'n',
    '<Leader>em',
    ('<Cmd>e %s<CR>'):format(vim.fs.joinpath(vim.env.DOTVIM, 'minimal.lua'))
)
vim.keymap.set(
    'n',
    '<Leader>ew',
    ('<Cmd>e %s/spell/custom-dictionary.utf-8.add<CR>'):format(vim.env.DOTVIM)
)
vim.keymap.set(
    'n',
    '<Leader>etm',
    ('<Cmd>e %s/git-repos/private/notes/mutt/todos_mutt.md<CR>'):format(vim.env.HOME)
)
vim.keymap.set(
    'n',
    '<Leader>ets',
    ('<Cmd>e %s/git-repos/private/notes/programming/todos_coding_setup.md<CR>'):format(
        vim.env.HOME
    )
)
vim.keymap.set(
    'n',
    '<Leader>dd',
    (':e %s'):format(vim.fs.joinpath(vim.env.HOME, 'Desktop/')),
    { silent = false }
)
vim.keymap.set('n', '<Leader>sb', function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    vim.api.nvim_input((':e %s/scratch/'):format(dir))
end, { silent = false })
vim.keymap.set('n', '<Leader>eb', ('<Cmd>e %s/.bashrc<CR>'):format(vim.env.HOME))
vim.keymap.set(
    'n',
    '<Leader>eh',
    -- Note: using a symlink here doesn't preserve make/load view
    ('<Cmd>e %s/git-repos/private/dotfiles/arch/config/i3/config<CR>'):format(
        vim.env.HOME
    )
)

-- Links & Filemanager
vim.keymap.set({ 'n', 'v' }, '<Leader>ol', 'gx', { remap = true })
vim.keymap.set('n', '<Leader>fm', function()
    vim.system({ 'tmux', 'split-window', '-l', '20', '-c', vim.uv.cwd(), 'ranger' })
end)
for i = 1, 6 do
    vim.keymap.set('n', '<Leader>h' .. i, function()
        vim.cmd.normal({ args = { 'mz' }, bang = true })
        vim.cmd.normal({ args = { '"zyiw' }, bang = true })
        local mid = 86750 + i -- arbitrary match id
        vim.cmd.matchdelete({ args = { tostring(mid) }, mods = { silent = true } })
        local pat = '\\V\\<' .. vim.fn.escape(vim.fn.getreg('z'), '\\') .. '\\>'
        vim.fn.matchadd('HlWord' .. i, pat, 1, mid)
        vim.cmd.normal({ args = { '`z' }, bang = true })
    end)
end

-- Quickfix, Location & Preview windows
vim.keymap.set('n', '<Leader>qf', '<Cmd>copen<CR>')
vim.keymap.set('n', '<Leader>ll', '<Cmd>lopen<CR>')
vim.keymap.set('n', '<Leader>qc', '<Cmd>cclose<CR>')
vim.keymap.set('n', '<Leader>lc', '<Cmd>lclose<CR>')
vim.keymap.set('n', '<Leader>lC', function()
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd.windo({
        args = { 'if &buftype == "quickfix" | lclose | endif' },
        mods = { noautocmd = true },
    })
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
vim.keymap.set('c', '%%', function()
    if vim.fn.getcmdtype() == ':' then
        return vim.fs.dirname(vim.api.nvim_buf_get_name(0)) .. '/'
    else
        return '%%'
    end
end, { expr = true, silent = false })

-- Terminal mode specific
vim.keymap.set('t', '<C-A-n>', '<C-\\><C-n>:bn<CR>')
vim.keymap.set('t', '<C-A-p>', '<C-\\><C-n>:bp<CR>')
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-W>h')
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-W>j')
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-W>k')
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-W>l')
vim.keymap.set('t', '<C-[>', function()
    vim.cmd.normal({ args = { '0' }, bang = true })
    vim.fn.search(' ', 'b')
end)
vim.keymap.set('t', 'kj', '<C-\\><C-n>')

-- Select mode (mostly for snippets)
vim.keymap.set('s', 'L', 'L')
vim.keymap.set('s', 'H', 'H')
vim.keymap.set('s', 'M', 'M')
