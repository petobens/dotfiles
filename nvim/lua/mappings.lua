local u = require('utils')

-- Save
u.keymap('n', '<Leader>kv', '<Cmd>qall<CR>')
u.keymap('n', '<Leader>nw', '<Cmd>noautocmd w!<CR>')
u.keymap('n', '<Leader>ps', function()
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
u.keymap('n', '<Leader>w', '<Cmd>w!<CR>')
u.keymap('n', '<Leader>wc', '<Cmd>w!<CR><Cmd>silent! close<CR>')
u.keymap('n', '<Leader>wq', '<Cmd>w!<CR><Cmd>q!<CR>')
u.keymap('n', '<Leader>ws', '<Cmd>SudaWrite<CR>')
u.keymap('n', '<Leader>rs', ':SudaRead ', { silent = false })

-- Buffer manipulation
u.keymap('n', '<C-n>', '<Cmd>bn<CR>')
u.keymap('n', '<C-p>', '<Cmd>bp<CR>')
u.keymap('n', '<Leader>bd', '<Cmd>bp|bd #<CR>')
u.keymap('n', '<Leader>cd', '<Cmd>lcd %:h<CR>')
u.keymap('n', '<Leader>rr', '<Cmd>checktime<CR>')
u.keymap('n', '<Leader>so', '<Cmd>update<CR>:luafile %<CR>', { silent = false })
u.keymap('n', '<Leader>wd', '<Cmd>bd<CR>')
u.keymap('n', 'gf', function()
    local wincmd = 'wincmd f'
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        wincmd = 'vertical ' .. wincmd
    end
    vim.cmd(wincmd)
end)

-- Window manipulation
u.keymap('n', '<A-o>', '<C-W>ozv')
u.keymap('n', '<C-A-h>', '<C-W>2<')
u.keymap('n', '<C-A-j>', '<C-W>2+')
u.keymap('n', '<C-A-k>', '<C-W>2-')
u.keymap('n', '<C-A-l>', '<C-W>2>')
u.keymap('n', '<C-c>', '<C-W>c')
local ok, tmux_plugin = pcall(require, 'tmux')
if ok then
    u.keymap('n', '<C-h>', tmux_plugin.move_left)
    u.keymap('n', '<C-j>', tmux_plugin.move_down)
    u.keymap('n', '<C-k>', tmux_plugin.move_up)
    u.keymap('n', '<C-l>', tmux_plugin.move_right)
end
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
u.keymap('n', 'q', function()
    if vim.api.nvim_win_get_config(0).zindex then
        if require('neo-zoom').is_neo_zoom_float() then
            vim.cmd('NeoZoomToggle')
        else
            vim.cmd('close')
        end
    end
end)
u.keymap('n', 'Q', 'gwap')
u.keymap('n', 'vv', '^vg_', { remap = true }) -- Visual selection excluding indentation
u.keymap('n', '<Leader>C', ':let &scrolloff=999-&scrolloff<CR>') -- always center
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
u.keymap('n', '<Leader>P', '<Cmd>put!<CR>')
u.keymap('n', '<Leader>p', '<Cmd>put<CR>', { nowait = false })
u.keymap('n', 'gp', '`[v`]') -- visually reselect what was just pasted
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
u.keymap(
    'n',
    '*',
    [[:let @/ = '\v' . expand('<cword>')<bar>set hlsearch<CR>]],
    { remap = true }
) -- don't jump to first match with * and #
u.keymap('n', '#', '#``', { remap = true })
u.keymap('n', '<Leader>sw', '/<><Left>', { silent = false, remap = true })
u.keymap('n', '[m', '[mzz')
u.keymap('n', ']m', ']mzz')

-- Folds
u.keymap('n', '<Leader>zf', 'zMzvzz') -- zoom/fold focus
u.keymap('n', 'l', function()
    -- Open fold from start
    local foldstart_linenr = vim.fn.foldclosed('.')
    if foldstart_linenr == -1 then
        vim.cmd('normal! l')
        return
    end
    vim.cmd('normal! zo')
    vim.cmd('normal! ' .. foldstart_linenr .. 'G^')
end)
u.keymap('n', 'zm', 'zM')
u.keymap('n', 'zr', 'zR')
u.keymap('n', '<Leader>mf', '<Cmd>set foldmethod=marker<CR>zv')

-- Diffs
u.keymap('n', '<Leader>de', '<Cmd>bd #<CR>zz')
u.keymap('n', '<Leader>ds', function()
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
u.keymap('n', '<Leader>du', '<Cmd>diffupdate<CR>')

-- Misc
u.keymap('n', '<Leader>ic', '<Cmd>set list!<CR>')
u.keymap('n', '<Leader>sa', '<Cmd>sort i<CR>')
u.keymap('n', '<Leader>sc', '<Cmd>set spell!<CR>')
u.keymap('n', '<Leader>lp', ':lua vim.print(', { silent = false })
u.keymap('n', '<Leader>lr', ':=', { silent = false })
u.keymap('n', '<Leader>cg', '<Cmd>Inspect<CR>')

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
    '<Cmd>e ' .. vim.env.HOME .. '/OneDrive/mutt/todos_mutt.md<CR>'
)
u.keymap(
    'n',
    '<Leader>ets',
    '<Cmd>e ' .. vim.env.HOME .. '/OneDrive/varios/todos_coding_setup.md<CR>'
)
u.keymap(
    'n',
    '<Leader>dd',
    ':e ' .. vim.fn.expand('$HOME') .. '/Desktop/',
    { silent = false }
)
u.keymap('n', '<Leader>sb', function()
    vim.api.nvim_input(':e ' .. vim.fn.expand('%:p:h') .. '/scratch/')
end, { silent = false })
u.keymap('n', '<Leader>eb', '<Cmd>e $HOME/.bashrc<CR>')
u.keymap(
    'n',
    '<Leader>eh',
    -- FIXME: defining the symlink here doesn't preserve make/load view
    '<Cmd>e $HOME/git-repos/private/dotfiles/arch/config/i3/config<CR>'
)

-- Links & Filemanager
u.keymap({ 'n', 'v' }, '<Leader>ol', function()
    local url
    local mode = vim.api.nvim_get_mode()['mode']
    if mode == 'v' then
        url = u.get_selection()
    else
        url = vim.fn.matchstr(
            vim.fn.getline('.'),
            [[\(http\|www\.\)[^ ]:\?[[:alnum:]%\/_#.-]*]]
        )
    end
    url = vim.fn.escape(url, '#!?&;|%')
    vim.cmd('silent! !xdg-open ' .. url)
    vim.cmd('redraw!')
end)
u.keymap('n', '<Leader>fm', function()
    vim.cmd('silent! !tmux split-window -p 30 -c ' .. vim.fn.getcwd() .. ' ranger')
end)
for i = 1, 6 do
    u.keymap('n', '<Leader>h' .. i, function()
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
u.keymap('v', '*', '*<C-o>')

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

-- Select mode (mostly for snippets)
u.keymap('s', 'L', 'L')
u.keymap('s', 'H', 'H')
u.keymap('s', 'M', 'M')
