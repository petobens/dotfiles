local u = require('utils')
local telescope = require('telescope')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- Custom actions
local transform_mod = require('telescope.actions.mt').transform_mod
local custom_actions = transform_mod({
    -- Yank
    yank = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        vim.fn.setreg('+', action_state.get_selected_entry().value)
    end,
    -- Open git commit using Fugitive
    fugitive_open = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        vim.cmd(string.format([[execute 'e' FugitiveFind("%s")]], commit_sha))
    end,
    fugitive_split = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        vim.cmd(string.format([[execute 'split' FugitiveFind("%s")]], commit_sha))
    end,
    fugitive_vsplit = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        vim.cmd(string.format([[execute 'vsplit' FugitiveFind("%s")]], commit_sha))
    end,
    -- Search history
    edit_search_line = function(prompt_bufnr)
        local selection = action_state.get_selected_entry().value
        actions.close(prompt_bufnr)
        vim.api.nvim_feedkeys('/' .. selection, 'n', true)
    end,
})

-- Setup
telescope.setup({
    defaults = {
        prompt_prefix = '   ',
        multi_icon = ' ',
        winblend = 7,
        results_title = false,
        color_devicons = true,
        file_ignore_patterns = { 'doc/', 'venv/' },
        layout_strategy = 'bottom_pane',
        layout_config = {
            prompt_position = 'bottom',
            height = 20,
            preview_width = 0.45,
        },
        mappings = {
            i = {
                ['<ESC>'] = 'close',
                ['<Tab>'] = 'select_default',
                ['<C-s>'] = 'file_split',
                ['<C-j>'] = 'move_selection_next',
                ['<C-k>'] = 'move_selection_previous',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
                ['<C-space>'] = actions.toggle_selection
                    + actions.move_selection_previous,
                ['<C-y>'] = custom_actions.yank,
            },
            n = { ['q'] = 'close' },
        },
    },
    pickers = {
        buffers = {
            sort_mru = true,
        },
        command_history = {
            mappings = {
                i = {
                    ['<Tab>'] = actions.edit_command_line,
                },
            },
        },
        find_files = {
            find_command = {
                'fd',
                '--type',
                'f',
                '--follow',
                '--hidden',
                '--exclude',
                '.git',
            },
        },
        git_commits = {
            mappings = {
                i = {
                    ['<CR>'] = custom_actions.fugitive_open,
                    ['<C-s>'] = custom_actions.fugitive_split,
                    ['<C-v>'] = custom_actions.fugitive_vsplit,
                    ['<C-o>'] = actions.git_checkout,
                },
            },
        },
        git_bcommits = {
            mappings = {
                i = {
                    ['<CR>'] = custom_actions.fugitive_open,
                    ['<C-s>'] = custom_actions.fugitive_split,
                    ['<C-v>'] = custom_actions.fugitive_vsplit,
                    ['<C-o>'] = actions.git_checkout,
                },
            },
        },
        search_history = {
            mappings = {
                i = {
                    ['<Tab>'] = custom_actions.edit_search_line,
                },
            },
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

-- Autocmds
local prompt_acg = vim.api.nvim_create_augroup('telescope_prompt', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = prompt_acg,
    pattern = { 'TelescopePrompt' },
    command = 'setlocal nocursorline',
})

-- Mappings
u.keymap(
    'n',
    '<Leader>ls',
    '<Cmd>lcd %:p:h<CR><Cmd>lua require("telescope.builtin").find_files({ prompt_title = string.format("Find Files (%s)", vim.loop.cwd()) })<CR>'
)
u.keymap('n', '<Leader>lu', '<Cmd>lcd %:p:h<CR><Cmd>Telescope find_files cwd=..<CR>')
u.keymap(
    'n',
    '<Leader>sd',
    '<Cmd>lcd %:p:h<CR>:Telescope find_files cwd=',
    { silent = false }
)
u.keymap(
    'n',
    '<Leader>ig',
    '<Cmd>lcd %:p:h<CR><Cmd>lua require("telescope.builtin").live_grep({ prompt_title = string.format("Live Grep (%s)", vim.loop.cwd()) })<CR>'
)
u.keymap('n', '<Leader>rd', '<Cmd>Telescope oldfiles<CR>')
u.keymap('n', '<Leader>be', '<Cmd>Telescope buffers<CR>')
u.keymap('n', '<Leader>gl', '<Cmd>Telescope git_commits<CR>')
u.keymap('n', '<Leader>gL', '<Cmd>lcd %:p:h<CR><Cmd>Telescope git_bcommits<CR>')
u.keymap('n', '<Leader>dr', '<Cmd>Telescope resume<CR>')
u.keymap('n', '<Leader>ch', '<Cmd>Telescope command_history<CR>')
u.keymap('n', '<Leader>sh', '<Cmd>Telescope search_history<CR>')
u.keymap('n', '<Leader>th', '<Cmd>Telescope highlights<CR>')
u.keymap(
    'n',
    '<A-z>',
    [[<cmd>lua require('telescope').extensions.z.list({cmd = {'bash', '-c', 'source /usr/share/z/z.sh && _z -l 2>&1'}})<CR>]],
    { silent = false }
)

-- Extensions
telescope.load_extension('fzf')
telescope.load_extension('z')
