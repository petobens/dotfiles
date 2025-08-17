-- luacheck:ignore 631
local u = require('utils')

-- Save and quit
vim.keymap.set('n', '<Leader>w', function()
    vim.cmd.write({ bang = true })
end, { desc = 'Write (save) current buffer' })
vim.keymap.set('n', '<Leader>nw', function()
    vim.cmd.write({ bang = true, mods = { noautocmd = true } })
end, { desc = 'Write without autocommands' })
vim.keymap.set('n', '<Leader>wc', function()
    vim.cmd.write({ bang = true })
    vim.cmd.close({ mods = { silent = true } })
end, { desc = 'Write and close window' })
vim.keymap.set('n', '<Leader>wq', function()
    vim.cmd.write({ bang = true })
    vim.cmd.quit({ bang = true })
end, { desc = 'Write and quit' })
vim.keymap.set(
    'n',
    '<Leader>ws',
    vim.cmd.SudaWrite,
    { desc = 'Write with sudo (SudaWrite)' }
)
vim.keymap.set('n', '<Leader>rs', function()
    vim.api.nvim_input(':SudaRead ')
end, { desc = 'Read file with sudo (SudaRead)' })
vim.keymap.set(
    'n',
    '<Leader>rr',
    vim.cmd.checktime,
    { desc = 'Re-read file if changed on disk' }
)
vim.keymap.set('n', '<Leader>so', function()
    vim.cmd.update()
    vim.cmd.luafile('%')
end, { silent = false, desc = 'Source current file' })

-- Sessions
vim.api.nvim_create_user_command('RestoreSession', function()
    vim.cmd.source({ args = { u.vim_session_file() }, mods = { silent = true } })
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_get_option(bufnr, 'buflisted')
            and vim.bo[bufnr].buftype ~= 'quickfix'
        then
            if vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr)) == nil then
                vim.cmd.bwipeout(tostring(bufnr))
            end
        end
    end
end, {})
vim.keymap.set('n', '<Leader>ps', vim.cmd.RestoreSession, { desc = 'Restore session' })
vim.keymap.set('n', '<Leader>rv', function()
    vim.cmd.update({ mods = { silent = true, noautocmd = true } })
    vim.cmd.restart({ args = { '+qall!', 'RestoreSession' } })
end, { desc = 'Restart and restore session' })
vim.keymap.set('n', '<Leader>kv', vim.cmd.qall, { desc = 'Quit all (exit)' })

-- Buffer manipulation
vim.keymap.set('n', '<C-n>', vim.cmd.bnext, { desc = 'Next buffer' })
vim.keymap.set('n', '<C-p>', vim.cmd.bprevious, { desc = 'Previous buffer' })
vim.keymap.set('n', '<Leader>wd', vim.cmd.bdelete, { desc = 'Delete buffer' })
vim.keymap.set('n', '<Leader>bd', function()
    vim.cmd.bprevious()
    vim.cmd.bdelete('#')
end, { desc = 'Delete buffer and go to previous' })
vim.keymap.set('n', '<Leader>cd', function()
    vim.api.nvim_set_current_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
end, { desc = 'Set CWD to current buffer directory' })

-- Window manipulation
vim.keymap.set('n', '<C-A-h>', function()
    vim.cmd.wincmd('2<')
end, { desc = 'Resize window left' })
vim.keymap.set('n', '<C-A-l>', function()
    vim.cmd.wincmd('2>')
end, { desc = 'Resize window right' })
vim.keymap.set('n', '<C-A-j>', function()
    vim.cmd.wincmd('2+')
end, { desc = 'Resize window down' })
vim.keymap.set('n', '<C-A-k>', function()
    vim.cmd.wincmd('2-')
end, { desc = 'Resize window up' })
vim.keymap.set('n', '<C-c>', vim.cmd.close, { desc = 'Close window' })
vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_get_config(0).relative ~= '' then
        vim.cmd.close()
    end
