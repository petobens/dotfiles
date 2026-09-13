local codecompanion = require('codecompanion')
local registry = require('codecompanion.interactions.shared.registry')
local utils = require('codecompanion.utils')

local state_helpers = require('plugin-config.codecompanion.helpers').state
local picker_helpers = require('plugin-config.codecompanion.pickers.helpers')
local restore = require('plugin-config.codecompanion.pickers.acp_sessions.restore')
local store = require('plugin-config.codecompanion.pickers.acp_sessions.store')

local M = {}

local TITLE_WIDTH = picker_helpers.TITLE_WIDTH + 10
local ICONS = {
    current = '\226\151\143', -- ● session open in the current chat
    loaded = '\226\151\139', -- ○ session open in another chat
    clock = '\239\128\151', -- nf-fa-clock_o (U+F017)
}

-- Helpers
local function open_session_map()
    local map = {}
    for _, entry in ipairs(registry.list()) do
        local chat = codecompanion.buf_get_chat(entry.bufnr)
        local sid = chat and chat.acp_connection and chat.acp_connection.session_id
        if sid then
            map[sid] = entry.bufnr
        end
    end
    return map
end

-- Picker entry presentation
local function adapter_label(name)
    return ({ claude_code = 'Claude', codex = 'Codex' })[name] or name
end

local function fmt_weight(size)
    local k = (size or 0) / 4 / 1000
    return k >= 1 and string.format('~%.1fk', k) or string.format('~%d', (size or 0) / 4)
end

