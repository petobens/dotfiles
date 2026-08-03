local u = require('utils')

_G.fugitiveConfig = {}

-- Helpers
local function open_file_at_commit_split()
    local bufname = vim.api.nvim_buf_get_name(0)
    local commit = bufname:match('//([0-9a-f]+)$')
    local line = vim.api.nvim_get_current_line()
    local file = line:match('^diff %-%-git a/.- b/(.+)$')
    if commit and file then
        u.split_open(vim.fn.FugitiveFind(commit .. ':' .. file))
    else
        vim.notify(
            'Not on a diff --git line or not in a commit buffer',
            vim.log.levels.WARN
        )
    end
end

local function open_git_status()
    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
    vim.cmd('botright Git')
    vim.cmd.wincmd('J')
    vim.cmd.resize('15')
    vim.cmd.normal({ args = { '4j' }, bang = true })
    _G.fugitiveConfig.gstatus_winid = vim.api.nvim_get_current_win()
end

local function open_status_file_diff()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.cmd.normal({ args = { '$' }, bang = true })
    local file = vim.fn.FugitiveFind(vim.fn.expand('<cfile>'))
    vim.api.nvim_win_set_cursor(0, cursor)
    if not file or file == '' or not vim.uv.fs_stat(file) then
        vim.notify('File does not exist: ' .. tostring(file), vim.log.levels.ERROR)
        return
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative ~= '' then
            vim.api.nvim_win_hide(win)
        end
    end

    u.quit_return()
    vim.cmd.edit(file)
    local worktree_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd.Gdiffsplit({ bang = true })

    local function add_review_comment(range)
        vim.cmd.CodeCompanionCodeReview({ args = { 'Comment' }, range = range })
    end

    vim.keymap.set('n', '<Leader>ra', function()
        add_review_comment()
    end, {
        buf = worktree_bufnr,
        desc = 'Add CodeCompanion review comment',
    })
    vim.keymap.set('v', '<Leader>ra', function()
        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
        local anchor_line = vim.fn.line('v')
        vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
        add_review_comment({
            math.min(anchor_line, cursor_line),
            math.max(anchor_line, cursor_line),
        })
    end, {
        buf = worktree_bufnr,
        desc = 'Add CodeCompanion review comment',
    })

    vim.keymap.set('n', '<Leader>de', function()
        vim.keymap.del('n', '<Leader>de', { buffer = 0 })
        vim.fn['fugitive#DiffClose']()
        open_git_status()
    end, { buf = 0, desc = 'Close diff and return to Fugitive status' })

    vim.cmd.normal({ args = { 'gg' }, bang = true })
    pcall(vim.cmd.normal, { args = { ']c' }, bang = true })
    vim.cmd.normal({ args = { 'zz' }, bang = true })
