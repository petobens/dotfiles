require('sniprun').setup({})

vim.keymap.set({ 'n', 'v' }, '<Leader>br', '<Plug>SnipRun')
vim.keymap.set('n', '<Leader>bc', '<Plug>SnipClose')
vim.keymap.set('n', '<Leader>bw', '<Plug>SnipReset')
