-- Save and load viewoptions and previous session
local session_acg = vim.api.nvim_create_augroup('session', { clear = true })
vim.api.nvim_create_autocmd('VimLeavePre', {
    group = session_acg,
    command = [[execute 'mksession! ' . v:lua.udfs.session_name()]],
})
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = session_acg,
    pattern = { '*.*', 'bashrc', 'config' },
    command = 'if &previewwindow != 1 | mkview | endif',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = session_acg,
    pattern = { '*.*', 'bashrc', 'config' },
    command = 'if &previewwindow != 1 | silent! loadview | endif',
})

-- Save when losing focus
local focus_acg = vim.api.nvim_create_augroup('focus_lost', { clear = true })
vim.api.nvim_create_autocmd('FocusLost', { group = focus_acg, command = 'silent! wall' })

-- Disable readonly warning
local noro_acg = vim.api.nvim_create_augroup('no_ro_warn', { clear = true })
vim.api.nvim_create_autocmd(
    'FileChangedRO',
    { group = noro_acg, command = 'set noreadonly' }
)

-- Resize splits when the Vim window is resized
local vim_resized_acg = vim.api.nvim_create_augroup('vim_resized', { clear = true })
vim.api.nvim_create_autocmd(
    'VimResized',
    { group = vim_resized_acg, command = 'wincmd =' }
)

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
local create_dir_before_write_acg =
    vim.api.nvim_create_augroup('create_dir_before_write', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    group = create_dir_before_write_acg,
    callback = function()
        udfs.mk_non_dir()
    end,
})

-- Delete trailing whitespace
local delete_trailing_acg =
    vim.api.nvim_create_augroup('delete_trailing', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    group = delete_trailing_acg,
    callback = function()
        udfs.delete_trailing_whitespace()
    end,
})
