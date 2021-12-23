local u = require('utils')
local telescope = require('telescope')

telescope.setup({
    defaults = {
        mappings = {
            i = {
                ['<ESC>'] = 'close',
                ['<C-s>'] = 'file_split',
                ['<C-j>'] = 'move_selection_next',
                ['<C-k>'] = 'move_selection_previous',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
            },
        },
        -- layout_strategy = 'bottom_pane',
        layout_config = {
            preview_width = 0.4,
        },
    },
})

-- Extensions
telescope.load_extension('z')

-- Mappings
u.keymap('n', '<Leader>ls', ':Telescope find_files<CR>')
u.keymap('n', '<Leader>lu', ':Telescope find_files cwd=..<CR>')
u.keymap('n', '<Leader>sd', ':Telescope find_files cwd=', { silent = false })
u.keymap('n', '<Leader>ig', ':Telescope live_grep<CR>')
u.keymap('n', '<Leader>rd', ':Telescope oldfiles<CR>')
u.keymap('n', '<Leader>be', ':Telescope buffers<CR>')
u.keymap('n', '<Leader>gl', ':Telescope git_commits<CR>')
u.keymap('n', '<Leader>dr', ':Telescope resume<CR>')
u.keymap('n', '<Leader>ch', ':Telescope command_history<CR>')
u.keymap(
    'n',
    '<A-z>',
    [[<cmd>lua require('telescope').extensions.z.list({cmd = {'bash', '-c', 'source /usr/share/z/z.sh && _z -l'}})<CR>]],
    { silent = false }
)
