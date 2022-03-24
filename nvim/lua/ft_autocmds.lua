--- i3
vim.api.nvim_create_augroup('ft_i3', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_i3',
    pattern = { '*i3/config' },
    command = 'setlocal ft=i3config foldmethod=marker',
})

--- Bash
vim.api.nvim_create_augroup('ft_bash', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_bash',
    pattern = { 'bash_profile', 'bashrc', 'fzf_bash.sh' },
    command = 'setlocal foldmethod=marker filetype=sh',
})

--- Bibtex
vim.api.nvim_create_augroup('ft_bib', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_bib',
    pattern = { 'bib' },
    command = 'setlocal foldmethod=marker commentstring=%%%%s spell shiftwidth=2 tabstop=2 softtabstop=2',
})

--- Configs
vim.api.nvim_create_augroup('ft_configs', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_configs',
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
    group = 'ft_configs',
    pattern = { 'vimiv.conf' },
    command = 'setlocal filetype=dosini',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_configs',
    pattern = { '*.rasi' },
    command = 'setlocal filetype=css',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_configs',
    pattern = { '*/.ssh/config', '*/ssh/config' },
    command = 'setlocal filetype=sshconfig',
})

--- Crontab
vim.api.nvim_create_augroup('ft_crontab', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_crontab',
    pattern = { 'crontab' },
    command = 'setlocal nobackup nowritebackup',
})

--- HTML & CSS
vim.api.nvim_create_augroup('ft_html', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_html',
    pattern = { 'html' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2',
})

--- JSON
vim.api.nvim_create_augroup('ft_json', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_json',
    pattern = { 'json' },
    command = 'setlocal foldmethod=syntax',
})

--- Latex
vim.api.nvim_create_augroup('ft_tex', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_tex',
    pattern = { 'tex' },
    command = 'setlocal iskeyword=@,48-57,_,192-255,: comments+=b:\\item indentkeys=!^F,o,O,0=\\item',
})

--- Markdown
vim.api.nvim_create_augroup('ft_markdown', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_markdown',
    pattern = { 'markdown' },
    command = 'setlocal textwidth=90 nolinebreak spell',
})

--- Python
vim.api.nvim_create_augroup('ft_python', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_python',
    pattern = { 'python' },
    command = 'setlocal commentstring=#%s ',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_python',
    pattern = { 'pdbrc' },
    command = 'setlocal filetype=python',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_python',
    pattern = { '*.ipynb' },
    command = 'setlocal filetype=json',
})

--- QuickFix
vim.api.nvim_create_augroup('ft_qf', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_qf',
    pattern = { 'qf' },
    command = 'setlocal colorcolumn= textwidth=0 nospell',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_qf',
    pattern = { 'qf' },
    command = 'nnoremap <buffer><silent> q <Cmd>bdelete<CR>',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_qf',
    pattern = { 'qf' },
    command = 'nnoremap <buffer><silent> Q <Cmd>bdelete<CR>',
})
vim.api.nvim_create_autocmd({ 'QuitPre', 'BufDelete' }, {
    group = 'ft_qf',
    -- Automatically close corresponding loclist when quitting a window
    command = 'if &filetype != "qf" | silent! lclose | endif',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_qf',
    pattern = { 'qf' },
    callback = function()
        vim.cmd('wincmd J')
        local height = math.max(1, math.min(vim.fn.line('$'), 15))
        vim.cmd(height .. 'wincmd _')
    end,
})

--- R
vim.api.nvim_create_augroup('ft_R', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_R',
    pattern = { 'Rprofile', '.Rprofile', '*.R', 'radian_profile', '.radian_profile' },
    command = 'setlocal ft=r',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_R',
    pattern = { 'r' },
    command = 'setlocal foldmethod=syntax',
})

--- SQL
vim.api.nvim_create_augroup('ft_sql', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_sql',
    pattern = { 'sql' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_sql',
    pattern = { '*.pgsql', '*.mssql', '*.mysql' },
    command = 'setlocal ft=sql',
})
-- FIXME: not quite working
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_sql',
    pattern = { 'sql' },
    command = 'syn keyword sqlFunction DATE_PARSE DATE_DIFF DATE_TRUNC',
})

--- Text
vim.api.nvim_create_augroup('ft_txt', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_txt',
    pattern = { 'text' },
    command = 'setlocal shiftwidth=2 tabstop=2 softtabstop=2 spell',
})

--- TOML
vim.api.nvim_create_augroup('ft_toml', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = 'ft_toml',
    pattern = { 'poetry.lock' },
    command = 'set  filetype=toml',
})

--- Vim (also help and man)
vim.api.nvim_create_augroup('ft_vim', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_vim',
    pattern = { 'vim' },
    command = 'setlocal foldmethod=marker formatoptions-=ro',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_vim',
    pattern = { 'help' },
    command = 'setlocal textwidth=78 relativenumber',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = 'ft_vim',
    pattern = { '*.txt' },
    command = 'if &ft == "help" | wincmd J | endif',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = 'ft_vim',
    pattern = { '*.txt' },
    command = 'if &ft == "help" | 20 wincmd _ | endif',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_vim',
    pattern = { 'help' },
    command = 'nnoremap <buffer><silent> q <Cmd>bdelete<CR>',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_vim',
    pattern = { 'help', 'man' },
    command = 'nmap <buffer><silent><Leader>tc gO',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_vim',
    pattern = { 'help', 'man' },
    command = 'nmap <buffer><silent><Leader>tC :execute "normal gO" <bar> bd<CR>',
})
vim.api.nvim_create_autocmd('FileType', {
    group = 'ft_vim',
    pattern = { 'man' },
    command = 'setlocal iskeyword+=-',
})
