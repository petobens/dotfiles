local u = require('utils')

_G.fugitiveConfig = {}

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ps_fugitive', { clear = true }),
    pattern = { 'fugitive' }, -- gstatus
    callback = function(e)
        -- Options
        vim.opt_local.winfixheight = true
        vim.opt_local.winfixbuf = true
        -- Mappings
        vim.keymap.set('n', 'q', u.quit_return, { buffer = e.buf })
        vim.keymap.set('n', ']h', ']c', { buffer = e.buf, remap = true })
        vim.keymap.set('n', '[h', '[c', { buffer = e.buf, remap = true })
        vim.keymap.set('n', 'ci', '<Cmd>Git commit -n<CR>', { buffer = e.buf })
        vim.keymap.set('n', '<Leader>gp', '<Cmd>Git push<CR>', { buffer = e.buf })
        vim.keymap.set(
            'n',
            '<Leader>gF',
            '<Cmd>Git push --force-with-lease<CR>',
            { buffer = e.buf }
        )
        vim.keymap.set('n', '<Leader>gP', '<Cmd>Git pull<CR>', { buffer = e.buf })
        vim.keymap.set('n', '<Leader>gl', function()
            vim.cmd.Git({ args = { 'log', '--oneline' } })
        end, { buffer = e.buf })
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
        end, { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('git_ft', { clear = true }),
    pattern = { 'git' }, -- basically diffs/commit history
    callback = function(e)
        vim.opt_local.foldlevel = 1 -- open commits unfolded
        vim.keymap.set('n', 'q', u.quit_return, { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd('FileType', {
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
        end, { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('git_commit_insert', { clear = true }),
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.cmd.wincmd({ args = { '15_' } })
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
    group = vim.api.nvim_create_augroup('git_commit_leave', { clear = true }),
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.api.nvim_set_current_win(_G.fugitiveConfig.gstatus_winid)
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>gs', function()
    vim.cmd.lcd({ args = { vim.fs.dirname(vim.api.nvim_buf_get_name(0)) } })
    vim.cmd('botright Git')
    vim.cmd.wincmd({ args = { 'J' } })
    vim.cmd.resize({ args = { '15' } })
    vim.cmd.normal({ args = { '4j' }, bang = true })
    _G.fugitiveConfig.gstatus_winid = vim.api.nvim_get_current_win()
end)
vim.keymap.set('n', '<Leader>gd', '<Cmd>Gdiffsplit!<CR>')
vim.keymap.set('n', '<Leader>gD', ':Git diff<space>', { silent = false })
vim.keymap.set('n', '<Leader>gM', '<Cmd>Git! mergetool<CR>')
vim.keymap.set('n', '<Leader>gr', ':Git rebase -i<space>', { silent = false })
vim.keymap.set('n', '<Leader>gp', '<Cmd>lcd %:p:h<CR><Cmd>Git push<CR>')
vim.keymap.set(
    'n',
    '<Leader>gF',
    '<Cmd>lcd %:p:h<CR><Cmd>Git push --force-with-lease<CR>'
)
vim.keymap.set('n', '<Leader>gP', '<Cmd>lcd %:p:h<CR><Cmd>Git pull<CR>')
vim.keymap.set({ 'n', 'v' }, '<Leader>gb', ':GBrowse<CR>')
vim.keymap.set({ 'n', 'v' }, '<Leader>gB', ':GBrowse!<CR>')
vim.keymap.set('n', '<Leader>bl', function()
    vim.cmd.Git({ args = { 'blame' }, range = { 0, 3 } })
    vim.cmd.wincmd({ args = { 'j' } })
    vim.cmd.normal({ args = { '5j' }, bang = true })
    vim.cmd.wincmd({ args = { '25_' } })
end)
