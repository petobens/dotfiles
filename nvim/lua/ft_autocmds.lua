-- luacheck:ignore 631
--- i3
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = vim.api.nvim_create_augroup('ft_i3', { clear = true }),
    pattern = { '*i3/config' },
    command = 'setlocal ft=i3config foldmethod=marker',
})

--- Bash
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = vim.api.nvim_create_augroup('ft_bash', { clear = true }),
    pattern = { 'bash_profile', 'bashrc', 'fzf_bash.sh' },
    command = 'setlocal foldmethod=marker filetype=sh',
})

--- Bibtex
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_bib', { clear = true }),
    pattern = { 'bib' },
    command = 'setlocal foldmethod=marker commentstring=%%%%s spell shiftwidth=2 tabstop=2 softtabstop=2',
})

--- Configs
local configs_acg = vim.api.nvim_create_augroup('ft_configs', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = configs_acg,
    pattern = {
        'dunstrc',
        '*.dirs',
        'zathurarc',
        '*mpv/*.conf',
        '*onedrive/config',
        '*fdignore',
        '*pylintrc',
        '*flake8',
        '*ripgreprc',
        'matplotlibrc',
    },
    command = 'setlocal filetype=config foldmethod=marker',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = configs_acg,
    pattern = { 'vimiv.conf' },
    command = 'setlocal filetype=dosini',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = configs_acg,
    pattern = { '*.rasi' },
    command = 'setlocal filetype=css',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = configs_acg,
    pattern = { '*/.ssh/config', '*/ssh/config' },
    command = 'setlocal filetype=sshconfig',
})

--- Crontab
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_crontab', { clear = true }),
    pattern = { 'crontab' },
    command = 'setlocal nobackup nowritebackup',
})

--- Git
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_git', { clear = true }),
    pattern = { 'git' },
    command = 'nnoremap <buffer><silent> q <Cmd>bdelete<CR>',
})

--- HTML & CSS
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_html', { clear = true }),
    pattern = { 'html' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2',
})

--- JSON
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_json', { clear = true }),
    pattern = { 'json' },
    command = 'setlocal foldmethod=syntax',
})

--- Latex
vim.g.tex_flavor = 'latex' -- treat latex files .tex files rather than plaintex

---- Lua
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ft_lua', { clear = true }),
    pattern = { 'lua' },
    command = 'setlocal formatoptions-=ro',
})

--- Markdown
local markdown_acg = vim.api.nvim_create_augroup('ft_markdown', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = markdown_acg,
    pattern = { 'markdown' },
    command = 'setlocal textwidth=90 nolinebreak spell',
})
vim.api.nvim_create_autocmd('FileType', {
    group = markdown_acg,
    pattern = { 'markdown' },
    command = 'setlocal foldlevel=1 foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()',
})

--- Python
local python_acg = vim.api.nvim_create_augroup('ft_python', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = python_acg,
    pattern = { 'pdbrc' },
    command = 'setlocal filetype=python',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = python_acg,
    pattern = { '*.ipynb' },
    command = 'setlocal filetype=json',
})

--- QuickFix
local qf_acg = vim.api.nvim_create_augroup('ft_qf', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = qf_acg,
    pattern = { 'qf' },
    command = 'setlocal colorcolumn= textwidth=0 nospell',
})
vim.api.nvim_create_autocmd('FileType', {
    group = qf_acg,
    pattern = { 'qf' },
    command = 'nnoremap <buffer><silent> q <Cmd>bdelete<CR>',
})
vim.api.nvim_create_autocmd('FileType', {
    group = qf_acg,
    pattern = { 'qf' },
    command = 'nnoremap <buffer><silent> Q <Cmd>bdelete<CR>',
})
vim.api.nvim_create_autocmd({ 'QuitPre', 'BufDelete' }, {
    group = qf_acg,
    -- Automatically close corresponding loclist when quitting a window
    command = 'if &filetype != "qf" | silent! lclose | endif',
})
vim.api.nvim_create_autocmd('FileType', {
    group = qf_acg,
    pattern = { 'qf' },
    callback = function()
        vim.cmd('wincmd J')
        local height = math.max(1, math.min(vim.fn.line('$'), 15))
        vim.cmd(height .. 'wincmd _')
    end,
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

--- SQL
local sql_acg = vim.api.nvim_create_augroup('ft_sql', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = sql_acg,
    pattern = { 'sql' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 textwidth=90',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = sql_acg,
    pattern = { '*.pgsql', '*.mssql', '*.mysql' },
    command = 'setlocal ft=sql',
})

--- Text
local txt_acg = vim.api.nvim_create_augroup('ft_txt', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = txt_acg,
    pattern = { 'text' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 spell',
})

--- TOML
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = vim.api.nvim_create_augroup('ft_toml', { clear = true }),
    pattern = { 'poetry.lock' },
    command = 'set filetype=toml',
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

--- YAML
vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = vim.api.nvim_create_augroup('ft_yaml', { clear = true }),
    pattern = { 'yaml' },
    command = 'setlocal textwidth=90',
})