end, { desc = 'Close floating window' })
vim.keymap.set('n', '<A-o>', function()
    vim.cmd.only()
    vim.cmd.normal('zv')
end, { desc = 'Close all other windows' })
vim.keymap.set('n', '<Leader>sp', vim.cmd.split, { desc = 'Horizontal split' })
vim.keymap.set('n', '<Leader>vs', vim.cmd.vsplit, { desc = 'Vertical split' })
vim.keymap.set('n', '<C-x>', function()
    vim.cmd.wincmd('x')
    vim.cmd.normal('zz')
end, { desc = 'Swap window and center' })
vim.keymap.set('n', '<Leader>hv', function()
    vim.cmd.wincmd('H')
    vim.cmd.wincmd('x')
end, { desc = 'Move window to left' })
vim.keymap.set('n', '<Leader>vh', function()
    vim.cmd.wincmd('K')
end, { desc = 'Move window to top' })

-- Line navigation and editing
vim.keymap.set({ 'n', 'i', 'v' }, '<down>', '<nop>', { desc = 'Disable <down>' })
vim.keymap.set({ 'n', 'i', 'v' }, '<left>', '<nop>', { desc = 'Disable <left>' })
vim.keymap.set({ 'n', 'i', 'v' }, '<right>', '<nop>', { desc = 'Disable <right>' })
vim.keymap.set({ 'n', 'i', 'v' }, '<up>', '<nop>', { desc = 'Disable <up>' })
vim.keymap.set('n', '<A-0>', 'H', { desc = 'Go to first line on screen' })
vim.keymap.set('n', '<A-b>', 'L', { desc = 'Go to last line on screen' })
vim.keymap.set('n', '<A-m>', 'M', { desc = 'Go to middle line on screen' })
vim.keymap.set({ 'n', 'v' }, 'H', '^', { desc = 'Go to first non-blank' })
vim.keymap.set('n', 'L', '$', { desc = 'Go to end of line' })
vim.keymap.set('n', 'M', function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()
    local line_len = vim.str_utfindex(line)
    local middle = math.floor(line_len / 2)
    vim.api.nvim_win_set_cursor(0, { row, middle })
end, { desc = 'Go to middle of line' })
vim.keymap.set('n', 'j', 'gj', { desc = 'Down (display line)' })
vim.keymap.set('n', 'k', 'gk', { desc = 'Up (display line)' })
vim.keymap.set(
    'n',
    '<Leader>oj',
    ']<Space>j',
    { remap = true, desc = 'Open line below and move down' }
)
vim.keymap.set(
    'n',
    '<Leader>ok',
    '[<Space>k',
    { remap = true, desc = 'Open line above and move up' }
)
vim.keymap.set('n', '<A-j>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd.move(tostring(line + vim.v.count1))
    pcall(function()
        vim.cmd.normal({ args = { 'zO' }, bang = true, mods = { silent = true } })
    end)
end, { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd.move(tostring(line - vim.v.count1 - 1))
    pcall(function()
        vim.cmd.normal({ args = { 'zO' }, bang = true, mods = { silent = true } })
    end)
end, { desc = 'Move line up' })
vim.keymap.set(
    'n',
    '<A-s>',
    'i<CR><ESC>^mwgk:silent! s/\\v +$//<CR>:noh<CR>`w',
    { desc = 'Split line' }
)
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines (keep cursor)' })
vim.keymap.set('n', 'Q', 'gwap', { desc = 'Format paragraph' })
vim.keymap.set('n', '<A-u>', 'mzg~iw`z', { desc = 'Toggle case of word' })
vim.keymap.set({ 'n', 'v' }, '+', '<C-a>', { desc = 'Increment number' })
vim.keymap.set({ 'n', 'v' }, '-', '<C-x>', { desc = 'Decrement number' })

-- Yank and paste
vim.keymap.set('n', 'Y', 'y$', { desc = 'Yank to end of line' })
vim.keymap.set('n', 'yy', 'mz0y$`z', { desc = 'Yank line (keep cursor)' })
vim.keymap.set('n', '<Leader>yf', function()
    local path = vim.api.nvim_buf_get_name(0)
    vim.fn.setreg('+', path)
    vim.fn.setreg('*', path)
    vim.notify(('Yanked file: %s'):format(path), vim.log.levels.INFO)
end, { desc = 'Yank file path to clipboard' })
vim.keymap.set('n', '<Leader>yd', function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    vim.fn.setreg('+', dir)
    vim.fn.setreg('*', dir)
    vim.notify(('Yanked directory: %s'):format(dir), vim.log.levels.INFO)
end, { desc = 'Yank directory path to clipboard' })
vim.keymap.set(
    'n',
    '<Leader>pp',
    vim.cmd.put,
    { desc = 'Put (paste) from default register' }
)
vim.keymap.set('n', '<Leader>P', function()
    vim.cmd.put({ bang = true })
end, { desc = 'Put (paste) from default register above' })
vim.keymap.set('n', 'gp', '`[v`]', { desc = 'Visually select just-pasted text' })

-- Search, jumps and marks
vim.keymap.set(
    { 'n', 'v' },
    '/',
    '/\\v',
    { silent = false, remap = true, desc = 'Search (very magic)' }
)
vim.keymap.set(
    { 'n', 'v' },
    '?',
    '?\\v',
    { silent = false, remap = true, desc = 'Backward search (very magic)' }
)
vim.keymap.set('n', '<Leader><Space>', function()
    vim.cmd.nohlsearch()
    vim.fn.clearmatches()
end, { desc = 'Clear search highlights and matches' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search match and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search match and center' })
vim.keymap.set('n', '*', function()
    -- Don't jump to first match with *
    local word = vim.fn.expand('<cword>')
    vim.fn.setreg('/', '\\v' .. word)
    vim.o.hlsearch = true
end, { remap = true, desc = 'Search word under cursor (no jump)' })
vim.keymap.set(
    'n',
    '#',
    '#``',
    { desc = 'Search backward for word under cursor (keep position)' }
)
vim.keymap.set(
    'n',
    '<Leader>sw',
    '/<><Left>',
    { silent = false, remap = true, desc = 'Search for bounded word' }
)
vim.keymap.set('n', '<Leader>sr', function()
    vim.api.nvim_input(':%s/')
end, { desc = 'Start search and replace' })
vim.keymap.set('n', '<C-o>', '<C-o>zvzz', { desc = 'Jump back and center' })
vim.keymap.set('n', '<C-y>', '<C-i>zvzz', { desc = 'Jump forward and center' })
vim.keymap.set('n', "'", '`', { desc = 'Jump to mark (backtick instead of quote)' })
vim.keymap.set('n', '<Leader>dm', function()
    vim.cmd.delmarks({ bang = true })
    vim.cmd.delmarks('A-Z0-9')
end, { desc = 'Delete all marks' })
vim.keymap.set('n', '[m', '[mzz', { desc = 'Previous mark and center' })
vim.keymap.set('n', ']m', ']mzz', { desc = 'Next mark and center' })
for i = 1, 6 do
    vim.keymap.set('n', '<Leader>h' .. i, function()
        vim.cmd.normal({ args = { 'mz"zyiw' }, bang = true })
        local mid = 86750 + i
        pcall(vim.fn.matchdelete, mid)
        local word = vim.fn.getreg('z')
        local pat = ([[\V\<%s\>]]):format(vim.fn.escape(word, '\\'))
        vim.fn.matchadd(('HlWord%s'):format(i), pat, 1, mid)
        vim.cmd.normal({ args = { '`z' }, bang = true })
    end, { desc = ('Highlight word under cursor (slot %d)'):format(i) })
end

-- Folds
vim.keymap.set('n', 'zm', 'zM', { desc = 'Close all folds' })
vim.keymap.set('n', 'zr', 'zR', { desc = 'Open all folds' })
vim.keymap.set('n', '<Leader>mf', function()
    vim.opt.foldmethod = 'marker'
    vim.cmd.normal('zv')
end, { desc = "Set foldmethod to 'marker' and open folds" })
vim.keymap.set('n', '<Leader>zf', 'zMzvzz', { desc = 'Zoom/fold focus' })
vim.keymap.set('n', 'l', function()
    -- Open fold from start
    local foldstart_linenr = vim.fn.foldclosed('.')
    if foldstart_linenr == -1 then
        vim.cmd.normal({ args = { 'l' }, bang = true })
        return
    end
    vim.cmd.normal({ args = { 'zo' }, bang = true })
    vim.api.nvim_win_set_cursor(0, { foldstart_linenr, 0 })
end, { desc = 'Open fold from start or move right' })

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
                other_file = vim.fs.abspath(other_file)
                local stat = vim.uv.fs_stat(other_file)
                if not stat or stat.type ~= 'file' then
                    vim.notify(
                        ('File not found: %s'):format(other_file),
                        vim.log.levels.ERROR
                    )
                    return
                end

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
end, { desc = 'Diff current buffer with another file' })
vim.keymap.set('n', '<Leader>du', vim.cmd.diffupdate, { desc = 'Update diff' })
vim.keymap.set('n', '<Leader>de', function()
    vim.cmd.bdelete('#')
    vim.cmd.normal('zz')
end, { desc = 'Close diff buffer and recenter' })

-- Misc
vim.keymap.set('n', '<Leader>mr', 'q', { desc = 'Start/stop macro recording' })
vim.keymap.set('n', '<Leader>mg', vim.cmd.messages, { desc = 'Show message history' })
vim.keymap.set('n', '<Leader>mm', 'g<', { remap = true, desc = 'Show last message (g<)' })
vim.keymap.set('n', '<Leader>C', function()
    vim.o.scrolloff = 999 - vim.o.scrolloff
end, { desc = 'Toggle scrolloff between 0 and 999' })
vim.keymap.set('n', '<Leader>ic', function()
    vim.opt.list = not vim.opt.list:get()
end, { desc = 'Toggle listchars' })
vim.keymap.set('n', '<Leader>sa', function()
    vim.cmd.sort('i')
end, { desc = 'Sort lines (case-insensitive)' })
vim.keymap.set('n', '<Leader>sc', function()
    vim.opt.spell = not vim.opt.spell:get()
end, { desc = 'Toggle spell checking' })
vim.keymap.set('n', '<Leader>lp', function()
    vim.api.nvim_input(':lua vim.print(')
end, { desc = 'Insert :lua vim.print( at command line' })
vim.keymap.set(
    'n',
    '<Leader>lr',
    ':=',
    { silent = false, desc = 'Open command-line for Lua expression' }
)
vim.keymap.set(
    'n',
    '<Leader>ci',
    vim.cmd.Inspect,
    { desc = 'Inspect syntax and extmarks at cursor' }
)
vim.keymap.set('n', '<Leader>cw', function()
    vim.print(('Words: %d'):format(vim.fn.wordcount().words))
end, { desc = 'Show word count' })

-- Commenting
vim.keymap.set('n', '<Leader>cc', 'gcc', { remap = true, desc = 'Toggle comment line' })
vim.keymap.set('n', '<Leader>cu', 'gcc', { remap = true, desc = 'Toggle uncomment line' })
vim.keymap.set(
    'v',
    '<Leader>cc',
    'gc',
    { remap = true, desc = 'Toggle comment selection' }
)
vim.keymap.set(
    'v',
    '<Leader>cu',
    'gc',
    { remap = true, desc = 'Toggle uncomment selection' }
)

-- Bookmarks
local git_repos = vim.fs.joinpath(vim.env.HOME, 'git-repos')
local private_notes = vim.fs.joinpath(git_repos, 'private', 'notes')
vim.keymap.set('n', '<Leader>ev', function()
    vim.cmd.edit(vim.env.MYVIMRC)
end, { desc = 'Edit init.lua (MYVIMRC)' })
vim.keymap.set('n', '<Leader>em', function()
    vim.cmd.edit(vim.fs.joinpath(vim.env.DOTVIM, 'minimal.lua'))
end, { desc = 'Edit minimal.lua' })
vim.keymap.set('n', '<Leader>ew', function()
    vim.cmd.edit(vim.fs.joinpath(vim.env.DOTVIM, 'spell', 'custom-dictionary.utf-8.add'))
end, { desc = 'Edit custom dictionary' })
vim.keymap.set('n', '<Leader>etm', function()
    vim.cmd.edit(vim.fs.joinpath(private_notes, 'mutt', 'todos_mutt.md'))
end, { desc = 'Edit mutt todos' })
vim.keymap.set('n', '<Leader>ets', function()
    vim.cmd.edit(vim.fs.joinpath(private_notes, 'programming', 'todos_coding_setup.md'))
end, { desc = 'Edit coding setup todos' })
vim.keymap.set('n', '<Leader>eb', function()
    vim.cmd.edit(vim.fs.joinpath(vim.env.HOME, '.bashrc'))
end, { desc = 'Edit .bashrc' })
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
end, { desc = 'Edit i3 config' })

-- Quick edit
vim.keymap.set('n', '<Leader>dd', function()
    local dir = vim.fs.joinpath(vim.env.HOME, 'Desktop')
    vim.api.nvim_input((':e %s/'):format(dir))
end, { desc = 'Edit file in ~/Desktop' })
vim.keymap.set('n', '<Leader>sb', function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    vim.api.nvim_input((':e %s/scratch/'):format(dir))
end, { desc = 'Edit file in scratch directory' })

-- Links & files
vim.keymap.set(
    { 'n', 'v' },
    '<Leader>ol',
    'gx',
    { remap = true, desc = 'Open link under cursor' }
)
vim.keymap.set('n', 'gf', function()
    local mods
    if vim.api.nvim_win_get_width(0) > 2 * (vim.go.textwidth or 80) then
        mods = { vertical = true }
    end
    vim.cmd.wincmd({ args = { 'f' }, mods = mods })
end, { desc = 'Edit file under cursor (vertical if wide)' })
vim.keymap.set('n', '<Leader>fm', function()
    vim.system({ 'tmux', 'split-window', '-l', '20', '-c', vim.uv.cwd(), 'ranger' })
end, { desc = 'Open ranger in tmux split' })

-- Quickfix and Location
vim.keymap.set('n', '<Leader>qf', vim.cmd.copen, { desc = 'Open quickfix list' })
vim.keymap.set('n', '<Leader>qc', vim.cmd.cclose, { desc = 'Close quickfix list' })
vim.keymap.set('n', ']q', function()
    pcall(vim.cmd.cnext)
end, { desc = 'Next quickfix entry' })
vim.keymap.set('n', '[q', function()
    pcall(vim.cmd.cprevious)
end, { desc = 'Previous quickfix entry' })
vim.keymap.set('n', ']Q', vim.cmd.clast, { desc = 'Last quickfix entry' })
vim.keymap.set('n', '[Q', vim.cmd.cfirst, { desc = 'First quickfix entry' })
vim.keymap.set('n', '<Leader>qr', function()
    vim.api.nvim_input(':cdo %s/')
end, { desc = 'Quickfix: start :cdo replace' })
vim.keymap.set('n', '<Leader>ll', vim.cmd.lopen, { desc = 'Open location list' })
vim.keymap.set('n', '<Leader>lc', vim.cmd.lclose, { desc = 'Close location list' })
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
end, { desc = 'Close all location lists' })
vim.keymap.set('n', ']l', function()
    pcall(vim.cmd.lnext)
end, { desc = 'Next location list entry' })
vim.keymap.set('n', '[l', function()
    pcall(vim.cmd.lprevious)
end, { desc = 'Previous location list entry' })
vim.keymap.set('n', ']L', vim.cmd.llast, { desc = 'Last location list entry' })
vim.keymap.set('n', '[L', vim.cmd.lfirst, { desc = 'First location list entry' })

