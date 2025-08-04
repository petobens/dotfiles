-- luacheck:ignore 631
local u = require('utils')

-- Save and quit
vim.keymap.set('n', '<Leader>w', function()
    vim.cmd.write({ bang = true })
end)
vim.keymap.set('n', '<Leader>nw', function()
    vim.cmd.write({ bang = true, mods = { noautocmd = true } })
end)
vim.keymap.set('n', '<Leader>wc', function()
    vim.cmd.write({ bang = true })
    vim.cmd.close({ mods = { silent = true } })
end)
vim.keymap.set('n', '<Leader>wq', function()
    vim.cmd.write({ bang = true })
    vim.cmd.quit({ bang = true })
end)
vim.keymap.set('n', '<Leader>rr', vim.cmd.checktime)
vim.keymap.set('n', '<Leader>so', function()
    vim.cmd.update()
    vim.cmd.luafile('%')
end, { silent = false })
vim.keymap.set('n', '<Leader>ws', vim.cmd.SudaWrite)
vim.keymap.set('n', '<Leader>rs', ':SudaRead ', { silent = false })

-- Sessions
vim.keymap.set('n', '<Leader>kv', vim.cmd.qall)
vim.api.nvim_create_user_command('RestoreSession', function()
    vim.cmd.source({ args = { u.vim_session_file() }, mods = { silent = true } })
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_get_option(b, 'buflisted')
            and vim.bo[b].buftype ~= 'quickfix'
        then
            if vim.uv.fs_stat(vim.api.nvim_buf_get_name(b)) == nil then
                vim.cmd.bwipeout(tostring(b))
            end
        end
    end
end, {})
vim.keymap.set('n', '<Leader>ps', vim.cmd.RestoreSession)
vim.keymap.set('n', '<Leader>rv', function()
    vim.cmd.restart({ args = { '+qall!', 'RestoreSession' } })
end)

-- Buffer manipulation
vim.keymap.set('n', '<C-n>', vim.cmd.bnext)
vim.keymap.set('n', '<C-p>', vim.cmd.bprevious)
vim.keymap.set('n', '<Leader>bd', function()
    vim.cmd.bprevious()
    vim.cmd.bdelete('#')
end)
vim.keymap.set('n', '<Leader>wd', vim.cmd.bdelete)
vim.keymap.set('n', '<Leader>cd', function()
    vim.api.nvim_set_current_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
end)
vim.keymap.set('n', 'gf', function()
    local mods
    if vim.api.nvim_win_get_width(0) > 160 then
        mods = { vertical = true }
    end
    vim.cmd.wincmd({ args = { 'f' }, mods = mods })
end)

-- Window manipulation
-- TODO: Resize to center
vim.keymap.set('n', '<C-A-h>', function()
    vim.cmd.wincmd('2<')
end)
vim.keymap.set('n', '<C-A-l>', function()
    vim.cmd.wincmd('2>')
end)
vim.keymap.set('n', '<C-A-j>', function()
    vim.cmd.wincmd('2+')
end)
vim.keymap.set('n', '<C-A-k>', function()
    vim.cmd.wincmd('2-')
end)
vim.keymap.set('n', '<C-c>', vim.cmd.close)
vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_get_config(0).zindex then
        vim.cmd.close()
    end
end)
vim.keymap.set('n', '<A-o>', function()
    vim.cmd.only()
    vim.cmd.normal('zv')
end)
vim.keymap.set('n', '<Leader>sp', vim.cmd.split)
vim.keymap.set('n', '<Leader>vs', vim.cmd.vsplit)
vim.keymap.set('n', '<C-x>', function()
    vim.cmd.wincmd('x')
    vim.cmd.normal('zz')
end)
vim.keymap.set('n', '<Leader>hv', function()
    -- make horizantal vertical and viceversa
    vim.cmd.wincmd('H')
    vim.cmd.wincmd('x')
end)
vim.keymap.set('n', '<Leader>vh', function()
    vim.cmd.wincmd('K')
end)

