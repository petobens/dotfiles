local action_layout = require('telescope.actions.layout')
local action_set = require('telescope.actions.set')
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
local sorters = require('telescope.sorters')
local telescope = require('telescope')
local u = require('utils')
local utils = require('telescope.utils')

local tree_api = require('nvim-tree.api').tree
local node_api = require('nvim-tree.api').node

_G.TelescopeConfig = {}

-- Custom previewers
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
    title = 'Tree Previewer',
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

-- Custom sorters
local preserve_order_sorter = function(opts)
    -- From: https://github.com/antoinemadec/telescope-git-browse.nvim/blob/main/lua/telescope/_extensions/git_browse/sorters.lua
    opts = opts or {}
    local fzy = opts.fzy_mod or require('telescope.algos.fzy')

    return sorters.Sorter:new({
        scoring_function = function(_, prompt, line, _)
            if not fzy.has_match(prompt, line) then
                return -1
            end
            return 1
        end,

        highlighter = function(_, prompt, display)
            return fzy.positions(prompt, display)
        end,
    })
end

-- Custom pickers
function _G.TelescopeConfig.find_dirs(opts)
    opts = opts or {}
    if opts.cwd == nil then
        opts.cwd = utils.buffer_dir()
    end
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
                '--strip-cwd-prefix',
                '--exclude',
                '.git',
            }, opts),
            sorter = conf.file_sorter(opts),
            results_title = opts.cwd,
            previewer = tree_previewer,
            attach_mappings = function()
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

function _G.TelescopeConfig.parent_dirs(opts)
    opts = opts or {}
    -- TODO: change dir icon
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

    local cwd = opts.starting_dir
    if opts.starting_dir == nil then
        cwd = Path:new(utils.buffer_dir())
    end
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
            attach_mappings = function()
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

function _G.TelescopeConfig.bookmark_dirs(opts)
    opts = opts or {}
    -- TODO: change dir icon
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
    pickers
        .new(opts, {
            prompt_title = 'Directory Bookmarks',
            finder = finders.new_table({
                results = {
                    '/home/pedro/git-repos/private/dotfiles/',
                    '/home/pedro/OneDrive/mutt/ops/',
                    '/home/pedro/git-repos/work/',
                    '/home/pedro/Desktop/',
                    '/home/pedro/.local/share/nvim/site/pack/packer/start',
                },
                entry_maker = opts.entry_maker,
            }),
            sorter = conf.file_sorter(opts),
            previewer = tree_previewer,
            attach_mappings = function()
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
function _G.TelescopeConfig.find_files_cwd(opts)
    local buffer_dir = utils.buffer_dir()
    opts = opts or {}
    opts.cwd = buffer_dir
    opts.results_title = buffer_dir
    builtin.find_files(opts)
end

local function find_files_upper_cwd()
    local buffer_upperdir = string.format('%s', Path:new(utils.buffer_dir()):parent())
    builtin.find_files({
        cwd = buffer_upperdir,
        results_title = buffer_upperdir,
    })
end

function _G.TelescopeConfig.z_with_tree_preview(opts)
    opts = opts or {}
    opts.cmd = { 'bash', '-c', 'source /usr/share/z/z.sh && _z -l 2>&1 | tac' }
    opts.previewer = tree_previewer
    telescope.extensions.z.list(opts)
end

local function igrep(dir, start_text, extra_args)
    local buffer_dir = dir or utils.buffer_dir()
    builtin.live_grep({
        cwd = buffer_dir,
        results_title = buffer_dir,
        default_text = start_text or '',
        additional_args = extra_args or {},
    })
end

local function igrep_git_root()
    local git_root, _ = utils.get_os_command_output({
        'git',
        'rev-parse',
        '--show-toplevel',
    }, utils.buffer_dir())
    igrep(git_root[1])
end

local function igrep_open_buffers()
    builtin.live_grep({ grep_open_files = true })
end

local function rgrep(extra_args)
    vim.ui.input({ prompt = 'Grep dir: ', completion = 'dir' }, function(dir)
        -- FIXME: no C-c exit: https://github.com/neovim/neovim/pull/21006
        if not dir then
            return
        end
        local opts = {
            cwd = dir,
            search_dirs = { dir },
            results_title = dir,
            additional_args = extra_args or {},
        }
        ---@diagnostic disable-next-line: assign-type-mismatch
        local type_filter = vim.fn.input('Type Filter: ', '')
        if type_filter ~= '' then
            opts.type_filter = type_filter
        end
        builtin.live_grep(opts)
    end)
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
        sorter = preserve_order_sorter(opts),
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
        sorter = preserve_order_sorter(opts),
    })
