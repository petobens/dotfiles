-- Save and load viewoptions and previous session
vim.api.nvim_create_augroup('session', { clear = true })
vim.api.nvim_create_autocmd(
    'VimLeavePre',
    { group = 'session', command = [[execute 'mksession! ' . v:lua.udfs.session_name()]] }
)
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = 'session',
    pattern = { '*.*', 'bashrc', 'config' },
    command = 'if &previewwindow != 1 | mkview | endif',
})
-- vim.api.nvim_create_autocmd('BufWinEnter', {
-- group = 'session',
-- pattern = { '*.*', 'bashrc', 'config' },
-- command = 'if &previewwindow != 1 | silent! loadview | endif',
-- })

-- Save when losing focus
vim.api.nvim_create_augroup('focus_lost', { clear = true })
vim.api.nvim_create_autocmd(
    'FocusLost',
    { group = 'focus_lost', command = 'silent! wall' }
)

-- Disable readonly warning
vim.api.nvim_create_augroup('no_ro_warn', { clear = true })
vim.api.nvim_create_autocmd(
    'FileChangedRO',
    { group = 'no_ro_warn', command = 'set noreadonly' }
)

-- Resize splits when the Vim window is resized
vim.api.nvim_create_augroup('vim_resized', { clear = true })
vim.api.nvim_create_autocmd('VimResized', { group = 'vim_resized', command = 'wincmd =' })

-- Only show cursorline in the current window
vim.api.nvim_create_augroup('cline', { clear = true })
vim.api.nvim_create_autocmd(
    'WinLeave',
    { group = 'cline', command = 'setlocal nocursorline' }
)
vim.api.nvim_create_autocmd(
    { 'VimEnter', 'WinEnter', 'BufWinEnter' },
    { group = 'cline', command = 'setlocal cursorline' }
)

-- Create non-existing parent directory on save
vim.api.nvim_create_augroup('create_dir_before_write', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    group = 'create_dir_before_write',
    callback = function()
        udfs.mk_non_dir()
    end,
})

-- Delete trailing whitespace
vim.api.nvim_create_augroup('delete_trailing', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    group = 'delete_trailing',
    callback = function()
        udfs.delete_trailing_whitespace()
    end,
})
