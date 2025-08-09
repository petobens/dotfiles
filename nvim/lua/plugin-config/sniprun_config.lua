require('sniprun').setup({})

vim.keymap.set(
    { 'n', 'v' },
    '<Leader>br',
    '<Plug>SnipRun',
    { desc = 'Run block code with SnipRun' }
)
vim.keymap.set(
    'n',
    '<Leader>bc',
    '<Plug>SnipClose',
    { desc = 'Close SnipRun block virtual text' }
)
vim.keymap.set(
    'n',
    '<Leader>bw',
    '<Plug>SnipReset',
    { desc = 'Reset/Wipe SnipRun block' }
)
