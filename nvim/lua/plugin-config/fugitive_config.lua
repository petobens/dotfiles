local u = require('utils')

-- Git settings
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('git_ft', { clear = true }),
    pattern = { 'git' },
    callback = function()
        -- Open git previous commits unfolded since we use Glog for the current file
        vim.opt_local.foldlevel = 1
        u.keymap('n', 'q', '<Cmd>bdelete<CR>', { buffer = true })
    end,
})
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    group = vim.api.nvim_create_augroup('git_window_size', { clear = true }),
    pattern = { '*.git/index' },
    command = '15 wincmd _',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('git_commit_ft', { clear = true }),
    pattern = { 'gitcommit' },
    callback = function()
        vim.opt_local.spell = true
        u.keymap('n', 'Q', 'q', { buffer = true, remap = true })
    end,
})
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('git_commit_insert', { clear = true }),
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        vim.cmd('normal! gg0')
        if vim.fn.getline('.') == '' then
            vim.cmd('startinsert')
        end
    end,
})

-- Fugitive settings
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ps_fugitive', { clear = true }),
    pattern = { 'fugitive' },
    callback = function()
        u.keymap('n', 'q', u.quit_return, { buffer = true })
        u.keymap('n', 'ci', '<Cmd><C-U>Git commit -n<CR>', { buffer = true })
        u.keymap('n', ']h', ']c', { buffer = true, remap = true })
        u.keymap('n', '[h', '[c', { buffer = true, remap = true })
    end,
})

-- Mappings
u.keymap('n', '<Leader>gd', '<Cmd>Gdiffsplit<CR><Cmd>wincmd x<CR>')
u.keymap('n', '<Leader>gD', ':Git diff<space>', { silent = false })
u.keymap('n', '<Leader>gs', '<Cmd>botright Git<CR><Cmd>wincmd J<bar>15 wincmd _<CR>4j')
u.keymap('n', '<Leader>gC', '<Cmd>w!<CR><Cmd>Git commit<CR>')
u.keymap('n', '<Leader>gM', '<Cmd>Git! mergetool<CR>')
u.keymap('n', '<Leader>gr', ':Git rebase -i<space>', { silent = false })
u.keymap('n', '<Leader>gR', '<Cmd>GRemove<CR>')
u.keymap('n', '<Leader>gp', '<Cmd>lcd %:p:h<CR><Cmd>Git push<CR>')
u.keymap('n', '<Leader>gF', '<Cmd>lcd %:p:h<CR><Cmd>Git push --force-with-lease<CR>')
u.keymap('n', '<Leader>gP', '<Cmd>lcd %:p:h<CR><Cmd>Git pull<CR>')
u.keymap('n', '<Leader>gb', '<Cmd>GBrowse<CR>')
u.keymap('v', '<Leader>gb', ':GBrowse<CR>')
u.keymap('n', '<Leader>gB', '<Cmd>GBrowse!<CR>')
u.keymap('v', '<Leader>gB', ':GBrowse!<CR>')
u.keymap('n', '<Leader>bl', function()
    vim.cmd('0,3Git blame')
    vim.cmd('wincmd j')
    vim.cmd('normal! 5j')
    vim.cmd('25 wincmd _')
end)
