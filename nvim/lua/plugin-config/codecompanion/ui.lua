local codecompanion = require('codecompanion')
local devicons = require('nvim-web-devicons')
local telescope_action_state = require('telescope.actions.state')

local acp_helpers = require('plugin-config.codecompanion.helpers').acp
local state_helpers = require('plugin-config.codecompanion.helpers').state
local usage_helpers = require('plugin-config.codecompanion.helpers').usage

local M = {}

-- Helpers
local function cwd_footer(chat)
    local cwd = vim.uv.cwd()
    if chat and chat.adapter and chat.adapter.type == 'acp' then
        if not chat.opts.cwd or chat.opts.cwd == '' then
            chat.opts.cwd = cwd
        end
        cwd = chat.opts.cwd
    end

    return cwd and cwd:match('([^/]+/[^/]+/[^/]+)$') or ''
end

local function chat_title(chat)
    return string.format(
        '󰭹%s · %s',
        state_helpers.format_open_chat_count(),
        state_helpers.get_chat_label(chat)
    )
end

local function chat_footer(chat)
    local parts = {}
    local adapter = chat and chat.adapter
    if adapter then
        -- acp agents show their name (Claude/Codex); http shows the model
        local labels = { claude_code = 'Claude', codex = 'Codex' }
        local label = labels[adapter.name]
            or state_helpers.get_adapter_model(adapter)
            or adapter.name
        local mode = acp_helpers.mode_label(chat)
        if mode then
            label = string.format('%s (%s)', label, mode)
        end
        table.insert(
            parts,
            string.format('%s %s', state_helpers.provider_icon(adapter.name), label)
        )
    end
    local cwd = cwd_footer(chat)
    if cwd ~= '' then
        table.insert(parts, ' ' .. cwd)
    end
    if chat then
        table.insert(parts, string.format(' %d', state_helpers.get_cycle_count(chat)))
        table.insert(
            parts,
            string.format(' %s', state_helpers.format_context_usage(chat))
        )
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
    end
    return table.concat(parts, ' · ')
end

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

local function set_chat_win_title(e)
    e = e or {}

    local ok, chat = pcall(function()
        return codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    end)

    if not ok or not chat or not chat.ui or not chat.ui.winnr then
        vim.defer_fn(function()
            local picker =
                telescope_action_state.get_current_picker(vim.api.nvim_get_current_buf())
            if picker then
                vim.api.nvim_win_close(picker.prompt_win, true)
            end
        end, 50)

        vim.wait(100)

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

-- Spinner internals
vim.api.nvim_set_hl(0, 'CodeCompanionSpinner', { fg = '#7f848e' })

local spinner = {
    states = {
        '⢎ ',
        '⠎⠁',
        '⠊⠑',
        '⠈⠱',
        ' ⡱',
        '⢀⡰',
        '⢄⡠',
        '⢆⡀',
    },
    ns = vim.api.nvim_create_namespace('codecompanion_spinner'),
    bufnr = nil,
    timer = nil,
    index = 1,
}

local function spinner_winnr()
    if not (spinner.bufnr and vim.api.nvim_buf_is_valid(spinner.bufnr)) then
        return nil
    end
    local winnr = vim.fn.bufwinid(spinner.bufnr)
    if winnr == -1 or not vim.api.nvim_win_is_valid(winnr) then
        return nil
    end
    return winnr
end

local function clear_spinner()
    if spinner.timer then
        spinner.timer:stop()
        spinner.timer:close()
        spinner.timer = nil
    end

    if spinner.bufnr and vim.api.nvim_buf_is_valid(spinner.bufnr) then
        vim.api.nvim_buf_clear_namespace(spinner.bufnr, spinner.ns, 0, -1)
    end

    spinner.bufnr = nil
end

local function update_spinner()
    if not spinner_winnr() then
        return
    end

    local last_line = vim.api.nvim_buf_line_count(spinner.bufnr) - 1
    vim.api.nvim_buf_set_extmark(spinner.bufnr, spinner.ns, last_line, 0, {
        id = 1,
        virt_text = { { spinner.states[spinner.index], 'CodeCompanionSpinner' } },
        virt_text_pos = 'right_align',
    })
    spinner.index = spinner.index % #spinner.states + 1
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
    -- Icons
    devicons.set_icon({
        codecompanion = { icon = ' ' },
    })
    devicons.set_icon_by_filetype({ codecompanion = 'codecompanion' })

    -- Window title
    vim.api.nvim_create_autocmd('User', {
        pattern = {
            'CodeCompanionChatCreated',
            'CodeCompanionChatOpened',
            'CodeCompanionHistoryTitleSet',
            'CodeCompanionChatClosed',
        },
        desc = 'Set CodeCompanion chat window title after chat events',
        callback = function(e)
            vim.defer_fn(function()
                set_chat_win_title(e)
                refresh_all_chat_titles()
            end, 1)
        end,
    })

    -- Window footer (statusline)
    vim.api.nvim_create_autocmd('User', {
        pattern = { 'CodeCompanionChatDone', 'CodeCompanionChatStopped' },
        desc = 'Refresh CodeCompanion chat footer context usage when a turn ends',
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

    vim.api.nvim_create_autocmd('User', {
        pattern = {
            'CodeCompanionChatCreated',
            'CodeCompanionChatOpened',
            'CodeCompanionChatDone',
            'CodeCompanionChatStopped',
        },
        desc = 'Refresh CodeCompanion usage limit for the chat footer',
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

    vim.api.nvim_create_autocmd('User', {
        pattern = { 'CodeCompanionChatAdapter', 'CodeCompanionChatModel' },
        desc = 'Refresh CodeCompanion chat footer when the adapter or model changes',
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

    vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionChatACPModeChanged',
        desc = 'Refresh CodeCompanion chat footer when the ACP mode changes',
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

    -- Spinner lifecycle
    vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionChatSubmitted',
        desc = 'Start CodeCompanion spinner when a chat turn begins',
        callback = function(e)
            clear_spinner()

            local bufnr = e.data and e.data.bufnr
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end

            spinner.bufnr = bufnr
            spinner.timer = vim.uv.new_timer()
            spinner.timer:start(0, 100, vim.schedule_wrap(update_spinner))
        end,
    })

    vim.api.nvim_create_autocmd('User', {
        pattern = { 'CodeCompanionChatDone', 'CodeCompanionChatStopped' },
        desc = 'Clear CodeCompanion spinner when a chat turn ends',
        callback = function()
            vim.defer_fn(clear_spinner, 50)
        end,
    })
end

return M
