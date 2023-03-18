-- Save and load viewoptions and previous session
local session_acg = vim.api.nvim_create_augroup('session', { clear = true })
vim.api.nvim_create_autocmd('VimLeavePre', {
    group = session_acg,
    command = [[execute 'mksession! ' . v:lua.udfs.session_name()]],
})
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = session_acg,
    pattern = { '*.*', 'bashrc', 'bash_profile', 'config' },
    command = 'if &previewwindow != 1 | mkview | endif',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = session_acg,
    pattern = { '*.*', 'bashrc', 'bash_profile', 'config' },
    command = 'if &previewwindow != 1 | silent! loadview | endif',
})

-- Save when losing focus
vim.api.nvim_create_autocmd('FocusLost', {
    group = vim.api.nvim_create_augroup('focus_lost', { clear = true }),
    command = 'silent! wall',
})

-- Disable readonly warning
vim.api.nvim_create_autocmd('FileChangedRO', {
    group = vim.api.nvim_create_augroup('no_ro_warn', { clear = true }),
    command = 'set noreadonly',
})

-- Send cwd to tmux splits (see https://github.com/neovim/neovim/issues/21771)
vim.api.nvim_create_autocmd({ 'DirChanged' }, {
    group = vim.api.nvim_create_augroup('cwd_tmux', { clear = true }),
    command = [[call chansend(v:stderr, printf("\033]7;%s\033", v:event.cwd))]],
})

-- Resize splits when the Vim window is resized
vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('vim_resized', { clear = true }),
    command = 'wincmd =',
})

-- Only show cursorline in the current window
local cline_acg = vim.api.nvim_create_augroup('cline', { clear = true })
vim.api.nvim_create_autocmd(
    'WinLeave',
    { group = cline_acg, command = 'setlocal nocursorline' }
)
vim.api.nvim_create_autocmd(
    { 'VimEnter', 'WinEnter', 'BufWinEnter' },
    { group = cline_acg, command = 'setlocal cursorline' }
)

-- Create non-existing parent directory on save
vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('create_dir_before_write', { clear = true }),
    callback = function()
        udfs.mk_non_dir()
    end,
})

-- Delete trailing whitespace
vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('delete_trailing', { clear = true }),
    callback = function()
        udfs.delete_trailing_whitespace()
    end,
})

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd({ 'TextYankPost' }, {
    group = vim.api.nvim_create_augroup('hl_yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank({ higroup = 'Visual', timeout = 300 })
    end,
})
