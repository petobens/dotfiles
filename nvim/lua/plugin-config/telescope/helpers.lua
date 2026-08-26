local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local from_entry = require('telescope.from_entry')

local M = {}

-- Picker mode
-- luacheck:ignore 631
-- See: https://github.com/nvim-telescope/telescope.nvim/issues/559#issuecomment-1311441898
function M.stopinsert(callback)
    return function(prompt_bufnr)
        vim.cmd.stopinsert()
        vim.schedule(function()
            callback(prompt_bufnr)
        end)
    end
end

-- Shared actions
function M.open_one_or_many(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    if picker.prompt_title == 'Select file(s)' then
        actions.select_default(prompt_bufnr)
        return
    end

    local multi = picker:get_multi_selection()
    if not vim.tbl_isempty(multi) then
        actions.close(prompt_bufnr)
        for _, entry in pairs(multi) do
            if entry.path ~= nil or entry.filename ~= nil then
                local filename = entry.path or entry.filename
                vim.cmd.edit({
                    args = { filename },
                    magic = { file = false, bar = false },
                })
                if entry.col ~= nil and entry.lnum ~= nil then
                    local lnum = math.min(entry.lnum, vim.api.nvim_buf_line_count(0))
                    vim.api.nvim_win_set_cursor(0, { lnum, math.max(entry.col - 1, 0) })
                end
            end
        end
    else
        actions.select_default(prompt_bufnr)
    end
end

function M.yank(prompt_bufnr)
    actions.close(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    vim.fn.setreg('+', entry.path or entry.value or entry.filename)
end

-- Selection
function M.selected_files(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local multi = picker:get_multi_selection()
    local cwd = picker.cwd or vim.uv.cwd()
    actions.close(prompt_bufnr)

    local entries = not vim.tbl_isempty(multi) and multi
        or { action_state.get_selected_entry() }
    return vim.iter(entries)
        :map(function(entry)
            local path = from_entry.path(entry, false, false)
            if not path then
                return nil
            end
            path = vim.fs.normalize(path)
            return vim.startswith(path, '/') and path
                or vim.fs.joinpath(entry.cwd or cwd, path)
        end)
        :totable()
end

function M.selected_entry_dir()
    local path = from_entry.path(action_state.get_selected_entry())
    local stat = vim.uv.fs_stat(path)
    return stat and stat.type == 'file' and vim.fs.dirname(path) or path
end

return M
