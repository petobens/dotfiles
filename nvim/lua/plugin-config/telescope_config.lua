local u = require('utils')
local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup({
    defaults = {
        prompt_prefix = '❯ ',
        multi_icon = '  ',
        winblend = 7,
        color_devicons = true,
        file_ignore_patterns = { 'doc/', 'venv/' },
        mappings = {
            i = {
                ['<ESC>'] = 'close',
                ['<C-s>'] = 'file_split',
                ['<C-j>'] = 'move_selection_next',
                ['<C-k>'] = 'move_selection_previous',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
                ['<C-space>'] = actions.toggle_selection
                    + actions.move_selection_previous,
            },
        },
        -- layout_strategy = 'bottom_pane',
        layout_config = {
            preview_width = 0.4,
        },
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
        },
    },
})

-- Mappings
u.keymap('n', '<Leader>ls', '<Cmd>lcd %:p:h<CR><Cmd>Telescope find_files<CR>')
u.keymap('n', '<Leader>lu', '<Cmd>lcd %:p:h<CR><Cmd>Telescope find_files cwd=..<CR>')
u.keymap(
    'n',
    '<Leader>sd',
    '<Cmd>lcd %:p:h<CR>:Telescope find_files cwd=',
    { silent = false }
)
u.keymap('n', '<Leader>ig', '<Cmd>lcd %:p:h<CR><Cmd>Telescope live_grep<CR>')
u.keymap('n', '<Leader>rd', '<Cmd>Telescope oldfiles<CR>')
u.keymap('n', '<Leader>be', '<Cmd>Telescope buffers<CR>')
u.keymap('n', '<Leader>gl', '<Cmd>Telescope git_commits<CR>')
u.keymap('n', '<Leader>gL', '<Cmd>Telescope git_bcommits<CR>')
u.keymap('n', '<Leader>dr', '<Cmd>Telescope resume<CR>')
u.keymap('n', '<Leader>ch', '<Cmd>Telescope command_history<CR>')
u.keymap(
    'n',
    '<A-z>',
    [[<cmd>lua require('telescope').extensions.z.list({cmd = {'bash', '-c', 'source /usr/share/z/z.sh && _z -l'}})<CR>]],
    { silent = false }
)

-- Extensions
telescope.load_extension('fzf')
telescope.load_extension('z')
