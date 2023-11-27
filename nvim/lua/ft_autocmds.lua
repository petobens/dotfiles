local u = require('utils')

--- Crontab
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_crontab', { clear = true }),
    pattern = { 'crontab' },
    command = 'setlocal nobackup nowritebackup',
})

--- HTML & CSS
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_html', { clear = true }),
    pattern = { 'html' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2',
})

--- QuickFix
local qf_acg = vim.api.nvim_create_augroup('ft_qf', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = qf_acg,
    pattern = { 'qf' },
    callback = function()
        -- Options, position and dynamic height
        vim.cmd('setlocal colorcolumn= textwidth=0 nospell nobuflisted')
        vim.cmd('wincmd J')
        vim.cmd(math.max(1, math.min(vim.fn.line('$'), 15)) .. 'wincmd _')

        -- Maps
        local map_opts = { buffer = true }
        u.keymap('n', 'q', '<Cmd>bdelete<CR>', map_opts)
        u.keymap('n', 'Q', '<Cmd>bdelete<CR>', map_opts)
        u.keymap('n', '<C-s>', '<C-w><Enter>', map_opts)
        u.keymap('n', '<C-v>', '<C-w><Enter><C-w>L', map_opts)
        u.keymap(
            'n',
            '<C-q>',
            '<Cmd>cclose<bar>wincmd p<bar>Telescope quickfix<CR>',
            map_opts
        )
        u.keymap(
            'n',
            '<C-l>',
            '<Cmd>lclose<bar>wincmd p<bar>Telescope loclist<CR>',
            map_opts
        )
    end,
})
vim.api.nvim_create_autocmd({ 'QuitPre', 'BufDelete' }, {
    group = qf_acg,
    -- Automatically close corresponding loclist when quitting a window
    command = 'if &filetype != "qf" | silent! lclose | endif',
})

--- R
local r_acg = vim.api.nvim_create_augroup('ft_R', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = r_acg,
    pattern = { 'Rprofile', '.Rprofile', '*.R', 'radian_profile', '.radian_profile' },
    command = 'setlocal ft=r',
})
vim.api.nvim_create_autocmd('FileType', {
    group = r_acg,
    pattern = { 'r' },
    command = 'setlocal foldmethod=syntax',
})

--- Text
local txt_acg = vim.api.nvim_create_augroup('ft_txt', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = txt_acg,
    pattern = { 'text' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 spell',
})

--- Vim (also help and man)
local vim_acg = vim.api.nvim_create_augroup('ft_vim', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = vim_acg,
    pattern = { 'vim' },
    command = 'setlocal foldmethod=marker formatoptions-=ro',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim_acg,
    pattern = { 'help' },
    command = 'setlocal textwidth=78 relativenumber',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim_acg,
    pattern = { '*.txt' },
    command = 'if &ft == "help" | wincmd J | endif',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim_acg,
    pattern = { '*.txt' },
    command = 'if &ft == "help" | 20 wincmd _ | endif',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim_acg,
    pattern = { 'help' },
    command = 'nnoremap <buffer><silent> q <Cmd>bdelete<CR>',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim_acg,
    pattern = { 'help', 'man' },
    command = 'nmap <buffer><silent><Leader>tc gO',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim_acg,
    pattern = { 'help', 'man' },
    command = 'nmap <buffer><silent><Leader>tC :execute "normal gO" <bar> bd<CR>',
})
vim.api.nvim_create_autocmd('FileType', {
    group = vim_acg,
    pattern = { 'man' },
    command = 'setlocal iskeyword+=-',
})