end

local function search_buffer(start_text)
    builtin.current_buffer_fuzzy_find({
        fuzzy = false, -- exact/regex matching/sorting
        tiebreak = function() -- sort by line number
            return false
        end,
        results_title = vim.api.nvim_buf_get_name(0),
        preview_title = 'Buffer Search Preview',
        default_text = start_text or '',
    })
end

local function keymaps()
    builtin.keymaps({ fuzzy = false })
end

local function spell_suggest()
    builtin.spell_suggest({ fuzzy = false })
end

local function lsp_doc_symbols()
    builtin.lsp_document_symbols({
        results_title = vim.api.nvim_buf_get_name(0),
        preview_title = 'LSP Document Symbols Preview',
    })
end

-- Custom actions
local transform_mod = require('telescope.actions.mt').transform_mod
local custom_actions = transform_mod({
    -- Context split
    context_split = function(prompt_bufnr)
        local split = 'new'
        ---@diagnostic disable-next-line: undefined-field
        if vim.fn.winwidth(vim.fn.winnr('#')) > 2 * (vim.go.textwidth or 80) then
            split = 'vnew'
        end
        return action_set.edit(prompt_bufnr, split)
    end,
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
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry().value
        vim.api.nvim_feedkeys('/' .. selection, 'n', true)
    end,
    -- Fix all spell mistakes in buffer
    spell_fix_all = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        vim.cmd('silent normal! mz')
        vim.cmd('silent normal! ' .. entry.index .. 'z=')
        -- Use pcall to gracefully catch E753 when there are no more words to replace
        ---@diagnostic disable-next-line: assign-type-mismatch
        pcall(vim.cmd, 'spellrepall')
        vim.cmd('silent normal! `z')
    end,
    -- Show containing files of entry dir
    entry_find_files = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local p = Path:new(from_entry.path(entry))
        if p:is_file() then
            p = p:parent()
        end
        local dir = tostring(p)
        builtin.find_files({
            cwd = dir,
            results_title = dir,
        })
    end,
    -- Show containing dir of entry
    entry_find_dir = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local p = Path:new(from_entry.path(entry))
        if p:is_file() then
            p = p:parent()
        end
        _G.TelescopeConfig.find_dirs({ cwd = tostring(p) })
    end,
    -- Show parent dirs of entry
    entry_parent_dirs = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local p = Path:new(from_entry.path(entry))
        if p:is_file() then
            p = p:parent()
        end
        _G.TelescopeConfig.parent_dirs({ starting_dir = p })
    end,
    -- Live (interactive) grep in entry dir
    entry_igrep = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local p = Path:new(from_entry.path(entry))
        if p:is_file() then
            p = p:parent()
        end
        igrep(tostring(p))
    end,
    -- Undo (restore) previous picker
    undo_picker = function()
        builtin.resume()
    end,
    -- Open in nvimtree
    open_nvimtree = function(prompt_bufnr)
        local is_dir = true
        local fname = nil

        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local p = Path:new(from_entry.path(entry))
        if p:is_file() then
            is_dir = false
            fname = vim.fn.fnamemodify(tostring(p), ':t')
            p = p:parent()
        end

        vim.cmd('NvimTreeOpen')
        vim.cmd('sleep 3m') -- we seem to need this to allow focus
        tree_api.change_root(tostring(p))
        if not is_dir then
            tree_api.find_file(fname)
        else
            node_api.navigate.sibling.first()
        end
    end,
})
-- Store custom actions to be used elsewhere
_G.TelescopeConfig.custom_actions = custom_actions