-- Line edit/movement
vim.keymap.set({ 'n', 'i', 'v' }, '<down>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<left>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<right>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<up>', '<nop>')
vim.keymap.set('n', '<A-0>', 'H')
vim.keymap.set('n', '<A-b>', 'L')
vim.keymap.set('n', '<A-m>', 'M')
vim.keymap.set('n', '<A-j>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd.move(tostring(line + vim.v.count1))
    pcall(function()
        vim.cmd.normal({ args = { 'zO' }, bang = true, mods = { silent = true } })
    end)
end)
vim.keymap.set('n', '<A-k>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd.move(tostring(line - vim.v.count1 - 1))
    pcall(function()
        vim.cmd.normal({ args = { 'zO' }, bang = true, mods = { silent = true } })
    end)
end)
vim.keymap.set('n', '<A-s>', 'i<CR><ESC>^mwgk:silent! s/\v +$//<CR>:noh<CR>`w') -- Split line
vim.keymap.set('n', 'J', 'mzJ`z') -- Keep the cursor in place while joining lines
vim.keymap.set({ 'n', 'v' }, 'H', '^')
vim.keymap.set('n', 'L', '$')
vim.keymap.set('n', 'M', function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local middle = math.floor(vim.fn.virtcol('$') / 2)
    vim.api.nvim_win_set_cursor(0, { row, middle - 1 })
end)
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '<Leader>oj', ']<Space>j', { remap = true })
vim.keymap.set('n', '<Leader>ok', '[<Space>k', { remap = true })
vim.keymap.set('n', 'Q', 'gwap')
vim.keymap.set('n', '<A-u>', 'mzg~iw`z', { remap = true }) -- Upper case inner word
vim.keymap.set({ 'n', 'v' }, '+', '<C-a>')
vim.keymap.set({ 'n', 'v' }, '-', '<C-x>')

-- Yank and paste
vim.keymap.set('n', '<Leader>pp', vim.cmd.put)
vim.keymap.set('n', '<Leader>P', function()
    vim.cmd.put({ bang = true })
end)
vim.keymap.set('n', 'Y', 'y$', { remap = true })
vim.keymap.set('n', 'yy', 'mz0y$`z', { remap = true })
vim.keymap.set('n', 'gp', '`[v`]') -- visually reselect what was just pasted
vim.keymap.set('n', 'vv', '^vg_', { remap = true }) -- visually select excluding indentation
vim.keymap.set('n', '<Leader>yf', function()
    local path = vim.api.nvim_buf_get_name(0)
    vim.fn.setreg('+', path)
    vim.fn.setreg('*', path)
    vim.notify(('Yanked file: %s'):format(path), vim.log.levels.INFO)
end)
vim.keymap.set('n', '<Leader>yd', function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    vim.fn.setreg('+', dir)
    vim.fn.setreg('*', dir)
    vim.notify(('Yanked directory: %s'):format(dir), vim.log.levels.INFO)
end)

-- Search, jumps and marks
vim.keymap.set({ 'n', 'v' }, '/', '/\\v', { silent = false, remap = true })
vim.keymap.set({ 'n', 'v' }, '?', '?\\v', { silent = false, remap = true })
vim.keymap.set('n', '<Leader><Space>', function()
    vim.cmd.nohlsearch()
    vim.fn.clearmatches()
end)
vim.keymap.set('n', 'n', 'nzzzv') -- keep matches window in the middle (while opening folds)
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '*', function()
    -- Don't jump to first match with *
    local word = vim.fn.expand('<cword>')
    vim.fn.setreg('/', '\\v' .. word)
    vim.o.hlsearch = true