-- Insert mode
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit insert mode (jj)' })
vim.keymap.set('i', '<A-b>', '<C-o>b', { desc = 'Move back a word' })
vim.keymap.set('i', '<A-f>', '<C-o>w', { desc = 'Move forward a word' })
vim.keymap.set('i', '<C-a>', '<C-o>^', { desc = 'Move to first non-blank' })
vim.keymap.set('i', '<C-e>', function()
    return vim.fn.pumvisible() == 1 and '<C-e>' or '<C-o>$'
end, { expr = true, desc = 'Move to end of line (or close popup)' })
vim.keymap.set('i', '<C-h>', '<C-o>h', { desc = 'Move left' })
vim.keymap.set('i', '<C-l>', '<C-o>l', { desc = 'Move right' })
vim.keymap.set('i', '<A-p>', '<C-R>"', { desc = 'Paste from unnamed register' })

-- Visual mode
-- Note: we avoid lua function mappings in visual mode since they lose the selection
vim.keymap.set('n', 'vv', '^vg_', { desc = 'Visually select line (no indent)' })
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left and reselect' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right and reselect' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv", { desc = 'Move selection up' })
vim.keymap.set('v', '<ESC>', '"+ygv<C-c>', { desc = 'Yank selection and keep selection' })
vim.keymap.set(
    'v',
    '<Leader>sa',
    ':sort i<CR>',
    { desc = 'Sort selection (case-insensitive)' }
)
vim.keymap.set(
    'v',
    '<Leader>sr',
    ':s/',
    { silent = false, desc = 'Start substitute in selection' }
)
vim.keymap.set('v', 'G', 'G$', { desc = 'Go to end of selection' })
vim.keymap.set('v', 'L', 'g_', { desc = 'Go to last non-blank in selection' })
vim.keymap.set('v', 'Q', 'gq', { desc = 'Format selection' })
vim.keymap.set('v', '.', ':normal .<CR>', { desc = 'Repeat last change in selection' })
vim.keymap.set('v', '*', '*<C-o>', { desc = 'Search for selection forward' })
vim.keymap.set('v', '#', '#<C-o>', { desc = 'Search for selection backward' })

