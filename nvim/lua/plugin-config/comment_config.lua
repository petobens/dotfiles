-- luacheck:ignore 631

require('Comment').setup({
    mappings = false,
})

vim.keymap.set(
    'n',
    '<Leader>cc',
    "v:count == 0 ? '<Plug>(comment_toggle_linewise_current)' : '<Plug>(comment_toggle_linewise_count)'",
    { expr = true, remap = true, replace_keycodes = false }
)
vim.keymap.set('x', 'cc', '<Plug>(comment_toggle_linewise_visual)')
vim.keymap.set(
    'n',
    '<Leader>cu',
    "v:count == 0 ? '<Plug>(comment_toggle_linewise_current)' : '<Plug>(comment_toggle_linewise_count)'",
    { expr = true, remap = true, replace_keycodes = false }
)
vim.keymap.set('x', 'cu', '<Plug>(comment_toggle_linewise_visual)')
