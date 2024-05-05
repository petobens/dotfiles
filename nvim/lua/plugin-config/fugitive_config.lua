local u = require('utils')

_G.fugitiveConfig = {}

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ps_fugitive', { clear = true }),
    pattern = { 'fugitive' }, -- gstatus
    callback = function(e)
        vim.opt_local.winfixheight = true
        vim.opt_local.winfixbuf = true

        vim.keymap.set('n', 'q', u.quit_return, { buffer = e.buf })
        vim.keymap.set('n', ']h', ']c', { buffer = e.buf, remap = true })
        vim.keymap.set('n', '[h', '[c', { buffer = e.buf, remap = true })
        vim.keymap.set('n', 'ci', '<Cmd>Git commit -n<CR>', { buffer = true })
        vim.keymap.set('n', '<Leader>gp', '<Cmd>Git push<CR>', { buffer = true })
        vim.keymap.set(
            'n',
            '<Leader>gF',
            '<Cmd>Git push --force-with-lease<CR>',
            { buffer = true }
        )
        vim.keymap.set('n', '<Leader>gP', '<Cmd>Git pull<CR>', { buffer = true })
    end,
})
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    group = vim.api.nvim_create_augroup('git_window_size', { clear = true }),
    pattern = { '*.git/index' },
    command = '15 wincmd _',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('git_ft', { clear = true }),
    pattern = { 'git' }, -- basically diffs
    callback = function(e)
        -- Open git previous commits unfolded since we use Glog for the current file
        vim.opt_local.foldlevel = 1
        vim.keymap.set('n', 'q', '<Cmd>bdelete<CR>', { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('git_commit_ft', { clear = true }),
    pattern = { 'gitcommit' },
    callback = function(e)
        vim.opt_local.spell = true
        vim.keymap.set('n', '<Leader>ac', function()
            vim.cmd('normal! gg0')
            vim.cmd('normal! dd')
            vim.cmd('silent noautocmd update')
            vim.cmd('bd')
        end, { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('git_commit_insert', { clear = true }),
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.cmd('15 wincmd _')
        vim.cmd('normal! gg0')
        if vim.fn.getline('.') == '' then
            vim.cmd('startinsert')
        end
    end,
})
vim.api.nvim_create_autocmd({ 'BufLeave' }, {
    group = vim.api.nvim_create_augroup('git_commit_leave', { clear = true }),
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.fn.win_gotoid(_G.fugitiveConfig.gstatus_winid)
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>gs', function()
    vim.cmd('botright Git')
    vim.cmd('wincmd J | resize 15')
    vim.cmd('normal! 4j')
    _G.fugitiveConfig.gstatus_winid = vim.fn.win_getid()
end)
vim.keymap.set('n', '<Leader>gd', '<Cmd>Gdiffsplit<CR><Cmd>wincmd x<CR>')
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
    vim.cmd('0,3Git blame')
    vim.cmd('wincmd j')
    vim.cmd('normal! 5j')
    vim.cmd('25 wincmd _')
end)