-- Command mode
vim.keymap.set('n', ';', ':', { silent = false, desc = 'Enter command-line mode' })
vim.keymap.set('c', '<A-b>', '<S-Left>', { desc = 'Move cursor left by word' })
vim.keymap.set('c', '<A-f>', '<S-Right>', { desc = 'Move cursor right by word' })
vim.keymap.set('c', '<C-a>', '<home>', { desc = 'Move to start of line' })
vim.keymap.set('c', '<C-e>', '<end>', { remap = true, desc = 'Move to end of line' })
vim.keymap.set('c', '<C-h>', '<left>', { desc = 'Move cursor left' })
vim.keymap.set('c', '<C-l>', '<right>', { desc = 'Move cursor right' })
vim.keymap.set(
    'c',
    '<C-x>',
    '<C-U>',
    { silent = false, desc = 'Delete to start of line' }
)
vim.keymap.set('c', '<A-x>', '<C-W>', { silent = false, desc = 'Delete previous word' })
vim.keymap.set(
    'c',
    '<A-p>',
    '<C-R>"',
    { silent = false, desc = 'Paste from unnamed register' }
)
vim.keymap.set('c', '%%', function()
    if vim.fn.getcmdtype() == ':' then
        return vim.fs.dirname(vim.api.nvim_buf_get_name(0)) .. '/'
    else
        return '%%'
    end
end, { expr = true, silent = false, desc = 'Expand to buffer directory in :cmd' })

