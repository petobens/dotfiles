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
