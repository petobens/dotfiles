-- Save and load viewoptions and previous session
vim.cmd([[
augroup session
    au!
    au VimLeavePre * execute 'mksession! ' . v:lua.udfs.session_name()
    au BufWinLeave {*.*,vimrc,vimrc_min,bashrc,config}
        \ if &previewwindow != 1 | mkview | endif
    "au BufWinEnter {*.*,vimrc,vimrc_min,bashrc,config}
    "    \ if &previewwindow != 1 | silent! loadview | endif
augroup END
]])

-- Save when losing focus
vim.cmd([[
augroup focus_lost
    au!
    au FocusLost * silent! wall
augroup END
]])

-- Disable readonly warning
vim.cmd([[
augroup no_ro_warn
    au!
    au FileChangedRO * set noreadonly
augroup END
]])

-- Resize splits when the Vim window is resized
vim.cmd([[
augroup vim_resized
    au!
    au VimResized * :wincmd =
augroup END
]])

-- Only show cursorline in the current window
vim.cmd([[
augroup cline
    au!
    au WinLeave * setlocal nocursorline
    au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
augroup END
]])

-- Create non-existing parent directory on save
vim.cmd([[
augroup create_dir_before_write
    au!
    au BufWritePre * call v:lua.udfs.mk_non_dir()
augroup END
]])

-- Delete trailing whitespace
vim.cmd([[
augroup create_dir_before_write
    au!
    au BufWritePre * call v:lua.udfs.delete_trailing_whitespace()
augroup END
]])
