local u = require('utils')

require('Comment').setup({
    mappings = false,
})

u.keymap(
    'n',
    '<Leader>cc',
    "v:count == 0 ? '<Plug>(comment_toggle_current_linewise)' : '<Plug>(comment_toggle_linewise_count)'",
    { expr = true, remap = true, replace_keycodes = false }
)
u.keymap('x', 'cc', '<Plug>(comment_toggle_linewise_visual)')
u.keymap(
    'n',
    '<Leader>cu',
    "v:count == 0 ? '<Plug>(comment_toggle_current_linewise)' : '<Plug>(comment_toggle_linewise_count)'",
    { expr = true, remap = true, replace_keycodes = false }
)
u.keymap('x', 'cu', '<Plug>(comment_toggle_linewise_visual)')
