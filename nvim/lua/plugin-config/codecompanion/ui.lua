local codecompanion = require('codecompanion')
local devicons = require('nvim-web-devicons')
local telescope_action_state = require('telescope.actions.state')
local tool_labels = require('codecompanion.interactions.chat.tools.labels')

local u = require('utils')
local acp_helpers = require('plugin-config.codecompanion.helpers').acp
local state_helpers = require('plugin-config.codecompanion.helpers').state
local usage_helpers = require('plugin-config.codecompanion.helpers').usage

local M = {}

local get_turn_state = state_helpers.get_turn_state
local set_turn_state = state_helpers.set_turn_state

-- Title and footer rendering
local function truncate(text, max_width)
    text = text:gsub('%s+', ' ')
    if vim.fn.strdisplaywidth(text) <= max_width then
        return text
    end

    local length = vim.fn.strchars(text)
    repeat
        length = length - 1
        text = vim.fn.strcharpart(text, 0, length)
    until length == 0 or vim.fn.strdisplaywidth(text .. '…') <= max_width
    return text .. '…'
end

local function cwd_footer(chat)
    local cwd = vim.uv.cwd()
    if chat and chat.adapter and chat.adapter.type == 'acp' then
        -- ACP agents run at the git root (see patch_acp_cwd), so reflect that
        if not chat.opts.cwd or chat.opts.cwd == '' then
            chat.opts.cwd = u.git_root(cwd) or cwd
        end
        cwd = chat.opts.cwd
    end

    return cwd and cwd:match('([^/]+/[^/]+/[^/]+)$') or ''
end

