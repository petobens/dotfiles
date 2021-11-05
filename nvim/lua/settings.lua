local opt = require('utils').opt

-- Vim behaviour
opt('o', 'clipboard', 'unnamedplus')
opt('o', 'modeline', false)
opt('o', 'title', true)
opt('o', 'cmdwinheight', 4)
opt('o', 'lazyredraw', true)
opt('o', 'visualbell', true)
opt('o', 'shortmess', 'aoOtTIc')
opt('o', 'confirm', true)
opt('o', 'updatetime', 500)
opt('o', 'timeoutlen', 550)
opt('o', 'ttimeoutlen', 0)
opt('o', 'foldlevelstart', 0)
opt('o', 'foldopen', vim.o.foldopen..',insert,jump')
opt('o', 'signcolumn', 'number')
opt('o', 'diffopt', 'internal,filler,indent-heuristic,algorithm:histogram')

-- Appearance
opt('o', 'number', true)
opt('o', 'relativenumber', true)
-- TODO: show cursorline only on the current window
opt('o', 'cursorline', true)
opt('o', 'virtualedit', 'block,onemore')
opt('o', 'startofline', true)
opt('o', 'scrolloff', 3)
opt('o', 'splitright', true)
opt('o', 'splitbelow', true)
opt('o', 'winblend', 7)

-- Read write
opt('o', 'autowrite', true)

-- Syntax
opt('o', 'termguicolors', true)
opt('o', 'iskeyword', vim.o.iskeyword..',:')

-- TODO backups and undo


-- Search, matching and substitution
opt('o', 'ignorecase', true)
opt('o', 'smartcase', true)
-- opt('o', 'hlsearch', true)
opt('o', 'gdefault', true)
opt('o', 'showmatch', true)
opt('o', 'matchtime', 1)

-- Tab and indent
opt('o', 'smartcase', true)
opt('o', 'tabstop', 4)
opt('o', 'shiftwidth', 4)
opt('o', 'softtabstop', 4)
opt('o', 'expandtab', true)
opt('o', 'shiftround', true)
opt('o', 'wrap', true)
opt('o', 'linebreak', true)
opt('o', 'breakindent', true)
opt('o', 'autoindent', true)
opt('o', 'textwidth', 80)
opt('o', 'colorcolumn', '+1')
opt('o', 'whichwrap', vim.o.whichwrap..',<,>,h,l,[,]')
opt('o', 'listchars', 'tab:▸\\ ,eol:¬,trail:•,extends:»,precedes:«,nbsp:␣')

-- Wildmenu
opt('o', 'wildignorecase', true)
opt('o', 'wildmode', 'longest:full,full')
opt('o', 'wildignore', '*~,*.o,*.obj,*.dll,*.dat,*.swp,*.zip,*.exe,*.DS_Store,*.out,*.toc')

-- Misc
opt('o', 'spelllang', 'en,es')
-- TODO: spellfile
