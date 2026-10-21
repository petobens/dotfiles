local codecompanion = require('codecompanion')
local u = require('utils')

local repo_helpers = require('plugin-config.codecompanion.helpers').repo
local git = repo_helpers.git

local M = {}

local function make_finder(trees)
    local main = trees[1].path
    return require('telescope.finders').new_table({
        results = trees,
        entry_maker = function(tree)
            local text = string.format(
                '%s  %s%s',
                tree.branch or 'detached',
                vim.fn.fnamemodify(tree.path, ':~'),
                tree.path == main and '  (main)' or ''
            )
            return { value = tree, display = text, ordinal = text }
        end,
    })
end

-- Chat in, create, merge, or remove the repository's worktrees
function M.browse(create_chat)
    -- In a chat, use the chat's directory instead of the chat buffer's name
    local chat = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    local trees = repo_helpers.worktrees(chat and chat.opts.cwd or u.buffer_dir())
    if not trees then
        return
    end
    local main = trees[1].path
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    require('telescope.pickers')
        .new({}, {
            prompt_title = 'Worktrees (<CR>:chat, <A-n>:new, <A-m>:merge, <A-d>:remove)',
            finder = make_finder(trees),
            sorter = require('telescope.config').values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if selection then
                        create_chat(selection.value.path)
                    end
                end)

                local function new()
                    local typed = vim.trim(action_state.get_current_line())
                    actions.close(prompt_bufnr)
                    vim.ui.input(
                        { prompt = 'New worktree branch: ', default = typed },
                        function(branch)
                            branch = vim.trim(branch or '')
                            if branch == '' then
                                return
                            end
                            -- Sibling directory, e.g. ~/repo-feat for branch feat
                            local path = main .. '-' .. branch:gsub('/', '-')
                            if git({ 'worktree', 'add', '-b', branch, path }, main) then
                                create_chat(path)
                            end
                        end
                    )
                end

                local function merge()
                    local selection = action_state.get_selected_entry()
                    local branch = selection and selection.value.branch
                    if not branch or selection.value.path == main then
                        return vim.notify('Select a worktree branch to merge')
                    end
                    local output = git({ 'merge', '--no-edit', branch }, main)
                    -- Reload open buffers whose files the merge changed
                    vim.cmd.checktime()
                    if output then
                        vim.notify('Merged ' .. branch .. '\n' .. vim.trim(output))
                    end
                end

                local function remove()
                    local selection = action_state.get_selected_entry()
                    local path = selection and selection.value.path
                    if not path or path == main then
                        return vim.notify('The main checkout cannot be removed')
                    end
                    -- Git refuses to remove worktrees with uncommitted changes
                    if git({ 'worktree', 'remove', path }, main) then
                        -- `branch -d` would check a tracked upstream instead of the
                        -- main checkout, so check the main checkout and force delete
                        local branch = selection.value.branch
                        local merged = branch
                                and git(
                                    { 'branch', '--list', '--merged', 'HEAD', branch },
                                    main
                                )
                            or ''
                        if merged ~= '' and git({ 'branch', '-D', branch }, main) then
                            vim.notify('Removed ' .. path .. ' and branch ' .. branch)
                        else
                            vim.notify('Removed ' .. path .. '; unmerged branch kept')
                        end
                        action_state
                            .get_current_picker(prompt_bufnr)
                            :refresh(make_finder(repo_helpers.worktrees(main)))
                    end
                end

                map('i', '<A-n>', new)
                map('i', '<A-m>', merge)
                map('i', '<A-d>', remove)
                map('n', 'd', remove)
                return true
            end,
        })
        :find()
end

return M
