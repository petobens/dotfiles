local u = require('utils')

-- Git settings
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('git_ft', { clear = true }),
    pattern = { 'git' },
    callback = function(e)
        -- Open git previous commits unfolded since we use Glog for the current file
        vim.opt_local.foldlevel = 1
        vim.keymap.set('n', 'q', '<Cmd>bdelete<CR>', { buffer = e.buf })
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
    callback = function(e)
        vim.opt_local.spell = true
        vim.keymap.set('n', 'Q', 'q', { buffer = e.buf, remap = true })
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

-- Fugitive settings
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ps_fugitive', { clear = true }),
    pattern = { 'fugitive' },
    callback = function(e)
        vim.keymap.set('n', 'q', u.quit_return, { buffer = e.buf })
        vim.keymap.set('n', 'ci', '<Cmd><C-U>Git commit -n<CR>', { buffer = true })
        vim.keymap.set('n', ']h', ']c', { buffer = e.buf, remap = true })
        vim.keymap.set('n', '[h', '[c', { buffer = e.buf, remap = true })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>gd', '<Cmd>Gdiffsplit<CR><Cmd>wincmd x<CR>')
vim.keymap.set('n', '<Leader>gD', ':Git diff<space>', { silent = false })
vim.keymap.set(
    'n',
    '<Leader>gs',
    '<Cmd>botright Git<CR><Cmd>wincmd J<bar>15 wincmd _<CR>4j'
)
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
