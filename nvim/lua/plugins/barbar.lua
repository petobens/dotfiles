local u = require('utils')

vim.g.bufferline = {
    animation = false,
    auto_hide = true, -- don't show with single buffer
    tabpages = true,
    closable = false, -- hide close button
    clickable = false,
    exclude_ft = nil,
    exclude_name = nil,
    icons = 'both',  -- show numbers and icons
    icon_custom_colors = false,
    icon_separator_active = '▎',
    icon_separator_inactive = '▎',
    icon_close_tab_modified = '●',
    insert_at_end = true,
    insert_at_start = false,
    maximum_length = 10,
    maximum_padding = 1,
}


u.keymap('n', '<C-n>', ':BufferNext<CR>')
u.keymap('n', '<C-p>', ':BufferPrevious<CR>')
u.keymap('n', '<A-p>', ':BufferMovePrevious<CR>')
u.keymap('n', '<A-n>', ':BufferMoveNext<CR>')
u.keymap('n', '<Leader>1', ':BufferGoto 1<CR>')
u.keymap('n', '<Leader>2', ':BufferGoto 2<CR>')
u.keymap('n', '<Leader>3', ':BufferGoto 3<CR>')
u.keymap('n', '<Leader>4', ':BufferGoto 4<CR>')
u.keymap('n', '<Leader>5', ':BufferGoto 5<CR>')
u.keymap('n', '<Leader>6', ':BufferGoto 6<CR>')
u.keymap('n', '<Leader>7', ':BufferGoto 7<CR>')
u.keymap('n', '<Leader>8', ':BufferGoto 8<CR>')
u.keymap('n', '<Leader>9', ':BufferGoto 9<CR>')
