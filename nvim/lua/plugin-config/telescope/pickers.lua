local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local from_entry = require('telescope.from_entry')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local sorters = require('telescope.sorters')
local telescope = require('telescope')
local utils = require('telescope.utils')

local custom_previewers = require('plugin-config.telescope.previewers')
local helpers = require('plugin-config.telescope.helpers')
local u = require('utils')

local M = {}

-- Helpers
local function select_dir()
    actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        local dir = from_entry.path(entry)
        builtin.find_files({
            cwd = dir,
            results_title = dir,
        })
    end)
    return true
end

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

-- Pickers
function M.find_dirs(opts)
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
            previewer = custom_previewers.tree,
            attach_mappings = select_dir,
        })
        :find()
end

function M.parent_dirs(opts)
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
        cwd = utils.buffer_dir()
    end
    local parent_dirs = {}
    for dir in vim.fs.parents(cwd) do
        table.insert(parent_dirs, dir)
    end

    pickers
        .new(opts, {
            prompt_title = 'Parents Dirs',
            finder = finders.new_table({
                results = parent_dirs,
                entry_maker = opts.entry_maker,
            }),
            sorter = conf.file_sorter(opts),
            results_title = string.format('%s', cwd),
            previewer = custom_previewers.tree,
            attach_mappings = select_dir,
        })
        :find()
end

function M.bookmark_dirs(opts)
    opts = opts or {}
    opts.entry_maker = function(entry)
        return {
            value = entry,
            display = '󰚝 ' .. entry:gsub(vim.env.HOME, '~'),
            ordinal = entry,
        }
    end
    pickers
        .new(opts, {
            prompt_title = 'Directory Bookmarks',
            finder = finders.new_table({
                results = {
                    vim.fs.joinpath(vim.env.HOME, 'git-repos', 'private', 'dotfiles'),
                    vim.fs.joinpath(vim.env.HOME, 'git-repos', 'private', 'ai-harness'),
                    vim.fs.joinpath(
                        vim.env.HOME,
                        'git-repos',
                        'private',
                        'notes',
                        'mutt',
                        'ops'
                    ),
                    vim.fs.joinpath(
                        vim.env.HOME,
                        'git-repos',
                        'private',
                        'notes',
                        'mutt',
                        'people'
                    ),
                    vim.fs.joinpath(
                        vim.env.HOME,
                        'git-repos',
                        'private',
                        'notes',
                        'mutt'
                    ),
                    vim.fs.joinpath(vim.env.HOME, 'git-repos', 'work'),
                    vim.fs.joinpath(vim.env.HOME, 'Desktop'),
                    vim.fs.joinpath(vim.fn.stdpath('data'), 'site/pack/core/opt'),
                },
                entry_maker = opts.entry_maker,
            }),
            sorter = conf.file_sorter(opts),
            previewer = custom_previewers.tree,
            attach_mappings = select_dir,
        })
        :find()
end

function M.igrep(dir, start_text, extra_args)
    local buffer_dir = dir or utils.buffer_dir()
    builtin.live_grep({
        cwd = buffer_dir,
        results_title = buffer_dir,
        default_text = start_text or '',
        additional_args = extra_args or {},
    })
end

function M.find_files_cwd(opts)
    local buffer_dir = utils.buffer_dir()
    opts = opts or {}
    opts.cwd = buffer_dir
    opts.results_title = buffer_dir
    builtin.find_files(opts)
end

function M.find_files_upper_cwd(opts)
    local buffer_upperdir = vim.fs.dirname(utils.buffer_dir())
    opts = opts or {}
    opts.cwd = buffer_upperdir
    opts.results_title = buffer_upperdir
    builtin.find_files(opts)
end

function M.delete_frecency(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local multi = picker:get_multi_selection()
    actions.close(prompt_bufnr)
    if not vim.tbl_isempty(multi) then
        for _, entry in pairs(multi) do
            vim.cmd(string.format('FrecencyDelete %s', entry.filename))
        end
    else
        vim.cmd('FrecencyDelete ' .. action_state.get_selected_entry().filename)
    end
end

function M.frecent_files()
    telescope.extensions.frecency.frecency({
        prompt_title = 'Frecent Files (<C-d>:delete,<C-y>:yank,<A-a>:cc-context)',
        attach_mappings = function(_, map)
            map('i', '<CR>', helpers.stopinsert(helpers.open_one_or_many))
            map('i', '<C-y>', helpers.yank)
            map('i', '<C-d>', M.delete_frecency)
            return true
        end,
        ignore_patterns = { '/tmp/', '.log' },
    })
end

function M.z_with_tree_preview(opts)
    opts = opts or {}
    opts.cmd = { 'bash', '-c', 'zoxide query --list --score 2>&1' }
    opts.prompt_title = 'Zoxide Directories'
    opts.path_display = function(_, path)
        return string.format(' %s', path:gsub(vim.env.HOME, '~'))
    end
    opts.previewer = custom_previewers.tree
    telescope.extensions.z.list(opts)
end

function M.rgrep(extra_args)
    vim.ui.input({ prompt = 'Grep dir: ', completion = 'dir' }, function(dir)
        if not dir or dir == '' then
            return
        else
            dir = vim.trim(vim.fs.normalize(dir))
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

function M.search_buffer(start_text)
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

function M.gitcommits(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()

    local git_root = u.git_root(opts.cwd)
    if not git_root then
        vim.notify('Current buffer is not in a git repository', vim.log.levels.WARN)
        return
    end

    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0))) -- to fix delta previewing
    builtin.git_commits({
        cwd = opts.cwd,
        results_title = git_root,
        previewer = {
            custom_previewers.delta,
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
        },
        sorter = preserve_order_sorter(opts),
    })
end

function M.gitcommits_buffer(opts)
    opts = opts or {}
    opts.cwd = utils.buffer_dir()
    vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0))) -- to fix delta previewing
    builtin.git_bcommits({
        cwd = opts.cwd,
        results_title = vim.api.nvim_buf_get_name(0),
        previewer = {
            custom_previewers.delta,
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
        },
        sorter = preserve_order_sorter(opts),
    })
end

function M.thesaurus_synonyms()
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

return M
