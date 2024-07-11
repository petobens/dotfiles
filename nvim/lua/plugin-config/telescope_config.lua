local action_layout = require('telescope.actions.layout')
local action_set = require('telescope.actions.set')
local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local from_entry = require('telescope.from_entry')
local layout_strategies = require('telescope.pickers.layout_strategies')
local node_api = require('nvim-tree.api').node
local Path = require('plenary.path')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local sorters = require('telescope.sorters')
local telescope = require('telescope')
local tree_api = require('nvim-tree.api').tree
local u = require('utils')
local utils = require('telescope.utils')

_G.TelescopeConfig = {}

-- Custom Layout
layout_strategies.bpane = function(picker, max_columns, max_lines, layout_config)
    local layout =
        layout_strategies.bottom_pane(picker, max_columns, max_lines, layout_config)
    layout.prompt.width = layout.results.width
    layout.prompt.col = layout.results.col
    if layout.preview then
        layout.preview.height = layout.preview.height + 2
    end
    return layout
end

-- Custom previewers
local function scroll_less(self, direction)
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
end

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
    scroll_fn = scroll_less,
})

local delta = previewers.new_termopen_previewer({
    get_command = function(entry)
        return {
            'git',
            '-c',
            'core.pager=delta',
            '-c',
            'delta.paging=never',
            '-c',
            'delta.side-by-side=false',
            'show',
            entry.value .. '^!',
            '--',
            entry.current_file,
        }
    end,
    title = 'Delta Diff',
    scroll_fn = scroll_less,
})