end, { remap = true })
vim.keymap.set('n', '#', '#``', { remap = true })
vim.keymap.set('n', '<Leader>sw', '/<><Left>', { silent = false, remap = true })
vim.keymap.set('n', '<C-o>', '<C-o>zvzz')
vim.keymap.set('n', '<C-y>', '<C-i>zvzz') -- jump to newer entry in jumplist
vim.keymap.set('n', '<Leader>qr', function()
    vim.api.nvim_input(':cdo %s/')
end)
vim.keymap.set('n', '<Leader>sr', function()
    vim.api.nvim_input(':%s/')
end)
vim.keymap.set('n', "'", '`', { remap = true })
vim.keymap.set('n', '<Leader>dm', function()
    vim.cmd.delmarks({ bang = true })
    vim.cmd.delmarks('A-Z0-9')
end)
vim.keymap.set('n', '[m', '[mzz')
vim.keymap.set('n', ']m', ']mzz')

-- Folds
vim.keymap.set('n', 'zm', 'zM')
vim.keymap.set('n', 'zr', 'zR')
vim.keymap.set('n', '<Leader>mf', function()
    vim.opt.foldmethod = 'marker'
    vim.cmd.normal('zv')
end)
vim.keymap.set('n', '<Leader>zf', 'zMzvzz') -- zoom/fold focus
vim.keymap.set('n', 'l', function()
    -- Open fold from start
    local foldstart_linenr = vim.fn.foldclosed('.')
    if foldstart_linenr == -1 then
        vim.cmd.normal({ args = { 'l' }, bang = true })
        return
    end
    vim.cmd.normal({ args = { 'zo' }, bang = true })
    vim.api.nvim_win_set_cursor(0, { foldstart_linenr, 0 })
end)

-- Diffs
vim.keymap.set('n', '<Leader>ds', function()
    local save_pwd = vim.uv.cwd()
    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
    local win_id = vim.api.nvim_get_current_win()
    vim.ui.input(
        { prompt = 'Input file for diffing: ', completion = 'file' },
        function(other_file)
            if not other_file or other_file == '' then
                return
            else
                local mods
                if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
                    mods = { vertical = true }
                end
                vim.cmd.diffsplit({ args = { other_file }, mods = mods })
            end
            vim.api.nvim_set_current_win(win_id)
            vim.cmd.normal('gg]h') -- move to first hunk
        end
    )
    vim.api.nvim_set_current_dir(save_pwd)
end)
vim.keymap.set('n', '<Leader>de', function()
    vim.cmd.bdelete('#')
    vim.cmd.normal('zz')
end)
vim.keymap.set('n', '<Leader>du', vim.cmd.diffupdate)

-- Misc
vim.keymap.set('n', '<Leader>C', function()
    vim.o.scrolloff = 999 - vim.o.scrolloff
end)
vim.keymap.set('n', '<Leader>mr', 'q') -- Macro recording
vim.keymap.set('n', '<Leader>mg', vim.cmd.messages)
vim.keymap.set('n', '<Leader>mm', 'g<', { remap = true })
vim.keymap.set('n', '<Leader>ic', function()
    vim.opt.list = not vim.opt.list:get()
end)
vim.keymap.set('n', '<Leader>sa', function()
    vim.cmd.sort('i')
end)
vim.keymap.set('n', '<Leader>sc', function()
    vim.opt.spell = not vim.opt.spell:get()
end)
vim.keymap.set('n', '<Leader>lp', function()
    vim.api.nvim_input(':lua vim.print(')
end)
vim.keymap.set('n', '<Leader>lr', ':=', { silent = false })
vim.keymap.set('n', '<Leader>ci', vim.cmd.Inspect)
vim.keymap.set('n', '<Leader>cw', function()
    vim.print(('Words: %d'):format(vim.fn.wordcount().words))
end)

-- Commenting
vim.keymap.set('n', '<Leader>cc', 'gcc', { remap = true })
vim.keymap.set('n', '<Leader>cu', 'gcc', { remap = true })
vim.keymap.set('v', '<Leader>cc', 'gc', { remap = true })
vim.keymap.set('v', '<Leader>cu', 'gc', { remap = true })

