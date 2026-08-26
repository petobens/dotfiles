require('sniprun').setup({})

vim.keymap.set(
    { 'n', 'v' },
    '<Leader>br',
    '<Plug>SnipRun',
    { desc = '[B]lock [r]un with SnipRun' }
)
vim.keymap.set(
    'n',
    '<Leader>bc',
    '<Plug>SnipClose',
    { desc = '[B]lock [c]lose: remove SnipRun virtual text' }
)
vim.keymap.set(
    'n',
    '<Leader>bw',
    '<Plug>SnipReset',
    { desc = '[B]lock [w]ipe: reset SnipRun' }
)
