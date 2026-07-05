local codecompanion = require('codecompanion')
local registry = require('codecompanion.interactions.shared.registry')

local helpers = require('plugin-config.codecompanion.helpers')
local state_helpers = helpers.state
local picker_utils = require('plugin-config.codecompanion.pickers')
local trim_chars = picker_utils.trim_chars
local pad_right = picker_utils.pad_right
local TITLE_WIDTH = picker_utils.TITLE_WIDTH

local M = {}

local function chat_title(chat, entry)
    if chat and chat.opts and chat.opts.title and chat.opts.title ~= '' then
        return chat.opts.title
    end
    -- No generated title yet: label by the latest user message so the chat is
    -- identifiable and the label keeps tracking the conversation
    local prompt = chat and state_helpers.get_last_user_prompt(chat)
    if prompt and prompt ~= '' then
        return prompt
    end
    return entry.name
end

local function chat_model(chat)
    local adapter = chat and chat.adapter
    if not adapter then
        return 'unknown'
    end

    local labels = { claude_code = 'Claude', codex = 'Codex' }
    return labels[adapter.name]
        or state_helpers.get_adapter_model(adapter)
        or adapter.name
end

local function chat_number(entry)
    local number = (entry.name or ''):match('Chat%s+(%d+)')
    return number and ('#' .. number) or ('#' .. tostring(entry.bufnr))
end

-- Build the telescope `display` function, capturing column widths shared by
-- all rows so they only get computed once.
local function make_display(entries)
    local model_w, title_w, number_w = 0, 0, 0
    for _, e in ipairs(entries) do
        e.display_title = trim_chars(e.title, TITLE_WIDTH)
        model_w = math.max(model_w, vim.fn.strdisplaywidth(e.model))
        title_w = math.max(title_w, vim.fn.strdisplaywidth(e.display_title))
        number_w = math.max(number_w, vim.fn.strdisplaywidth(e.chat_number))
    end

    return function(picker_entry)
        local e = picker_entry.value
        local active = e.active and '*' or ' '
        local icon = state_helpers.provider_icon(e.adapter_name)
        local model = pad_right(e.model, model_w)
        local title = pad_right(e.display_title, title_w)
        local number = pad_right(e.chat_number, number_w)
        local cwd = e.cwd and vim.fn.fnamemodify(e.cwd, ':~') or ''
        local line =
            string.format('%s %s %s  %s  %s  %s', active, icon, model, title, number, cwd)

        local title_start = #active + 1 + #icon + 1 + #model + 2
        local title_end = title_start + #title

        return line,
            {
                { { 0, #active }, e.active and 'TelescopeSelection' or 'Comment' },
                {
                    { title_start, title_end },
                    e.active and 'TelescopeSelection' or 'Normal',
                },
                { { title_end + 1, #line }, 'Comment' },
            }
    end
end

local function make_preview(self, entry)
    local source = entry.value.bufnr
    if source and vim.api.nvim_buf_is_valid(source) then
        local buf, win = self.state.bufnr, self.state.winid
        local lines = vim.api.nvim_buf_get_lines(source, 0, -1, false)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].filetype = 'codecompanion'
        -- Scroll to the latest messages once telescope shows the buffer
        vim.schedule(function()
            if
                win
                and vim.api.nvim_win_is_valid(win)
                and vim.api.nvim_buf_is_valid(buf)
            then
                pcall(
                    vim.api.nvim_win_set_cursor,
                    win,
                    { vim.api.nvim_buf_line_count(buf), 0 }
                )
            end
        end)
    end
end

local function collect_entries(current_chat)
    local current_bufnr = current_chat and current_chat.bufnr
    local entries = {}

    for _, entry in ipairs(registry.list()) do
        local chat = codecompanion.buf_get_chat(entry.bufnr)
        local adapter = chat and chat.adapter
        entries[#entries + 1] = {
            bufnr = entry.bufnr,
            open = entry.open,
            active = entry.bufnr == current_bufnr,
            adapter_name = adapter and adapter.name,
            model = chat_model(chat),
            chat_number = chat_number(entry),
            title = chat_title(chat, entry),
            cwd = chat and chat.opts and chat.opts.cwd,
        }
    end

    table.sort(entries, function(a, b)
        if a.active ~= b.active then
            return a.active
        end
        return a.bufnr < b.bufnr
    end)

    return entries
end

function M.browse(chat)
    local entries = collect_entries(chat)
    if #entries == 0 then
        vim.notify('No open CodeCompanion chats', vim.log.levels.INFO)
        return
    end

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local previewers = require('telescope.previewers')

    local display = make_display(entries)
    pickers
        .new({}, {
            prompt_title = 'Open CodeCompanion Chats',
            finder = finders.new_table({
                results = entries,
                entry_maker = function(e)
                    return {
                        value = e,
                        display = display,
                        ordinal = table.concat({
                            e.model or '',
                            e.title or '',
                            e.cwd or '',
                            tostring(e.bufnr),
                        }, ' '),
                    }
                end,
            }),
            previewer = previewers.new_buffer_previewer({
                define_preview = make_preview,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local sel = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if sel then
                        sel.value.open()
                    end
                end)
                return true
            end,
        })
        :find()
end

return M