-- Bookmarks
local git_repos = vim.fs.joinpath(vim.env.HOME, 'git-repos')
local private_notes = vim.fs.joinpath(git_repos, 'private', 'notes')
vim.keymap.set('n', '<Leader>ev', function()
    vim.cmd.edit(vim.env.MYVIMRC)
end)
vim.keymap.set('n', '<Leader>em', function()
    vim.cmd.edit(vim.fs.joinpath(vim.env.DOTVIM, 'minimal.lua'))
end)
vim.keymap.set('n', '<Leader>ew', function()
    vim.cmd.edit(vim.fs.joinpath(vim.env.DOTVIM, 'spell', 'custom-dictionary.utf-8.add'))
end)
vim.keymap.set('n', '<Leader>etm', function()
    vim.cmd.edit(vim.fs.joinpath(private_notes, 'mutt', 'todos_mutt.md'))
end)
vim.keymap.set('n', '<Leader>ets', function()
    vim.cmd.edit(vim.fs.joinpath(private_notes, 'programming', 'todos_coding_setup.md'))
end)
vim.keymap.set('n', '<Leader>eb', function()
    vim.cmd.edit(vim.fs.joinpath(vim.env.HOME, '.bashrc'))
end)
vim.keymap.set('n', '<Leader>eh', function()
    vim.cmd.edit(
        vim.fs.joinpath(
            git_repos,
            'private',
            'dotfiles',
            'arch',
            'config',
            'i3',
            'config'
        )
    )
end)

-- Quick edit
vim.keymap.set('n', '<Leader>dd', function()
    local dir = vim.fs.joinpath(vim.env.HOME, 'Desktop')
    vim.api.nvim_input((':e %s/'):format(dir))
end)
vim.keymap.set('n', '<Leader>sb', function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    vim.api.nvim_input((':e %s/scratch/'):format(dir))
end)

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
vim.keymap.set('n', '<Leader>qf', vim.cmd.copen)
vim.keymap.set('n', '<Leader>qc', vim.cmd.cclose)
vim.keymap.set('n', ']q', function()
    pcall(function()
        vim.cmd.cnext({ count = vim.v.count1 })
    end)
end)
vim.keymap.set('n', '[q', function()
    pcall(function()
        vim.cmd.cprevious({ count = vim.v.count1 })
    end)
end)
vim.keymap.set('n', ']Q', vim.cmd.clast)
vim.keymap.set('n', '[Q', vim.cmd.cfirst)
vim.keymap.set('n', '<Leader>ll', vim.cmd.lopen)
vim.keymap.set('n', '<Leader>lc', vim.cmd.lclose)
vim.keymap.set('n', '<Leader>lC', function()
    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
        if buftype == 'quickfix' then
            vim.api.nvim_win_call(win, function()
                vim.cmd.lclose({ mods = { noautocmd = true } })
            end)
        end
    end
    vim.api.nvim_set_current_win(current_win)
end)
vim.keymap.set('n', ']l', function()
    pcall(function()
        vim.cmd.lnext({ count = vim.v.count1 })
    end)
end)
vim.keymap.set('n', '[l', function()
    pcall(function()
        vim.cmd.lprevious({ count = vim.v.count1 })
    end)
end)
vim.keymap.set('n', ']L', vim.cmd.llast)
vim.keymap.set('n', '[L', vim.cmd.lfirst)

-- Insert mode specific
vim.keymap.set('i', 'jj', '<ESC>')
vim.keymap.set('i', '<A-b>', '<C-o>b')
vim.keymap.set('i', '<A-f>', '<C-o>w')
vim.keymap.set('i', '<A-p>', '<C-R>"')
vim.keymap.set('i', '<A-x>', '<C-W>')
vim.keymap.set('i', '<C-a>', '<C-o>^')
vim.keymap.set('i', '<C-e>', function()
    return vim.fn.pumvisible() == 1 and '<C-e>' or '<C-o>$'
end, { expr = true })
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
    -- FIXME: Not working
    vim.cmd.normal({ args = { '0' }, bang = true })
    vim.fn.search(' ', 'b')
end)
vim.keymap.set('t', 'kj', '<C-\\><C-n>')

-- Select mode (mostly for snippets)
vim.keymap.set('s', 'L', 'L')
vim.keymap.set('s', 'H', 'H')
vim.keymap.set('s', 'M', 'M')