-- Autocmds
local prompt_acg = vim.api.nvim_create_augroup('telescope_prompt', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
    group = prompt_acg,
    pattern = { 'TelescopePrompt' },
    command = 'setlocal nocursorline',
})
vim.api.nvim_create_autocmd('FileType', {
    group = prompt_acg,
    pattern = { 'TelescopePrompt' },
    command = 'nnoremap <buffer><silent> H ^lll', -- to account for search symbol
})
vim.api.nvim_create_autocmd('FileType', {
    group = prompt_acg,
    pattern = { 'TelescopePrompt' },
    command = 'nnoremap <buffer><silent> L $',
})
vim.api.nvim_create_autocmd('FileType', {
    group = prompt_acg,
    pattern = { 'TelescopePrompt' },
    command = 'inoremap <buffer><silent> <C-l> <C-o>l',
})
local previewer_acg = vim.api.nvim_create_augroup('telescope_previewer', { clear = true })
vim.api.nvim_create_autocmd('User', {
    group = previewer_acg,
    pattern = { 'TelescopePreviewerLoaded' },
    command = 'setlocal number',
})

-- Setup
telescope.setup({
    defaults = {
        prompt_prefix = '   ',
        multi_icon = ' ',
        winblend = 7,
        results_title = false,
        color_devicons = true,
        file_ignore_patterns = { 'doc/', 'venv/', '__pycache__/' },
        layout_strategy = 'bottom_pane',
        layout_config = {
            prompt_position = 'bottom',
            height = 20,
            preview_width = 0.45,
        },
        cache_picker = { num_pickers = 3 },
        path_display = { truncate = 1 },
        mappings = {
            i = {
                ['<ESC>'] = 'close',
                ['<Tab>'] = 'select_default',
                ['<C-s>'] = 'file_split',
                ['<C-j>'] = 'move_selection_next',
                ['<C-k>'] = 'move_selection_previous',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
                ['<A-v>'] = action_layout.toggle_preview,
                ['<A-n>'] = actions.cycle_previewers_next,
                ['<C-space>'] = actions.toggle_selection
                    + actions.move_selection_previous,
                ['<C-y>'] = custom_actions.yank,
                ['<C-t>'] = custom_actions.entry_find_files,
                ['<A-c>'] = custom_actions.entry_find_dir,
                ['<A-f>'] = custom_actions.open_nvimtree,
                ['<A-p>'] = custom_actions.entry_parent_dirs,
                ['<A-g>'] = custom_actions.entry_igrep,
                ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
                ['<A-q>'] = actions.send_to_qflist + actions.open_qflist,
                ['<A-u>'] = custom_actions.undo_picker,
                ['<C-/>'] = 'which_key',
            },
            n = {
                ['q'] = 'close',
                ['<C-c>'] = 'close',
                ['<Tab>'] = 'select_default',
                ['<C-s>'] = 'file_split',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
                ['<A-v>'] = action_layout.toggle_preview,
                ['<A-n>'] = actions.cycle_previewers_next,
                ['<space>'] = actions.toggle_selection + actions.move_selection_previous,
                ['<C-space>'] = actions.toggle_selection
                    + actions.move_selection_previous,
                ['<C-y>'] = custom_actions.yank,
                ['<C-t>'] = custom_actions.entry_find_files,
                ['<A-c>'] = custom_actions.entry_find_dir,
                ['<A-f>'] = custom_actions.open_nvimtree,
                ['<A-p>'] = custom_actions.entry_parent_dirs,
                ['<A-g>'] = custom_actions.entry_igrep,
                ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
                ['<A-q>'] = actions.send_to_qflist + actions.open_qflist,
                ['<A-u>'] = custom_actions.undo_picker,
                ['?'] = 'which_key',
            },
        },
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--trim',
        },
    },
    pickers = {
        buffers = {
            sort_mru = true,
            mappings = {
                i = {
                    ['<C-o>'] = custom_actions.context_split,
                },
            },
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
                '--strip-cwd-prefix',
                '--exclude',
                '.git',
            },
        },
        live_grep = {
            path_display = { shorten = 3 },
            mappings = {
                i = {
                    ['<C-space>'] = actions.toggle_selection
                        + actions.move_selection_previous,
                },
            },
        },
        lsp_document_symbols = {
            mappings = {
                i = {
                    ['<C-x>'] = actions.complete_tag,
                },
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
        spell_suggest = {
            mappings = {
                i = {
                    ['<C-o>'] = custom_actions.spell_fix_all,
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
        recent_files = {
            -- FIXME: Not working
            path_display = function(_, path)
                local p = Path:new(path)
                return p.normalize(p)
            end,
        },
    },
})

-- Mappings
u.keymap('n', '<Leader>ls', _G.TelescopeConfig.find_files_cwd)
u.keymap('n', '<Leader>lu', find_files_upper_cwd)
u.keymap(
    'n',
    '<Leader>sd',
    '<Cmd>lcd %:p:h<CR>:Telescope find_files cwd=',
    { silent = false }
)
u.keymap('n', '<C-t>', _G.TelescopeConfig.find_files_cwd)
u.keymap('n', '<A-c>', _G.TelescopeConfig.find_dirs)
u.keymap('n', '<A-p>', _G.TelescopeConfig.parent_dirs)
u.keymap('n', '<A-z>', _G.TelescopeConfig.z_with_tree_preview)
u.keymap('n', '<Leader>bm', _G.TelescopeConfig.bookmark_dirs)
u.keymap('n', '<Leader>ig', igrep)
u.keymap('n', '<Leader>iG', function()
    igrep(nil, nil, { '--no-ignore-vcs' })
end)
u.keymap('n', '<Leader>ir', igrep_git_root)
u.keymap('n', '<Leader>io', igrep_open_buffers)
u.keymap('n', '<A-g>', igrep)
u.keymap('n', '<Leader>rg', rgrep)
u.keymap('n', '<Leader>rG', function()
    rgrep({ '--no-ignore-vcs' })
end)
u.keymap({ 'n', 'v' }, '<Leader>dg', function()
    igrep(nil, u.get_selection())
end)
u.keymap(
    'n',
    '<Leader>rd',
    [[<Cmd>lua require('telescope').extensions.recent_files.pick()<CR>]]
)
u.keymap('n', '<Leader>be', '<Cmd>Telescope buffers<CR>')
u.keymap('n', '<Leader>tl', tasklist_buffer)
u.keymap('n', '<Leader>tL', tasklist_cwd)
u.keymap('n', '<Leader>gl', gitcommits)
u.keymap('n', '<Leader>gL', gitcommits_buffer)
u.keymap('n', '<Leader>dl', search_buffer)
u.keymap({ 'n', 'v' }, '<Leader>dw', function()
    search_buffer(u.get_selection())
end)
u.keymap('n', '<Leader>dr', '<Cmd>Telescope resume<CR>')
u.keymap('n', '<Leader>ch', '<Cmd>Telescope command_history<CR>')
u.keymap('n', '<Leader>sh', '<Cmd>Telescope search_history<CR>')
u.keymap('n', '<Leader>dh', '<Cmd>Telescope help_tags<CR>')
u.keymap('n', '<Leader>th', '<Cmd>Telescope highlights<CR>')
u.keymap('n', '<Leader>tm', '<Cmd>Telescope marks<CR>')
u.keymap('n', '<Leader>me', keymaps)
u.keymap('n', '<Leader>sg', spell_suggest)
u.keymap('n', '<Leader>tp', '<Cmd>Telescope pickers<CR>')
u.keymap('n', '<Leader>te', lsp_doc_symbols)

-- Extensions
telescope.load_extension('recent_files')
telescope.load_extension('fzf')
telescope.load_extension('luasnip')
telescope.load_extension('z')
