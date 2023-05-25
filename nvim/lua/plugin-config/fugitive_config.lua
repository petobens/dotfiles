local u = require('utils')

-- Helpers
local function buf_enter_commit()
    vim.cmd('normal! gg0')
    if vim.fn.getline('.') == '' then
        vim.cmd('startinsert')
    end
end

local function quit_gstatus()
    vim.cmd('wincmd p')
    local win_id = vim.api.nvim_get_current_win()
    vim.cmd('wincmd p')
    vim.cmd('bdelete')
    vim.fn.win_gotoid(win_id)
end

-- Autocmds
local fugitive_acg = vim.api.nvim_create_augroup('ps_fugitive', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
    group = fugitive_acg,
    pattern = { '*.git/COMMIT_EDITMSG' },
    callback = function()
        buf_enter_commit()
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'gitcommit' },
    command = 'setlocal spell',
})
vim.api.nvim_create_autocmd('BufEnter', {
    -- FIXME: not working with nvim-cmp
    -- See https://github.com/petertriho/cmp-git
    group = fugitive_acg,
    pattern = { '*.git/COMMIT_EDITMSG', '*.gitcommit' },
    callback = function()
        local remote =
            vim.api.nvim_exec([[echo FugitiveConfigGet('remote.origin.url')]], true)
        local omnifunc = 'rhubarb#omnifunc'
        if remote:find('github') then
            omnifunc = 'gitlab#omnifunc'
        end
        vim.cmd('setlocal omnifunc=' .. omnifunc)
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'gitcommit' },
    command = 'nmap <silent> <buffer> Q q',
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'git' },
    -- Open git previous commits unfolded since we use Glog for the current file:
    command = 'setlocal foldlevel=1',
})
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    group = fugitive_acg,
    pattern = { '*.git/index', '*.git/COMMIT_EDITMSG' },
    command = '15 wincmd _',
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'fugitive' },
    callback = function()
        u.keymap('n', 'q', quit_gstatus)
    end,
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'fugitive' },
    command = 'nmap <buffer><silent> ]h ]c',
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'fugitive' },
    command = 'nmap <buffer><silent> [h [c',
})
vim.api.nvim_create_autocmd('FileType', {
    group = fugitive_acg,
    pattern = { 'fugitive' },
    command = 'nnoremap <buffer><silent> ci :<C-U>Git commit -n<CR>',
})

-- Mappings
u.keymap('n', '<Leader>gd', '<Cmd>Gdiffsplit<CR><Cmd>wincmd x<CR>')
u.keymap('n', '<Leader>gD', ':Git diff<space>', { silent = false })
u.keymap('n', '<Leader>gs', '<Cmd>botright Git<CR><Cmd>wincmd J<bar>15 wincmd _<CR>')
u.keymap('n', '<Leader>gc', '<Cmd>w!<CR><Cmd>Git commit<CR>')
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