local function make_display(entries)
    local title_w, model_w, id_w, weight_w, time_w = 0, 0, 0, 0, 0
    for _, e in ipairs(entries) do
        e.display_title = picker_helpers.trim_chars(e.title or e.session_id, TITLE_WIDTH)
        local model = state_helpers.format_model_label(e.adapter, e.model)
        e.display_model = state_helpers.format_model_effort_label(model, e.effort)
        e.display_id = e.session_id and e.session_id:sub(-7) or '?'
        e.display_weight = fmt_weight(e.size)
        e.display_time = e.updated_at and utils.make_relative(e.updated_at) or '?'
        e.display_timestamp = e.updated_at and os.date('%Y-%m-%d %H:%M', e.updated_at)
            or '?'
        title_w = math.max(title_w, vim.fn.strdisplaywidth(e.display_title))
        model_w = math.max(model_w, vim.fn.strdisplaywidth(e.display_model))
        id_w = math.max(id_w, vim.fn.strdisplaywidth(e.display_id))
        weight_w = math.max(weight_w, vim.fn.strdisplaywidth(e.display_weight))
        time_w = math.max(time_w, vim.fn.strdisplaywidth(e.display_time))
    end

    return function(picker_entry)
        local e = picker_entry.value
        local marker = e.current and ICONS.current or (e.loaded and ICONS.loaded or ' ')
        local icon = state_helpers.provider_icon(e.adapter)
        local title = picker_helpers.pad_right(e.display_title, title_w)
        local model = picker_helpers.pad_right(e.display_model, model_w)
        local id = picker_helpers.pad_right(e.display_id, id_w)
        local weight_pad = string.rep(
            ' ',
            math.max(weight_w - vim.fn.strdisplaywidth(e.display_weight), 0)
        )
        local time = picker_helpers.pad_right(e.display_time, time_w)
        local cwd = e.cwd and vim.fn.fnamemodify(e.cwd, ':~') or ''
        local meta = string.format(
            '(%s)%s   %s %s (%s)',
            e.display_weight,
            weight_pad,
            ICONS.clock,
            time,
            e.display_timestamp
        )
        local line = string.format(
            '%s %s %s  %s  %s  %s  %s',
            marker,
            icon,
            title,
            model,
            id,
            meta,
            cwd
        )
        local model_end = #marker + 1 + #icon + 1 + #title + 2 + #model
        return line, {
            { { model_end + 1, #line }, 'Comment' },
        }
    end
end

local function make_finder(entries)
    local display = make_display(entries)
    return require('telescope.finders').new_table({
        results = entries,
        entry_maker = function(e)
            return {
                value = e,
                display = display,
                ordinal = adapter_label(e.adapter)
                    .. ' '
                    .. (e.title or '')
                    .. ' '
                    .. (e.session_id or '')
                    .. ' '
                    .. (e.display_time or '')
                    .. ' '
                    .. (e.display_timestamp or '')
                    .. ' '
                    .. (e.cwd or ''),
            }
        end,
    })
end

-- Picker actions
local function picker_mappings(chat, entries)
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    return function(prompt_bufnr, map)
        local current = action_state.get_current_picker(prompt_bufnr)
        local function selected_entries()
            local selections = current:get_multi_selection()
            return #selections > 0 and selections or { action_state.get_selected_entry() }
        end

        local selection_hl =
            vim.api.nvim_get_hl(0, { name = 'TelescopeSelection', link = false })
        selection_hl.bold = true
        vim.api.nvim_set_hl(0, 'CodeCompanionSessionSelection', selection_hl)
        vim.wo[current.results_win].winhighlight = table.concat(
            vim.tbl_filter(function(part)
                return part ~= ''
            end, {
                vim.wo[current.results_win].winhighlight,
                'TelescopeSelection:CodeCompanionSessionSelection',
            }),
            ','
        )

        actions.select_default:replace(function()
            local selections = selected_entries()
            actions.close(prompt_bufnr)
            for _, selection in ipairs(selections) do
                if selection then
                    restore.load(chat, selection.value)
                end
            end
        end)

        local function delete()
            local deleted = {}
            for _, selection in ipairs(selected_entries()) do
                if selection and store.delete(selection.value.path) then
                    deleted[selection.value] = true
                end
            end
            for i = #entries, 1, -1 do
                if deleted[entries[i]] then
                    table.remove(entries, i)
                end
            end
            current:refresh(make_finder(entries), { reset_prompt = false })
            local n = vim.tbl_count(deleted)
            utils.notify(
                string.format('Deleted %d session%s', n, n == 1 and '' or 's'),
                n > 0 and vim.log.levels.INFO or vim.log.levels.WARN
            )
        end

        local function yank_session_id()
            local selection = action_state.get_selected_entry()
            if selection then
                actions.close(prompt_bufnr)
                vim.fn.setreg('+', selection.value.session_id)
            end
        end

        map('n', 'd', delete)
        map('n', '<C-y>', yank_session_id)
        map('i', '<A-d>', delete)
        map('i', '<C-y>', yank_session_id)
        return true
    end
end

-- Background title refresh
local function refresh_titles(picker, entries)
    vim.system({ 'ai_session_title' }, { text = true }, function(obj)
        if tonumber((obj.stdout or ''):match('generated (%d+)')) == 0 then
            return
        end
        vim.schedule(function()
            if
                not picker.prompt_bufnr
                or not vim.api.nvim_buf_is_valid(picker.prompt_bufnr)
            then
                return
            end
            store.refresh_titles(entries)
            pcall(function()
                picker:refresh(make_finder(entries), { reset_prompt = false })
            end)
        end)
    end)
end

-- Picker orchestration
function M.browse(chat)
    store.ensure_periodic_prune()

    local entries = store.list()
    if #entries == 0 then
        return utils.notify('No ACP sessions found', vim.log.levels.INFO)
    end

    local open_map = open_session_map()
    local current_sid = chat and chat.acp_connection and chat.acp_connection.session_id
    for _, e in ipairs(entries) do
        e.loaded = open_map[e.session_id] ~= nil
        e.current = e.session_id == current_sid
    end

    local pickers = require('telescope.pickers')
    local conf = require('telescope.config').values

    local picker = pickers.new({}, {
        prompt_title = string.format(
            'ACP Sessions (%s current %s loaded | <C-y>:yank ID,<A-d>:delete)',
            ICONS.current,
            ICONS.loaded
        ),
        finder = make_finder(entries),
        sorter = conf.generic_sorter({}),
        tiebreak = function()
            return false
        end,
        attach_mappings = picker_mappings(chat, entries),
    })
    picker:find()
    refresh_titles(picker, entries)
end

return M
