local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local from_entry = require('telescope.from_entry')
local make_entry = require('telescope.make_entry')
local Path = require('plenary.path')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local telescope = require('telescope')
local utils = require('telescope.utils')
local u = require('utils')

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
                ['<A-n>'] = actions.cycle_previewers_next,
                ['<A-p>'] = actions.cycle_previewers_prev,
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
local previewer_acg = vim.api.nvim_create_augroup('telescope_previewer', { clear = true })
vim.api.nvim_create_autocmd('User', {
    group = previewer_acg,
    pattern = { 'TelescopePreviewerLoaded' },
    command = 'setlocal number',
})

-- Custom previewers
---- Tree Previewer
local tree_previewer = previewers.new_termopen_previewer({
    get_command = function(entry)
        return {
            'lsd',
            '-F',
            '--tree',
            '--depth=2',
            '--icon=always',
            from_entry.path(entry),
        }
    end,
    scroll_fn = function(self, direction)
        if not self.state then
            return
        end
        local bufnr = self.state.termopen_bufnr
        -- 0x05 -> <C-e>; 0x19 -> <C-y>
        local input = direction > 0 and string.char(0x05) or string.char(0x19)
        local count = math.abs(direction)
        vim.api.nvim_win_call(vim.fn.bufwinid(bufnr), function()
            vim.cmd([[normal! ]] .. count .. input)
        end)
    end,
})

-- Custom pickers
local find_dirs = function(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()
    -- TODO: change dir icon
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
    pickers
        .new(opts, {
            prompt_title = 'Find Dirs',
            finder = finders.new_oneshot_job({
                'fd',
                '--type',
                'd',
                '--follow',
                '--hidden',
                '--exclude',
                '.git',
            }, opts),
            sorter = conf.file_sorter(opts),
            results_title = opts.cwd,
            previewer = tree_previewer,
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    local entry = action_state.get_selected_entry()
                    local dir = from_entry.path(entry)
                    builtin.find_files({
                        cwd = dir,
                        results_title = dir,
                    })
                end)
                return true
            end,
        })
        :find()
end

local parent_dirs = function(opts)
    opts = opts or {}
    -- TODO: change dir icon
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

    local cwd = Path:new(utils.buffer_dir())
    pickers
        .new(opts, {
            prompt_title = 'Parents Dirs',
            finder = finders.new_table({
                results = cwd:parents(),
                entry_maker = opts.entry_maker,
            }),
            sorter = conf.file_sorter(opts),
            results_title = string.format('%s', cwd),
            previewer = tree_previewer,
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    local entry = action_state.get_selected_entry()
                    local dir = from_entry.path(entry)
                    builtin.find_files({
                        cwd = dir,
                        results_title = dir,
                    })
                end)
                return true
            end,
        })
        :find()
end

-- Helper (wrapper) functions
local function find_files_cwd()
    local buffer_dir = utils.buffer_dir()
    builtin.find_files({
        cwd = buffer_dir,
        results_title = buffer_dir,
    })
end

local function find_files_upper_cwd()
    local buffer_upperdir = string.format('%s', Path:new(utils.buffer_dir()):parent())
    builtin.find_files({
        cwd = buffer_upperdir,
        results_title = buffer_upperdir,
    })
end

local function z_with_tree_preview()
    telescope.extensions.z.list({
        cmd = { 'bash', '-c', 'source /usr/share/z/z.sh && _z -l 2>&1 | tac' },
        previewer = tree_previewer,
    })
end

local function igrep()
    local buffer_dir = utils.buffer_dir()
    builtin.live_grep({
        cwd = buffer_dir,
        results_title = buffer_dir,
    })
end

local function tasklist_cwd()
    local buffer_dir = utils.buffer_dir()
    builtin.grep_string({
        cwd = buffer_dir,
        results_title = buffer_dir,
        use_regex = true,
        search = 'TODO:\\s|FIXME:\\s',
    })
end

local function tasklist_buffer()
    local buf_name = vim.api.nvim_buf_get_name(0)
    builtin.grep_string({
        results_title = buf_name,
        use_regex = true,
        search = 'TODO:\\s|FIXME:\\s',
        search_dirs = { buf_name },
    })
end

local function gitcommits(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()
    local git_root, _ = utils.get_os_command_output({
        'git',
        'rev-parse',
        '--show-toplevel',
    }, opts.cwd)
    builtin.git_commits({
        cwd = opts.cwd,
        results_title = git_root[1],
        previewer = {
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
        },
    })
end

local function gitcommits_buffer(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()
    builtin.git_bcommits({
        cwd = opts.cwd,
        results_title = vim.api.nvim_buf_get_name(0),
        previewer = {
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
        },
    })
end

local function search_buffer()
    builtin.current_buffer_fuzzy_find({
        fuzzy = false, -- exact/regex matching/sorting
        tiebreak = function() -- sort by line number
            return false
        end,
        results_title = vim.api.nvim_buf_get_name(0),
        preview_title = 'Buffer Search Preview',
    })
end

-- Mappings
u.keymap('n', '<Leader>ls', find_files_cwd)
u.keymap('n', '<Leader>lu', find_files_upper_cwd)
u.keymap(
    'n',
    '<Leader>sd',
    '<Cmd>lcd %:p:h<CR>:Telescope find_files cwd=',
    { silent = false }
)
u.keymap('n', '<A-c>', find_dirs)
u.keymap('n', '<A-p>', parent_dirs)
u.keymap('n', '<A-z>', z_with_tree_preview)
u.keymap('n', '<Leader>ig', igrep)
u.keymap('n', '<Leader>rd', '<Cmd>Telescope oldfiles<CR>')
u.keymap('n', '<Leader>be', '<Cmd>Telescope buffers<CR>')
u.keymap('n', '<Leader>tl', tasklist_buffer)
u.keymap('n', '<Leader>tL', tasklist_cwd)
u.keymap('n', '<Leader>gl', gitcommits)
u.keymap('n', '<Leader>gL', gitcommits_buffer)
u.keymap('n', '<Leader>dl', search_buffer)
u.keymap('n', '<Leader>dr', '<Cmd>Telescope resume<CR>')
u.keymap('n', '<Leader>ch', '<Cmd>Telescope command_history<CR>')
u.keymap('n', '<Leader>sh', '<Cmd>Telescope search_history<CR>')
u.keymap('n', '<Leader>dh', '<Cmd>Telescope highlights<CR>')

-- Extensions
telescope.load_extension('fzf')
telescope.load_extension('z')
