local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local u = require('utils')

local SKILLS_DIR =
    vim.fs.joinpath(vim.env.HOME, 'git-repos', 'private', 'ai-harness', 'skills')

local M = {}

local function skill_entries()
    local entries = {}
    local stat = vim.uv.fs_stat(SKILLS_DIR)
    if not (stat and stat.type == 'directory') then
        return entries
    end

    for name, ftype in vim.fs.dir(SKILLS_DIR) do
        if ftype == 'directory' then
            local skill_md = vim.fs.joinpath(SKILLS_DIR, name, 'SKILL.md')
            if vim.uv.fs_stat(skill_md) then
                table.insert(entries, { name = name, path = skill_md })
            end
        end
    end

    table.sort(entries, function(a, b)
        return a.name < b.name
    end)
    return entries
end

local function open_picker(on_select)
    local results = skill_entries()
    if vim.tbl_isempty(results) then
        vim.notify('No skills found in ' .. SKILLS_DIR, vim.log.levels.WARN)
        return
    end

    local opts = {}
    pickers
        .new(opts, {
            prompt_title = 'Skills',
            finder = finders.new_table({
                results = results,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = '󰓅 ' .. entry.name,
                        ordinal = entry.name,
                        path = entry.path,
                    }
                end,
            }),
            sorter = conf.generic_sorter(opts),
            previewer = conf.file_previewer(opts),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local entry = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if entry then
                        on_select(entry.value)
                    end
                end)
                return true
            end,
        })
        :find()
end

function M.browse()
    open_picker(function(skill)
        u.split_open(skill.path)
    end)
end

function M.skills(chat)
    open_picker(function(skill)
        if chat and chat.bufnr and vim.api.nvim_buf_is_valid(chat.bufnr) then
            local win = vim.fn.bufwinid(chat.bufnr)
            if win ~= -1 then
                vim.api.nvim_set_current_win(win)
            end
        end
        vim.api.nvim_put({ skill.name }, 'c', true, true)
    end)
end

return M
