local opt = require('utils').opt

-- Syntax
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
opt('o', 'iskeyword', vim.o.iskeyword .. ',:')
opt('o', 'termguicolors', true)

-- Vim behaviour
opt('o', 'autowrite', true)
opt('o', 'clipboard', 'unnamedplus')
opt('o', 'cmdwinheight', 4)
opt('o', 'confirm', true)
opt('o', 'diffopt', 'internal,filler,indent-heuristic,algorithm:histogram')
opt('o', 'foldlevelstart', 0)
opt('o', 'foldopen', vim.o.foldopen .. ',insert,jump')
opt('o', 'lazyredraw', true)
opt('o', 'modeline', false)
opt('o', 'shortmess', 'aoOtTIc')
opt('o', 'signcolumn', 'number')
opt('o', 'timeoutlen', 550)
opt('o', 'title', true)
opt('o', 'ttimeoutlen', 0)
opt('o', 'updatetime', 500)
opt('o', 'visualbell', true)

-- Appearance
-- TODO: only show cursorline in current window
opt('o', 'cursorline', true)
opt('o', 'number', true)
opt('o', 'relativenumber', true)
opt('o', 'scrolloff', 3)
opt('o', 'splitbelow', true)
opt('o', 'splitright', true)
opt('o', 'startofline', true)
opt('o', 'virtualedit', 'block,onemore')
opt('o', 'winblend', 7)

-- Backups, sessions and undo
opt('o', 'backup', true)
opt('o', 'backupdir', vim.env.CACHE .. '/tmp/backup//')
opt('o', 'directory', vim.env.CACHE .. '/tmp/swap//')
opt('o', 'undodir', vim.env.CACHE .. '/tmp/undo//')
opt('o', 'undofile', true)
opt('o', 'viewdir', vim.env.CACHE .. '/tmp/view//')
vim.opt.sessionoptions:remove('tabpages')
vim.opt.sessionoptions:append({'winpos', 'resize'})
vim.cmd [[
augroup session
    au!
    au BufWinLeave {*.*,vimrc,vimrc_min,bashrc,config}
        \ if &previewwindow != 1 | mkview | endif
    au BufWinEnter {*.*,vimrc,vimrc_min,bashrc,config}
        \ if &previewwindow != 1 | silent! loadview | endif
augroup END
]]

-- Search, matching and substitution
opt('o', 'gdefault', true)
opt('o', 'ignorecase', true)
opt('o', 'matchtime', 1)
opt('o', 'showmatch', true)
opt('o', 'smartcase', true)

-- Tab and indent
opt('o', 'autoindent', true)
opt('o', 'breakindent', true)
opt('o', 'colorcolumn', '+1')
opt('o', 'expandtab', true)
opt('o', 'linebreak', true)
opt('o', 'listchars', 'tab:▸\\ ,eol:¬,trail:•,extends:»,precedes:«,nbsp:␣')
opt('o', 'shiftround', true)
opt('o', 'shiftwidth', 4)
opt('o', 'smartcase', true)
opt('o', 'softtabstop', 4)
opt('o', 'tabstop', 4)
opt('o', 'textwidth', 80)
opt('o', 'whichwrap', vim.o.whichwrap .. ',<,>,h,l,[,]')
opt('o', 'wrap', true)

-- Wildmenu
opt('o', 'wildignore', '*~,*.o,*.obj,*.dll,*.dat,*.swp,*.zip,*.exe,*.DS_Store,*.out,*.toc')
opt('o', 'wildignorecase', true)
opt('o', 'wildmode', 'longest:full,full')

-- Misc
opt('o', 'spelllang', 'en,es')
-- TODO: spellfile