local function chat_title(chat)
    -- Status counts cover every open chat, while the trailing title is local
    local counts, open_chat_count = state_helpers.get_turn_state_counts()
    local chat_count = '󰭹' .. state_helpers.superscript(open_chat_count)
    local statuses = {}
    for _, state in ipairs({ 'attention', 'running', 'ready', 'stopped' }) do
        if counts[state] then
            local prefix = statuses[1] and ' ' or ''
            local state_icon = state_helpers.turn_states[state].icon
            statuses[#statuses + 1] = {
                prefix .. state_icon .. state_helpers.superscript(counts[state]),
                'FloatTitle',
            }
        end
    end

    local title = { { chat_count, 'FloatTitle' } }
    if statuses[1] then
        title[#title + 1] = { ' (', 'FloatTitle' }
        vim.list_extend(title, statuses)
        title[#title + 1] = { ')', 'FloatTitle' }
    end

    local width = vim.api.nvim_win_get_width(chat.ui.winnr) - 4
    local left_width = 0
    for _, chunk in ipairs(title) do
        left_width = left_width + vim.fn.strdisplaywidth(chunk[1])
    end
    local chat_name =
        truncate(state_helpers.get_chat_title(chat), math.max(1, width - left_width - 3))

    title[#title + 1] = { ' · ' .. chat_name, 'FloatTitle' }
    return title
end

local function chat_footer(chat)
    local chat_number = state_helpers.get_chat_number({ bufnr = chat.bufnr }):sub(2)
    local adapter = chat.adapter
    local parts = {
        string.format(
            '%s %s: %s',
            state_helpers.provider_icon(adapter and adapter.name),
            chat_number,
            state_helpers.get_chat_model_label(chat)
        ),
    }
    if adapter and acp_helpers.mode_label(chat) then
        table.insert(parts, ' Plan')
    end
    local cwd = cwd_footer(chat)
    if cwd ~= '' then
        table.insert(parts, ' ' .. cwd)
    end
    table.insert(parts, string.format(' %d', state_helpers.get_cycle_count(chat)))
    table.insert(parts, string.format(' %s', state_helpers.format_context_usage(chat)))
    if adapter and adapter.type == 'acp' then
        local usage = usage_helpers.get(adapter.name)
        if usage then
            local label = string.format(' 5h %.0f%%', usage.pct)
            if usage.reset then
                label = label .. ' (' .. usage.reset .. ')'
            end
            table.insert(parts, label)
        end
    end
    return table.concat(parts, ' · ')
end

-- Window refresh
local function refresh_chat_footer(bufnr)
    local ok, chat = pcall(function()
        return codecompanion.buf_get_chat(bufnr)
    end)
    if not ok or not chat or not chat.ui or not chat.ui.winnr then
        return
    end
    if not vim.api.nvim_win_is_valid(chat.ui.winnr) then
        return
    end
    vim.api.nvim_win_set_config(chat.ui.winnr, {
        footer = chat_footer(chat),
        footer_pos = 'center',
    })
end

local function refresh_all_chat_titles()
    state_helpers.for_each_open_chat(function(chat)
        if
            chat
            and chat.ui
            and chat.ui.winnr
            and vim.api.nvim_win_is_valid(chat.ui.winnr)
        then
            vim.api.nvim_win_set_config(chat.ui.winnr, {
                title = chat_title(chat),
            })
        end
    end)
end

local function notify_chat_done(bufnr)
    local chat = codecompanion.buf_get_chat(bufnr)
    if not chat then
        return
    end

    local message = string.format(
        '%s finished (%s)',
        state_helpers.get_chat_model_label(chat),
        state_helpers.get_chat_name(chat)
    )
    vim.api.nvim_echo({ { message, 'DiagnosticOk' } }, true)
end

-- Fetch the usage limit for claude_code/codex chats and re-render the footer
local function refresh_chat_usage(bufnr)
    local ok, chat = pcall(function()
        return codecompanion.buf_get_chat(bufnr)
    end)
    if not ok or not chat or not chat.adapter or chat.adapter.type ~= 'acp' then
        return
    end
    usage_helpers.refresh(chat.adapter.name, function()
        refresh_chat_footer(bufnr)
    end)
end

local function refresh_current_chat_window(e, attempt)
    e = e or {}
    attempt = attempt or 0

    local ok, chat = pcall(function()
        return codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    end)

    if not ok or not chat or not chat.ui or not chat.ui.winnr then
        -- Picker/restore events can arrive before the chat window is registered
        if attempt == 0 then
            vim.defer_fn(function()
                local picker = telescope_action_state.get_current_picker(
                    vim.api.nvim_get_current_buf()
                )
                if picker then
                    vim.api.nvim_win_close(picker.prompt_win, true)
                end
            end, 50)
        end

        if attempt < 2 then
            -- Retry for up to 100 ms without blocking the UI
            vim.defer_fn(function()
                refresh_current_chat_window(e, attempt + 1)
            end, 50)
            return
        end

        if vim.bo.filetype == 'codecompanion' and e.data and e.data.title then
            local win_id = vim.api.nvim_get_current_win()
            local current = vim.api.nvim_win_get_config(win_id)
            vim.api.nvim_win_set_config(win_id, {
                title = current.title[1][1]:gsub('%b()', '(' .. e.data.title .. ')'),
            })
        end
        return
    end

    vim.api.nvim_win_set_config(chat.ui.winnr, {
        title = chat_title(chat),
        footer = chat_footer(chat),
        footer_pos = 'center',
    })
end

-- Role label formatter for the chat UI
function M.llm_role(adapter)
    local adapter_name = adapter.formatted_name or adapter.name or 'unknown'
    local model = state_helpers.get_adapter_model(adapter) or 'unknown'
    local effort = state_helpers.get_adapter_effort(adapter)
    if effort then
        model = string.format('%s %s', model, effort)
    end
    return string.format(
        '%s (%s) |  %s',
        adapter_name,
        model,
        os.date('%Y-%m-%d %H:%M:%S')
    )
end

-- Spinner
vim.api.nvim_set_hl(0, 'CodeCompanionSpinner', { fg = '#7f848e' })

local spinner_frames = {
    '⢎ ',
    '⠎⠁',
    '⠊⠑',
    '⠈⠱',
    ' ⡱',
    '⢀⡰',
    '⢄⡠',
    '⢆⡀',
}
local spinner_ns = vim.api.nvim_create_namespace('codecompanion_spinner')
local spinners = {}

local function update_spinner(bufnr)
    local current = spinners[bufnr]
    if not current or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    local winnr = vim.fn.bufwinid(bufnr)
    if winnr == -1 or not vim.api.nvim_win_is_valid(winnr) then
        return
    end

    vim.api.nvim_buf_set_extmark(
        bufnr,
        spinner_ns,
        vim.api.nvim_buf_line_count(bufnr) - 1,
        0,
        {
            id = 1,
            virt_text = {
                { spinner_frames[current.index], 'CodeCompanionSpinner' },
            },
            virt_text_pos = 'right_align',
        }
    )
    current.index = current.index % #spinner_frames + 1
end

local function clear_spinner(bufnr)
    local current = spinners[bufnr]
    if not current then
        return
    end

    current.timer:stop()
    current.timer:close()
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, spinner_ns, 0, -1)
    end
    spinners[bufnr] = nil
end

local function start_spinner(bufnr)
    clear_spinner(bufnr)
    spinners[bufnr] = { timer = vim.uv.new_timer(), index = 1 }
    spinners[bufnr].timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            update_spinner(bufnr)
        end)
    )
end

-- Chat display
function M.chat_display()
    return {
        intro_message = '',
        icons = {
            buffer_sync_all = ' ',
            buffer_sync_diff = ' ',
        },
        window = {
            layout = 'float',
            border = 'rounded',
            height = vim.o.lines - 5,
            width = 0.461,
            relative = 'editor',
            col = vim.o.columns,
            row = 1,
            opts = { winfixbuf = true },
        },
        debug_window = {
            width = math.floor(vim.o.columns * 0.535),
            height = vim.o.lines - 4,
        },
    }
end

