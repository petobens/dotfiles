local opt = require('utils').opt

opt('wo', 'number', true)
opt('wo', 'relativenumber', true)
opt('o', 'splitright', true)
opt('o', 'clipboard', 'unnamedplus')

-- Tab settings
opt('o', 'tabstop', 4)
opt('o', 'shiftwidth', 4)
opt('o', 'softtabstop', 4)
opt('o', 'expandtab', true)
opt('o', 'shiftround', true)


opt('o', 'scrolloff', 3)

opt('o', 'wrap', true)
opt('o', 'linebreak', true)
opt('o', 'breakindent', true)
opt('o', 'autoindent', true)
