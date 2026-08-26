local action_set = require('telescope.actions.set')
local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local from_entry = require('telescope.from_entry')
local node_api = require('nvim-tree.api').node
local transform_mod = require('telescope.actions.mt').transform_mod
local tree_api = require('nvim-tree.api').tree

local custom_previewers = require('plugin-config.telescope.previewers')
local helpers = require('plugin-config.telescope.helpers')
local pickers = require('plugin-config.telescope.pickers')
local u = require('utils')

local M = {}

M.custom = transform_mod({
    -- Open one or many files at once
    open_one_or_many = helpers.open_one_or_many,
    -- Context split
    context_split = function(prompt_bufnr)
        local split = 'new'
        local target_win = vim.fn.win_getid(vim.fn.winnr('#'))
        if u.should_vsplit(target_win) then
            split = 'vnew'
        end
        return action_set.edit(prompt_bufnr, split)
    end,
    -- Yank
    yank = helpers.yank,
    -- Open git commit using Fugitive
    fugitive_open = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        vim.cmd.e(vim.fn.FugitiveFind(commit_sha))
    end,
    fugitive_split = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        vim.cmd.split(vim.fn.FugitiveFind(commit_sha))
    end,
    fugitive_vsplit = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local commit_sha = action_state.get_selected_entry().value
        vim.cmd.vsplit(vim.fn.FugitiveFind(commit_sha))
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
        vim.cmd.wincmd('p')
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
        vim.cmd.normal({ 'mz', bang = true, mods = { silent = true } })
        vim.cmd.normal({ entry.index .. 'z=', bang = true, mods = { silent = true } })
        -- Use pcall to gracefully catch E753 when there are no more words to replace
        pcall(vim.cmd.spellrepall)
        vim.cmd.normal({ '`z', bang = true, mods = { silent = true } })
    end,
    -- Show containing files of entry dir
    entry_find_files = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local dir = helpers.selected_entry_dir()
        builtin.find_files({
            cwd = dir,
            results_title = dir,
        })
    end,
    -- Same as above but don't gitignore
    entry_find_files_no_ignore = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local dir = helpers.selected_entry_dir()
        builtin.find_files({
            cwd = dir,
            results_title = dir,
            no_ignore = true,
        })
    end,
    -- Show containing dir of entry
    entry_find_dir = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        pickers.find_dirs({ cwd = helpers.selected_entry_dir() })
    end,
    -- Show parent dirs of entry
    entry_parent_dirs = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        pickers.parent_dirs({ starting_dir = helpers.selected_entry_dir() })
    end,
    -- Live (interactive) grep in entry dir
    entry_igrep = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        pickers.igrep(helpers.selected_entry_dir())
    end,
    -- resume previous picker
    resume = function()
        builtin.resume()
    end,
    -- Open in nvimtree
    open_nvimtree = function(prompt_bufnr)
        local is_dir = true
        local fname = nil

        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()

        local path = from_entry.path(entry)
        local stat = vim.uv.fs_stat(path)
        if stat and stat.type == 'file' then
            is_dir = false
            fname = vim.fs.basename(path)
            path = vim.fs.dirname(path)
        end

        tree_api.open()
        vim.cmd.sleep('3m') -- we seem to need this to allow focus
        tree_api.change_root(path)
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
                vim.cmd.bwipeout(v.filename)
            end
        else
            vim.cmd.bwipeout(action_state.get_selected_entry().value)
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
        vim.cmd.normal({ '0', bang = true })
    end,
    -- Delete frecency entries
    delete_frecency = pickers.delete_frecency,
    -- Focus preview window
    focus_preview = function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local bufnr = picker.previewer.state.bufnr
        vim.keymap.set('n', '<C-h>', function()
            vim.api.nvim_set_current_win(picker.prompt_win)
        end, { buf = bufnr })
        vim.cmd(
            string.format(
                'noautocmd lua vim.api.nvim_set_current_win(%s)',
                picker.previewer.state.winid
            )
        )
    end,
    -- Add files as a reference/context to codecompanion
    add_codecompanion_references = function(prompt_bufnr)
        _G.CodeCompanionConfig.add_context(helpers.selected_files(prompt_bufnr))
    end,
    -- Add PDFs as documents to CodeCompanion
    add_codecompanion_documents = function(prompt_bufnr)
        local files = vim.iter(helpers.selected_files(prompt_bufnr))
            :filter(function(file)
                return vim.fs.ext(file):lower() == 'pdf'
            end)
            :totable()

        if vim.tbl_isempty(files) then
            vim.notify('Select at least one PDF', vim.log.levels.WARN)
            return
        end
        _G.CodeCompanionConfig.add_documents(files)
    end,
    -- Add images to CodeCompanion
    add_codecompanion_images = function(prompt_bufnr)
        local files = vim.iter(helpers.selected_files(prompt_bufnr))
            :filter(function(file)
                return custom_previewers.supported_images[vim.fs.ext(file):lower()]
            end)
            :totable()

        if vim.tbl_isempty(files) then
            vim.notify('Select at least one image', vim.log.levels.WARN)
            return
        end
        _G.CodeCompanionConfig.add_images(files)
    end,
    -- Run codecompanion code review
    codecompanion_code_review = function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        if entry and entry.value then
            _G.CodeCompanionConfig.run_slash_command(
                'code_review',
                { commit_sha = entry.value }
            )
        end
    end,
    -- Run codecompanion changelog
    codecompanion_changelog = function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        actions.close(prompt_bufnr)

        local commit_shas = {}
        if not vim.tbl_isempty(multi) then
            for _, entry in ipairs(multi) do
                table.insert(commit_shas, entry.value)
            end
        else
            local entry = action_state.get_selected_entry()
            if entry then
                table.insert(commit_shas, entry.value)
            end
        end
        _G.CodeCompanionConfig.run_slash_command(
            'changelog',
            { commit_shas = commit_shas }
        )
    end,
})

return M