-- Setup
function M.setup()
    -- Re-sourcing replaces handlers instead of registering duplicates
    local group = vim.api.nvim_create_augroup('codecompanion_ui', { clear = true })

    -- Icons
    devicons.set_icon({
        codecompanion = { icon = ' ' },
    })
    devicons.set_icon_by_filetype({ codecompanion = 'codecompanion' })

    -- Chat window lifecycle
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = {
            'CodeCompanionChatCreated',
            'CodeCompanionChatOpened',
            'CodeCompanionACPChatRestored',
            'CodeCompanionBackgroundTitleSet',
            'CodeCompanionChatClosed',
        },
        desc = 'Refresh CodeCompanion chat windows',
        callback = function(e)
            vim.defer_fn(function()
                if e.match ~= 'CodeCompanionChatClosed' then
                    refresh_current_chat_window(e)
                end
                refresh_all_chat_titles()
            end, 1)
        end,
    })

    -- Width-aware title truncation
    vim.api.nvim_create_autocmd('WinResized', {
        group = group,
        desc = 'Refresh CodeCompanion chat titles after resize',
        callback = refresh_all_chat_titles,
    })

    -- Read-state and notification cleanup
    vim.api.nvim_create_autocmd('BufEnter', {
        group = group,
        desc = 'Clear reviewed CodeCompanion chat notifications',
        callback = function(e)
            local state = get_turn_state(e.buf)
            if state ~= 'ready' and state ~= 'attention' then
                return
            end

            -- Attention stays active until its approval is handled
            vim.api.nvim_echo({ { '' } }, false)
            if state == 'ready' then
                set_turn_state(e.buf, nil)
                refresh_all_chat_titles()
            end
        end,
    })

    -- Footer values that change when a turn ends or a session is restored
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = {
            'CodeCompanionChatDone',
            'CodeCompanionChatStopped',
            'CodeCompanionACPChatRestored',
        },
        desc = 'Refresh CodeCompanion chat footer',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr then
                return
            end
            vim.defer_fn(function()
                refresh_chat_footer(bufnr)
            end, 50)
        end,
    })

    -- ACP usage fetched after chat lifecycle events
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = {
            'CodeCompanionChatCreated',
            'CodeCompanionChatOpened',
            'CodeCompanionChatDone',
            'CodeCompanionChatStopped',
        },
        desc = 'Refresh CodeCompanion usage limit',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr then
                return
            end
            vim.defer_fn(function()
                refresh_chat_usage(bufnr)
            end, 50)
        end,
    })

    -- Footer identity after adapter or model changes
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = { 'CodeCompanionChatAdapter', 'CodeCompanionChatModel' },
        desc = 'Refresh CodeCompanion chat adapter display',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr then
                return
            end
            vim.schedule(function()
                refresh_chat_footer(bufnr)
                refresh_chat_usage(bufnr)
            end)
        end,
    })

    -- Plan mode in the footer
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeCompanionChatACPModeChanged',
        desc = 'Refresh CodeCompanion ACP mode display',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr then
                return
            end
            vim.schedule(function()
                refresh_chat_footer(bufnr)
            end)
        end,
    })

    -- Tool approval needs attention
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeCompanionToolApprovalRequested',
        desc = 'Mark CodeCompanion chat as needing attention',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr then
                return
            end
            set_turn_state(bufnr, 'attention')
            refresh_all_chat_titles()
        end,
    })

    -- Resume the running state after an approval response
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeCompanionToolApprovalFinished',
        desc = 'Resume CodeCompanion chat after tool approval',
        callback = function(e)
            local choice = e.data and e.data.choice
            if choice ~= 'cancelled' and not tool_labels.is_rejection(choice) then
                vim.api.nvim_echo({ { '' } }, false)
            end

            local bufnr = e.data and e.data.bufnr
            if bufnr and get_turn_state(bufnr) == 'attention' then
                set_turn_state(bufnr, spinners[bufnr] and 'running' or nil)
                refresh_all_chat_titles()
            end
        end,
    })

    -- Start the turn state and buffer spinner
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeCompanionChatSubmitted',
        desc = 'Start CodeCompanion chat turn UI',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end

            set_turn_state(bufnr, 'running')
            refresh_all_chat_titles()
            start_spinner(bufnr)
        end,
    })

    -- Finish the turn state and clear the spinner
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = { 'CodeCompanionChatDone', 'CodeCompanionChatStopped' },
        desc = 'Finish CodeCompanion chat turn UI',
        callback = function(e)
            local bufnr = e.data and e.data.bufnr
            if not bufnr then
                return
            end

            if e.match == 'CodeCompanionChatStopped' then
                set_turn_state(bufnr, 'stopped')
            elseif get_turn_state(bufnr) == 'stopped' then
                -- CodeCompanion can emit Done after Stopped
                set_turn_state(bufnr, nil)
            elseif vim.api.nvim_get_current_buf() == bufnr then
                set_turn_state(bufnr, nil)
            else
                set_turn_state(bufnr, 'ready')
                notify_chat_done(bufnr)
            end
            refresh_all_chat_titles()

            vim.defer_fn(function()
                clear_spinner(bufnr)
            end, 50)
        end,
    })
end

return M