end

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    desc = 'Set up Fugitive git status options and mappings',
    group = vim.api.nvim_create_augroup('ps_fugitive', { clear = true }),
    pattern = { 'fugitive' },
    callback = function(e)
        -- Options
        vim.opt_local.winfixheight = true
        vim.opt_local.winfixbuf = true

        -- Mappings
        vim.keymap.set(
            'n',
            'q',
            u.quit_return,
            { buf = e.buf, desc = 'Quit Fugitive and return to previous window' }
        )
        vim.keymap.set('n', ']h', ']c', { buf = e.buf, remap = true, desc = 'Next hunk' })
        vim.keymap.set(
            'n',
            '[h',
            '[c',
            { buf = e.buf, remap = true, desc = 'Previous hunk' }
        )
        vim.keymap.set('n', '<Leader>ds', open_status_file_diff, {
            buf = e.buf,
            desc = 'Open file diff and close Fugitive status',
        })

        vim.keymap.set('n', '<Leader>gp', function()
            vim.cmd.Git('push')
        end, { buf = e.buf, desc = 'Push' })

        vim.keymap.set('n', '<Leader>gF', function()
            vim.cmd.Git('push --force-with-lease')
        end, { buf = e.buf, desc = 'Force push with lease' })

        vim.keymap.set('n', '<Leader>gP', function()
            vim.cmd.Git('pull')
        end, { buf = e.buf, desc = 'Pull' })

        vim.keymap.set('n', 'ci', function()
            vim.cmd.Git('commit -n')
        end, { buf = e.buf, desc = 'Commit ignore check (no verify)' })

        vim.keymap.set('n', '<Leader>nd', function()
            local file = vim.fn.FugitiveFind(vim.fn.expand('<cfile>'))
            if not file or file == '' or not vim.uv.fs_stat(file) then
                vim.notify(
                    'File does not exist: ' .. tostring(file),
                    vim.log.levels.ERROR
                )
                return
            end
            vim.notify(
                'Opening browser with nbdiff-web HEAD for: ' .. file,
                vim.log.levels.INFO
            )
            vim.system({ 'nbdiff-web', 'HEAD', file }, { detach = true })
        end, { buf = e.buf, desc = 'Open nbdiff-web for file under cursor' })

        vim.keymap.set('n', '<Leader>dm', function()
            local height = vim.w.fugitive_restore_height
            if height then
                vim.api.nvim_win_resize(0, -1, height)
                vim.w.fugitive_restore_height = nil
            else
                vim.w.fugitive_restore_height = vim.api.nvim_win_get_height(0)
                vim.cmd.wincmd('_')
            end
        end, { buf = e.buf, desc = 'Toggle maximize Fugitive height' })
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Set up git filetype (diffs & commit history) options and mappings',
    group = vim.api.nvim_create_augroup('git_ft', { clear = true }),
    pattern = { 'git' },
    callback = function(e)
        -- Options
        vim.opt_local.foldlevel = 1 -- open commits unfolded

        -- Mappings
        vim.keymap.set(
            'n',
            'q',
            u.quit_return,
            { buf = e.buf, desc = 'Quit and return to previous window' }
        )
        vim.keymap.set(
            'n',
            '<Leader>gh',
            open_file_at_commit_split,
            { buf = e.buf, desc = 'Open file at commit in split (diff --git line)' }
        )
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Set up gitcommit filetype options and mappings',
    group = vim.api.nvim_create_augroup('git_commit_ft', { clear = true }),
    pattern = { 'gitcommit' },
    callback = function(e)
        -- Options
        vim.opt_local.spell = true

        -- Mappings
        vim.keymap.set('n', '<Leader>ac', function()
            vim.cmd.normal({ args = { 'gg0' }, bang = true })
            vim.cmd.normal({ args = { 'dd' }, bang = true })
            vim.cmd.update({ mods = { silent = true, noautocmd = true } })
            vim.cmd.bd()
        end, { buf = e.buf, desc = 'Abort commit' })
    end,
})

local git_commit_edit = vim.api.nvim_create_augroup('git_commit_edit', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    desc = 'Startinsert and highlight commit message summary',
    group = git_commit_edit,
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.cmd.wincmd('15_')
        vim.cmd.normal({ args = { 'gg0' }, bang = true })
        if vim.api.nvim_get_current_line() == '' then
            vim.cmd.startinsert()
        end
        vim.cmd(
            -- Extend gitcommitSummary highlight to 72 columns
            [[syntax region gitcommitSummary start='\%^\%1l' end='.\{72}\|$' keepend]]
        )
    end,
})
vim.api.nvim_create_autocmd({ 'BufLeave' }, {
    desc = 'Go back to git status window after leaving commit message buffer',
    group = git_commit_edit,
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.api.nvim_set_current_win(_G.fugitiveConfig.gstatus_winid)
    end,
})

-- Mappings
vim.keymap.set(
    'n',
    '<Leader>gs',
    open_git_status,
    { desc = 'Open Fugitive status window' }
)

vim.keymap.set('n', '<Leader>gd', function()
    vim.cmd.Gdiffsplit({ bang = true })
end, { desc = 'Run Gdiffsplit' })

vim.keymap.set('n', '<Leader>gD', function()
    vim.cmd.Git('diff')
end, { desc = 'Git diff prompt' })

vim.keymap.set('n', '<Leader>gM', function()
    vim.cmd.Git('mergetool')
end, { desc = 'Git mergetool' })

vim.keymap.set('n', '<Leader>gr', function()
    vim.cmd.Git('rebase -i')
end, { desc = 'Git interactive rebase' })

vim.keymap.set('n', '<Leader>gp', function()
    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
    vim.cmd.Git('push')
end, { desc = 'Push' })

vim.keymap.set('n', '<Leader>gF', function()
    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
    vim.cmd.Git('push --force-with-lease')
end, { desc = 'Force push with lease' })

vim.keymap.set('n', '<Leader>gP', function()
    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
    vim.cmd.Git('pull')
end, { desc = 'Pull' })

vim.keymap.set({ 'n', 'v' }, '<Leader>gb', ':GBrowse<CR>', { desc = 'Browse git object' })

vim.keymap.set(
    { 'n', 'v' },
    '<Leader>gB',
    ':GBrowse!<CR>',
    { desc = 'Copy browser git permalink' }
)

vim.keymap.set('n', '<Leader>bl', function()
    vim.cmd.Git({ args = { 'blame' }, range = { 0, 3 } })
    vim.cmd.wincmd('j')
    vim.cmd.normal({ args = { '5j' }, bang = true })
    vim.cmd.wincmd('25_')
end, { desc = 'Open git blame' })