-- Custom sorters
local function preserve_order_sorter(opts)
    -- luacheck:ignore 631
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
    opts.entry_maker = function(entry)
        return {
            value = entry,
            display = ' ' .. entry,
            ordinal = entry,
            path = opts.cwd .. '/' .. entry,
        }
    end
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
    opts.entry_maker = function(entry)
        return {
            value = entry,
            display = '󰉙 ' .. entry,
            ordinal = entry,
        }
    end

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
    opts.entry_maker = function(entry)
        return {
            value = entry,
            display = '󰚝 ' .. vim.fn.substitute(entry, vim.env.HOME, '~', ''),
            ordinal = entry,
        }
    end
    pickers
        .new(opts, {
            prompt_title = 'Directory Bookmarks',
            finder = finders.new_table({
                results = {
                    vim.env.HOME .. '/git-repos/private/dotfiles/',
                    vim.env.HOME .. '/git-repos/private/notes/mutt/ops/',
                    vim.env.HOME .. '/git-repos/private/notes/mutt/people/',
                    vim.env.HOME .. '/git-repos/private/notes/mutt/',
                    vim.env.HOME .. '/git-repos/work/',
                    vim.env.HOME .. '/Desktop/',
                    vim.env.HOME .. '/.local/share/nvim/lazy/',
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

function _G.TelescopeConfig.poetry_venvs(opts)
    vim.cmd('lcd %:p:h')
    opts = opts or {}
    opts.entry_maker = function(entry)
        return {
            value = vim.fn.substitute(entry, ' (Activated)$', '', ''),
            display = '󰆍 ' .. entry,
            ordinal = entry,
        }
    end
    pickers
        .new(opts, {
            prompt_title = 'Poetry Virtual Envs',
            finder = finders.new_oneshot_job(
                { 'poetry', 'env', 'list', '--full-path' },
                opts
            ),
            sorter = conf.file_sorter(opts),
            previewer = tree_previewer,
            attach_mappings = function(bufnr)
                actions.select_default:replace(function()
                    local venv = action_state.get_selected_entry().value
                    actions.close(bufnr)
                    _G.PyVenv.deactivate()
                    _G.PyVenv.activate(venv)
                end)
                return true
            end,
        })
        :find()
end

-- Wrapper to avoid actions starting in insert mode
-- luacheck:ignore 631
-- See: https://github.com/nvim-telescope/telescope.nvim/issues/559#issuecomment-1311441898
local function stopinsert(callback)
    return function(prompt_bufnr)
        vim.cmd.stopinsert()
        vim.schedule(function()
            callback(prompt_bufnr)
        end)
    end
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

-- Custom actions
local transform_mod = require('telescope.actions.mt').transform_mod
local custom_actions = transform_mod({
    -- Open one or many files at once
    open_one_or_many = function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        if not vim.tbl_isempty(multi) then
            actions.close(prompt_bufnr)
            for _, v in pairs(multi) do
                if v.path ~= nil or v.filename ~= nil then
                    local fname = v.path or v.filename
                    local edit_cmd = 'edit'
                    if v.col ~= nil and v.lnum ~= nil then
                        edit_cmd = string.format(
                            '%s +call\\ cursor(%s,%s)',
                            edit_cmd,
                            v.lnum,
                            v.col
                        )
                    end
                    vim.cmd(string.format('%s %s', edit_cmd, fname))
                end
            end
        else
            actions.select_default(prompt_bufnr)
        end
    end,
    -- Context split
    context_split = function(prompt_bufnr)
        local split = 'new'
        if vim.fn.winwidth(vim.fn.winnr('#')) > 2 * (vim.go.textwidth or 80) then
            split = 'vnew'
        end
        return action_set.edit(prompt_bufnr, split)
    end,
    -- Yank
    yank = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        vim.fn.setreg('+', entry.value or entry.filename)
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
    -- Open git commit with delta via toggleterm
    delta_term = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        local delta_cmd = 'git -c core.pager=delta -c delta.paging=always -c '
            .. 'delta.side-by-side=true diff '
            .. commit_sha
            .. '^! --'
        vim.cmd(string.format('TermExec size=25 cmd="%s"', delta_cmd))
        vim.cmd('wincmd p')
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
    -- Same as above but don't gitignore
    entry_find_files_no_ignore = function(prompt_bufnr)
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
            no_ignore = true,
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
    -- resUme previous picker
    resume = function()
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

        tree_api.open()
        vim.cmd('sleep 3m') -- we seem to need this to allow focus
        tree_api.change_root(tostring(p))
        if not is_dir then
            tree_api.find_file(fname)
        else
            node_api.navigate.sibling.first()
        end
    end,
    -- Delete buffers
    delete_buffer = function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        actions.close(prompt_bufnr)
        if not vim.tbl_isempty(multi) then
            for _, v in pairs(multi) do
                vim.cmd(string.format('bwipeout %s', v.filename))
            end
        else
            vim.cmd('bwipeout ' .. action_state.get_selected_entry().value)
        end
    end,
    -- Send selection to quickfix and open
    send2qf = function(prompt_bufnr)
        actions.send_to_qflist(prompt_bufnr)
        actions.open_qflist(prompt_bufnr)
    end,
    -- Open (filter) aerial buffer
    open_aerial = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        require('aerial').focus()
        vim.fn.search(action_state.get_selected_entry().name)
        vim.cmd('normal! 0')
    end,
    -- Delete frecency entries
    delete_frecency = function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        actions.close(prompt_bufnr)
        if not vim.tbl_isempty(multi) then
            for _, v in pairs(multi) do
                vim.cmd(string.format('FrecencyDelete %s', v.filename))
            end
        else
            vim.cmd('FrecencyDelete ' .. action_state.get_selected_entry().filename)
        end
    end,
    -- Focus preview window
    focus_preview = function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local bufnr = picker.previewer.state.bufnr
        vim.keymap.set('n', '<C-h>', function()
            vim.cmd(
                string.format(
                    'noautocmd lua vim.api.nvim_set_current_win(%s)',
                    picker.prompt_win
                )
            )
        end, { buffer = bufnr })
        vim.cmd(
            string.format(
                'noautocmd lua vim.api.nvim_set_current_win(%s)',
                picker.previewer.state.winid
            )
        )
    end,
})
-- Store custom actions to be used elsewhere
_G.TelescopeConfig.custom_actions = custom_actions

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('telescope_prompt', { clear = true }),
    pattern = { 'TelescopePrompt' },
    callback = function(e)
        vim.opt_local.cursorline = false

        vim.keymap.set('n', 'H', '^lll', { buffer = e.buf })
        vim.keymap.set('n', 'L', '$', { buffer = e.buf })
    end,
})
vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('telescope_preview_ln', { clear = true }),
    pattern = { 'TelescopePreviewerLoaded' },
    callback = function()
        vim.opt_local.number = true
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
        file_ignore_patterns = { 'doc/', 'venv/', '__pycache__/' },
        layout_strategy = 'bpane',
        layout_config = {
            prompt_position = 'bottom',
            height = 20,
            preview_width = 0.45,
            preview_cutoff = 110,
        },
        cache_picker = { num_pickers = 3 },
        path_display = { 'filename_first' },
        mappings = {
            i = {
                ['<ESC>'] = 'close',
                ['<CR>'] = stopinsert(actions.select_default),
                ['<TAB>'] = stopinsert(actions.select_default),
                ['<C-s>'] = stopinsert(actions.select_horizontal),
                ['<C-v>'] = stopinsert(actions.select_vertical),
                ['<C-j>'] = 'move_selection_next',
                ['<C-k>'] = 'move_selection_previous',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
                ['<C-l>'] = custom_actions.focus_preview,
                ['<A-v>'] = action_layout.toggle_preview,
                ['<A-n>'] = actions.cycle_previewers_next,
                ['<C-space>'] = actions.toggle_selection
                    + actions.move_selection_previous,
                ['<C-y>'] = custom_actions.yank,
                ['<C-t>'] = custom_actions.entry_find_files,
                ['<A-t>'] = custom_actions.entry_find_files_no_ignore,
                ['<A-c>'] = custom_actions.entry_find_dir,
                ['<A-f>'] = stopinsert(custom_actions.open_nvimtree),
                ['<A-p>'] = custom_actions.entry_parent_dirs,
                ['<A-g>'] = custom_actions.entry_igrep,
                ['<A-r>'] = actions.to_fuzzy_refine,
                ['<C-q>'] = stopinsert(custom_actions.send2qf),
                ['<A-q>'] = actions.send_to_qflist + actions.open_qflist,
                ['<A-u>'] = custom_actions.resume,
                ['<C-/>'] = 'which_key',
                ['<A-l>'] = actions.complete_tag,
            },
            n = {
                ['q'] = 'close',
                ['<C-c>'] = 'close',
                ['<Tab>'] = 'select_default',
                ['<C-s>'] = 'file_split',
                ['<A-j>'] = 'preview_scrolling_down',
                ['<A-k>'] = 'preview_scrolling_up',
                ['<C-l>'] = custom_actions.focus_preview,
                ['<A-v>'] = action_layout.toggle_preview,
                ['<A-n>'] = actions.cycle_previewers_next,
                ['<space>'] = actions.toggle_selection + actions.move_selection_previous,
                ['<C-space>'] = actions.toggle_selection
                    + actions.move_selection_previous,
                ['<C-y>'] = custom_actions.yank,
                ['<C-t>'] = custom_actions.entry_find_files,
                ['<A-t>'] = custom_actions.entry_find_files_no_ignore,
                ['<A-c>'] = custom_actions.entry_find_dir,
                ['<A-f>'] = custom_actions.open_nvimtree,
                ['<A-p>'] = custom_actions.entry_parent_dirs,
                ['<A-g>'] = custom_actions.entry_igrep,
                ['<A-r>'] = actions.to_fuzzy_refine,
                ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
                ['<A-q>'] = actions.send_to_qflist + actions.open_qflist,
                ['<A-u>'] = custom_actions.resume,
                ['?'] = 'which_key',
                ['<A-l>'] = actions.complete_tag,
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
                    ['<C-d>'] = custom_actions.delete_buffer,
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
            mappings = {
                i = {
                    ['<CR>'] = stopinsert(custom_actions.open_one_or_many),
                },
            },
        },
        live_grep = {
            path_display = { shorten = 3 },
            mappings = {
                i = {
                    ['<CR>'] = stopinsert(custom_actions.open_one_or_many),
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
        lsp_workspace_symbols = {
            mappings = {
                i = {
                    ['<C-x>'] = actions.complete_tag,
                },
            },
        },
        git_commits = {
            layout_config = { preview_width = 0.55 },
            mappings = {
                i = {
                    ['<CR>'] = custom_actions.fugitive_open,
                    ['<C-s>'] = custom_actions.fugitive_split,
                    ['<C-v>'] = custom_actions.fugitive_vsplit,
                    ['<C-d>'] = custom_actions.delta_term,
                    ['<C-o>'] = actions.git_checkout,
                },
            },
        },
        git_bcommits = {
            layout_config = { preview_width = 0.55 },
            mappings = {
                i = {
                    ['<CR>'] = custom_actions.fugitive_open,
                    ['<C-s>'] = custom_actions.fugitive_split,
                    ['<C-v>'] = custom_actions.fugitive_vsplit,
                    ['<C-d>'] = custom_actions.delta_term,
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
        frecency = {
            auto_validate = true,
            db_validate_threshold = 2,
            db_safe_mode = false,
            matcher = 'fuzzy',
        },
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
        },
        thesaurus = {
            provider = 'dictionaryapi', -- or 'datamuse'
        },
        undo = {
            layout_config = { preview_width = 0.7 },
            mappings = {
                i = {
                    ['<C-y>'] = require('telescope-undo.actions').yank_additions,
                    ['<C-r>'] = require('telescope-undo.actions').restore,
                },
            },
        },
    },
})

-- Customized picker functions (to be called by mappings)
function _G.TelescopeConfig.find_files_cwd(opts)
    local buffer_dir = utils.buffer_dir()
    opts = opts or {}
    opts.cwd = buffer_dir
    opts.results_title = buffer_dir
    builtin.find_files(opts)
end

local function find_files_upper_cwd(opts)
    local buffer_upperdir = string.format('%s', Path:new(utils.buffer_dir()):parent())
    opts = opts or {}
    opts.cwd = buffer_upperdir
    opts.results_title = buffer_upperdir
    builtin.find_files(opts)
end

local function frecent_files()
    telescope.extensions.frecency.frecency({
        prompt_title = 'Frecent Files (<C-d>:delete)',
        attach_mappings = function(_, map)
            map('i', '<CR>', stopinsert(custom_actions.open_one_or_many))
            map('i', '<C-y>', custom_actions.yank)
            map('i', '<C-d>', custom_actions.delete_frecency)
            return true
        end,
        ignore_patterns = { '/tmp/', '.log' },
    })
end

function _G.TelescopeConfig.z_with_tree_preview(opts)
    opts = opts or {}
    opts.cmd = { 'bash', '-c', 'zoxide query --list --score 2>&1' }
    opts.prompt_title = 'Zoxide Directories'
    opts.path_display = function(_, path)
        return string.format(' %s', vim.fn.substitute(path, vim.env.HOME, '~', ''))
    end
    opts.previewer = tree_previewer
    telescope.extensions.z.list(opts)
end

local function rgrep(extra_args)
    vim.ui.input({ prompt = 'Grep dir: ', completion = 'dir' }, function(dir)
        if not dir or dir == '' then
            return
        else
            dir = vim.fn.trim(vim.fn.fnamemodify(dir, ':ph'))
        end
        local opts = {
            cwd = dir,
            search_dirs = { dir },
            results_title = dir,
            additional_args = extra_args or {},
        }
        vim.ui.input({ prompt = 'Type Filter: ' }, function(type_filter)
            if type_filter ~= '' then
                opts.type_filter = type_filter
                opts.results_title = opts.results_title .. ' [' .. type_filter .. ']'
            end
        end)
        builtin.live_grep(opts)
    end)
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

local function gitcommits(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()
    local git_root, _ = utils.get_os_command_output({
        'git',
        'rev-parse',
        '--show-toplevel',
    }, opts.cwd)
    vim.cmd('lcd %:p:h') -- to fix delta previewing
    builtin.git_commits({
        cwd = opts.cwd,
        prompt_title = 'Repo Commits (<C-d>:delta-diff,<C-o>:git-checkout)',
        results_title = git_root[1],
        previewer = {
            delta,
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
        },
        sorter = preserve_order_sorter(opts),
    })
end

local function gitcommits_buffer(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()
    vim.cmd('lcd %:p:h') -- to fix delta previewing
    builtin.git_bcommits({
        cwd = opts.cwd,
        results_title = vim.api.nvim_buf_get_name(0),
        prompt_title = 'File Commits (<C-d>:delta-diff,<C-o>:git-checkout)',
        previewer = {
            delta,
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
        },
        sorter = preserve_order_sorter(opts),
    })
end

local function thesaurus_synonyms()
    local provider = require('telescope._extensions.thesaurus.config').get().provider
    if not vim.g.dictionary_api_key and provider == 'dictionaryapi' then
        vim.g.dictionary_api_key = vim.trim(
            vim.system(
                { 'pass', 'show', [[dictionary-api/yahoomail/api-key]] },
                { text = true }
            )
                :wait().stdout
        )
    end
    telescope.extensions.thesaurus.lookup({
        layout_strategy = 'bpane',
        layout_config = {
            prompt_position = 'bottom',
            height = 20,
        },
        prompt_title = 'Synonyms',
        preview_title = 'Cursor Word Definition',
    })
end

-- Mappings
vim.keymap.set('n', '<Leader>dr', '<Cmd>Telescope resume<CR>')
vim.keymap.set('n', '<Leader>tp', '<Cmd>Telescope pickers<CR>')
vim.keymap.set('n', '<Leader>tq', '<Cmd>Telescope quickfix<CR>')
vim.keymap.set('n', '<Leader>be', function()
    builtin.buffers({ prompt_title = 'Buffers (<C-d>:delete)' })
end)
vim.keymap.set('n', '<Leader>ls', _G.TelescopeConfig.find_files_cwd)
vim.keymap.set('n', '<Leader>lS', function()
    _G.TelescopeConfig.find_files_cwd({ no_ignore = true })
end)
vim.keymap.set('n', '<Leader>lu', find_files_upper_cwd)
vim.keymap.set('n', '<Leader>lU', function()
    find_files_upper_cwd({ no_ignore = true })
end)
vim.keymap.set(
    'n',
    '<Leader>sd',
    '<Cmd>lcd %:p:h<CR>:Telescope find_files cwd=',
    { silent = false }
)
vim.keymap.set('n', '<C-t>', _G.TelescopeConfig.find_files_cwd)
vim.keymap.set('n', '<A-t>', function()
    _G.TelescopeConfig.find_files_cwd({ no_ignore = true })
end)
vim.keymap.set('n', '<Leader>rd', frecent_files)
vim.keymap.set('n', '<A-c>', _G.TelescopeConfig.find_dirs)
vim.keymap.set('n', '<A-p>', _G.TelescopeConfig.parent_dirs)
vim.keymap.set('n', '<Leader>bm', _G.TelescopeConfig.bookmark_dirs)
vim.keymap.set('n', '<A-z>', _G.TelescopeConfig.z_with_tree_preview)
vim.keymap.set('n', '<Leader>ig', igrep)
vim.keymap.set('n', '<Leader>iG', function()
    igrep(nil, nil, { '--no-ignore-vcs' })
end)
vim.keymap.set('n', '<A-g>', igrep)
vim.keymap.set('n', '<Leader>ir', function()
    local git_root, _ = utils.get_os_command_output({
        'git',
        'rev-parse',
        '--show-toplevel',
    }, utils.buffer_dir())
    igrep(git_root[1])
end)
vim.keymap.set('n', '<Leader>io', function()
    builtin.live_grep({ grep_open_files = true, results_title = 'Open Files' })
end)
vim.keymap.set('n', '<Leader>rg', rgrep)
vim.keymap.set('n', '<Leader>rG', function()
    rgrep({ '--no-ignore-vcs' })
end)
vim.keymap.set({ 'n', 'v' }, '<Leader>dg', function()
    igrep(nil, u.get_selection())
end)
vim.keymap.set('n', '<Leader>dl', search_buffer)
vim.keymap.set({ 'n', 'v' }, '<Leader>dw', function()
    search_buffer(u.get_selection())
end)
vim.keymap.set('n', '<Leader>tl', function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    builtin.grep_string({
        results_title = buf_name,
        use_regex = true,
        search = 'TODO:\\s|FIXME:\\s',
        search_dirs = { buf_name },
    })
end)
vim.keymap.set('n', '<Leader>tL', function()
    local buffer_dir = utils.buffer_dir()
    builtin.grep_string({
        cwd = buffer_dir,
        results_title = buffer_dir,
        use_regex = true,
        search = 'TODO:\\s|FIXME:\\s',
    })
end)
vim.keymap.set('n', '<Leader>gl', gitcommits)
vim.keymap.set('n', '<Leader>gL', gitcommits_buffer)
vim.keymap.set('v', '<Leader>gl', builtin.git_bcommits_range)
vim.keymap.set('n', '<Leader>gc', function()
    builtin.git_branches({ prompt_title = 'Git Branches (<C-d>:delete)' })
end)
vim.keymap.set('n', '<Leader>ch', function()
    builtin.command_history({
        prompt_title = 'Command History (<Tab>:edit)',
    })
end)
vim.keymap.set('n', '<Leader>sh', function()
    builtin.search_history({
        prompt_title = 'Search History (<Tab>:edit)',
    })
end)
vim.keymap.set('n', '<Leader>yh', function()
    telescope.extensions.neoclip.default({
        prompt_title = 'Neoclip: Register + (<C-y>:yank, <CR>:paste)',
        preview_title = 'Yank History Preview',
    })
end)
vim.keymap.set('n', '<Leader>he', function()
    builtin.help_tags({})
end)
vim.keymap.set('n', '<Leader>th', function()
    builtin.highlights({})
end)
vim.keymap.set('n', '<Leader>tm', function()
    builtin.marks({})
end)
vim.keymap.set('n', '<Leader>me', function()
    builtin.keymaps({})
end)
vim.keymap.set('n', '<Leader>sg', function()
    builtin.spell_suggest({
        fuzzy = false,
        prompt_title = 'Spelling Suggestions (<CR>:fix-word,<C-o>:fix-all)',
    })
end)
vim.keymap.set('n', '<Leader>la', function()
    builtin.lsp_references({
        preview_title = 'LSP References Preview',
        jump_type = 'split',
        fname_width = 50,
    })
end)
vim.keymap.set('n', '<Leader>te', function()
    builtin.lsp_document_symbols({
        prompt_title = 'LSP Symbols (<C-x>:complete-tag)',
        results_title = vim.api.nvim_buf_get_name(0),
        preview_title = 'LSP Document Symbols Preview',
    })
end)
vim.keymap.set('n', '<Leader>we', function()
    builtin.lsp_workspace_symbols({
        prompt_title = 'LSP Workspace Symbols (<C-x>:complete-tag)',
        preview_title = 'LSP Workspace Symbols Preview',
    })
end)
vim.keymap.set('n', '<Leader>ta', function()
    require('telescope').extensions.aerial.aerial({
        prompt_title = 'Aerial Document Symbols',
    })
end)
vim.keymap.set('n', '<Leader>se', function()
    require('telescope').extensions.luasnip.luasnip({
        prompt_title = 'Snippets',
        preview_title = 'Snippet Preview',
    })
end)
vim.keymap.set('n', '<Leader>gu', function()
    require('telescope').extensions.undo.undo({
        prompt_title = 'Undo Tree (<C-r>:restore, <C-y>:yank)',
        preview_title = 'Undo Diff',
    })
end)
vim.keymap.set('n', '<Leader>tt', thesaurus_synonyms)

-- Extensions
telescope.load_extension('aerial')
telescope.load_extension('frecency')
telescope.load_extension('fzf')
telescope.load_extension('luasnip')
telescope.load_extension('neoclip')
telescope.load_extension('thesaurus')
telescope.load_extension('undo')
telescope.load_extension('z')