-- Terminal mode
local terminal_escape = '<C-\\><C-n>' -- enter normal mode from terminal
vim.keymap.set('t', 'kj', terminal_escape, { desc = 'Exit terminal mode (kj)' })
vim.keymap.set(
    't',
    '<C-A-n>',
    ('%s:bn<CR>'):format(terminal_escape),
    { desc = 'Next buffer from terminal' }
)
vim.keymap.set(
    't',
    '<C-A-p>',
    ('%s:bp<CR>'):format(terminal_escape),
    { desc = 'Previous buffer from terminal' }
)
vim.keymap.set(
    't',
    '<C-h>',
    ('%s<C-W>h'):format(terminal_escape),
    { desc = 'Move to left window from terminal' }
)
vim.keymap.set(
    't',
    '<C-j>',
    ('%s<C-W>j'):format(terminal_escape),
    { desc = 'Move to below window from terminal' }
)
vim.keymap.set(
    't',
    '<C-k>',
    ('%s<C-W>k'):format(terminal_escape),
    { desc = 'Move to above window from terminal' }
)
vim.keymap.set(
    't',
    '<C-l>',
    ('%s<C-W>l'):format(terminal_escape),
    { desc = 'Move to right window from terminal' }
)
vim.keymap.set('t', '<C-[>', function()
    vim.api.nvim_feedkeys(vim.keycode(terminal_escape), 'n', false)
    vim.schedule(function()
        vim.cmd.normal({ args = { '0' }, bang = true })
        vim.fn.search(' ', 'b')
    end)
end, { desc = 'Move to previous terminal prompt' })

-- Select mode (mostly for snippets)
vim.keymap.set('s', 'L', 'L', { desc = 'Move to last character in selection' })
vim.keymap.set('s', 'H', 'H', { desc = 'Move to first character in selection' })
vim.keymap.set('s', 'M', 'M', { desc = 'Move to middle character in selection' })
