local ACP = require('codecompanion.acp')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local u = require('utils')

local M = {
    repo = {},
    state = {},
    chat = {},
    window = {},
    acp = {},
    usage = {},
}

-- Repo/filesystem
function M.repo.git_root_or_notify(path)
    local root = u.git_root(path)
    if root then
        return root
    end

    vim.notify(
        'Not inside a Git repository. Could not determine the project root.',
        vim.log.levels.ERROR
    )
    return nil
end

function M.repo.git_root_file(filename, path)
    vim.validate('filename', filename, 'string')

    local root = u.git_root(path)
    if not root then
        return nil
    end

    local filepath = vim.fs.joinpath(root, filename)
    local stat = vim.uv.fs_stat(filepath)
    if not stat or stat.type ~= 'file' then
        return nil
    end

    return filepath
end

-- State
local function get_last_chat()
    local ok, chat = pcall(codecompanion.last_chat)
    if ok and chat then
        return chat
    end
    return nil
end

local function get_or_create_chat()
    return get_last_chat() or codecompanion.chat()
end

function M.state.get_chat_label(chat)
    local label = nil

    pcall(function()
        for _, entry in pairs(codecompanion.buf_get_chat()) do
            if entry.chat == chat then
                label = entry.name
                break
            end
        end
    end)

    if not label or label == '' then
        label = 'Chat ' .. chat.bufnr
    end

    if chat.opts and chat.opts.title and chat.opts.title ~= '' then
        label = string.format('%s · %s', label, chat.opts.title)
    end

    return label
end

function M.state.for_each_open_chat(callback)
    local ok, chats = pcall(codecompanion.buf_get_chat)
    if not ok or not chats then
        return
    end

    for _, entry in pairs(chats) do
        callback(entry.chat, entry)
    end
end

local function get_open_chat_count()
    local count = 0
    M.state.for_each_open_chat(function()
        count = count + 1
    end)
    return count
end

function M.state.format_open_chat_count()
    local count = get_open_chat_count()
    return ({
        [1] = '¹',
        [2] = '²',
        [3] = '³',
        [4] = '⁴',
        [5] = '⁵',
    })[count] or tostring(count)
end

function M.state.get_last_user_prompt(chat)
    chat = chat or get_last_chat()
    if not chat or type(chat.messages) ~= 'table' then
        return nil
    end

    for i = #chat.messages, 1, -1 do
        local msg = chat.messages[i]
        if msg.role == 'user' then
            return msg.content
        end
    end

    return nil
end

function M.state.get_cycle_count(chat)
    return (chat and chat.cycle) or 0
end

function M.state.get_adapter_model(adapter)
    return vim.tbl_get(adapter, 'schema', 'model', 'default')
        or vim.tbl_get(adapter, 'defaults', 'session_config_options', 'model')
        or vim.tbl_get(adapter, 'defaults', 'model')
end

function M.state.get_chat_model_label(chat)
    local adapter = chat and chat.adapter
    if not adapter then
        return 'unknown'
    end

    local labels = { claude_code = 'Claude', codex = 'Codex' }
    return labels[adapter.name] or M.state.get_adapter_model(adapter) or adapter.name
end

function M.state.get_chat_title(chat, entry)
    if chat and chat.opts and chat.opts.title and chat.opts.title ~= '' then
        return chat.opts.title
    end

    local prompt = M.state.get_last_user_prompt(chat)
    if prompt and prompt ~= '' then
        return prompt
    end

    if entry and entry.name then
        return entry.name
    end

    return chat and M.state.get_chat_label(chat) or 'Chat'
end

function M.state.get_chat_number(entry)
    local number = (entry and entry.name or ''):match('Chat%s+(%d+)')
    return number and ('#' .. number) or ('#' .. tostring(entry and entry.bufnr or '?'))
end

function M.state.get_adapter_effort(adapter)
    local effort = vim.tbl_get(adapter, 'defaults', 'effort')
        or vim.tbl_get(adapter, 'schema', 'reasoning.effort', 'default')
        or vim.tbl_get(adapter, 'schema', 'reasoning_effort', 'default')

    if effort and effort ~= '' and effort ~= 'none' then
        return tostring(effort)
    end
end

function M.state.provider_icon(name)
    name = (name or ''):lower()
    if name:find('claude') or name:find('anthropic') then
        return '' -- cod-sparkle
    elseif name:find('codex') or name:find('openai') or name:find('gpt') then
        return '󰙴' -- md-creation
    elseif name:find('gemini') or name:find('google') then
        return '󰊭' -- md-google
    end
    return '󰚩' -- md-robot
end

local function get_adapter_context_window(adapter)
    if type(adapter) ~= 'table' then
        return nil
    end

    local model = M.state.get_adapter_model(adapter)
    if not model then
        return nil
    end

    local context_window = vim.tbl_get(
        adapter,
        'schema',
        'model',
        'choices',
        model,
        'meta',
        'context_window'
    )
    if type(context_window) == 'number' then
        return context_window
    end

    return nil
end

function M.state.format_context_usage(chat)
    -- The plugin only tracks tokens live, from the first turn onward, so a
    -- freshly restored chat reads 0 until then
    local tokens = (chat and chat.tokens) or 0

    local max_ctx = get_adapter_context_window(chat and chat.adapter)
    if not max_ctx then
        return 'unknown ctx'
    end

    return string.format('%.1f%%', (tokens / max_ctx) * 100)
end

-- ACP agent config files
local function read_json(path)
    local ok, data = pcall(vim.json.decode, u.read_file(path) or '')
    return ok and data or {}
end

local function read_toml_value(path, key)
    return (u.read_file(path) or ''):match(key .. '%s*=%s*["\']([^"\']+)')
end

function M.acp.claude_config()
    local settings = read_json(vim.env.HOME .. '/.claude/settings.json')
    return {
        model = settings.model,
        effort = settings.effortLevel,
        mode = vim.tbl_get(settings, 'permissions', 'defaultMode'),
    }
end

function M.acp.codex_config()
    local path = vim.env.HOME .. '/.codex/config.toml'
    return {
        model = read_toml_value(path, 'model'),
        effort = read_toml_value(path, 'model_reasoning_effort'),
    }
end

-- ACP session state
local function acp_value_is_plan(value)
    local text = (tostring(value.value or '') .. tostring(value.name or '')):lower()
    return text:find('plan', 1, true) ~= nil
end

local function acp_value_matches(value, expected)
    if not expected then
        return false
    end

    local normalized = tostring(expected):lower()
    return tostring(value.value or ''):lower() == normalized
        or tostring(value.name or ''):lower() == normalized
end

local function acp_default_mode(chat)
    local mode =
        vim.tbl_get(chat, 'adapter', 'defaults', 'session_config_options', 'mode')
    if type(mode) == 'function' then
        mode = mode(chat.adapter)
    end
    return mode
end

local function acp_mode(chat)
    local connection = chat and chat.acp_connection
    if not connection then
        return nil
    end

    local opt = vim.iter(connection:get_config_options()):find(function(opt)
        if opt.category == 'mode' and opt.type == 'select' then
            return true
        end
    end)
    if not opt then
        return nil
    end

    local values = ACP.flatten_config_options(opt.options or {})
    local current = vim.iter(values):find(function(value)
        return value.value == opt.currentValue
    end) or { value = opt.currentValue, name = opt.currentValue }
    return opt,
        {
            value = current.value,
            name = current.name,
            is_plan = acp_value_is_plan(current),
        },
        values
end

function M.acp.mode_label(chat)
    local _, mode = acp_mode(chat)
    if mode and mode.is_plan then
        return 'plan'
    end
end

function M.acp.toggle_plan_mode(chat)
    if not chat or not chat.acp_connection then
        vim.notify('No ACP connection available', vim.log.levels.WARN)
        return
    end

    local opt, current, values = acp_mode(chat)
    if not opt then
        vim.notify('This ACP adapter does not expose a mode option', vim.log.levels.WARN)
        return
    end

    local want_plan = not (current and current.is_plan)
    local target = not want_plan
        and vim.iter(values):find(function(value)
            return value.value ~= opt.currentValue
                and acp_value_matches(value, acp_default_mode(chat))
        end)

    target = target
        or vim.iter(values):find(function(value)
            return value.value ~= opt.currentValue
                and acp_value_is_plan(value) == want_plan
        end)

    if not target then
        vim.notify(
            'No alternate ACP mode value is available for this adapter',
            vim.log.levels.WARN
        )
        return
    end

    if not chat.acp_connection:set_config_option(opt.id, target.value) then
        vim.notify('Failed to change ACP mode', vim.log.levels.ERROR)
        return
    end

    vim.notify('ACP mode: ' .. (target.name or target.value), vim.log.levels.INFO)
    vim.api.nvim_exec_autocmds('User', {
        pattern = 'CodeCompanionChatACPModeChanged',
        data = {
            bufnr = chat.bufnr,
            session_id = chat.acp_connection.session_id,
        },
    })
end

-- Usage limits: shell out to the ai_session_usage script
local usage_cache = {}
local usage_labels = { claude_code = 'Claude', codex = 'Codex' }
local usage_flags = { claude_code = '--claude', codex = '--codex' }
local usage_last_run = {}
local USAGE_TTL = 120

-- Run the ai_session_usage script and hand back its ANSI-stripped output
function M.usage.run(name, cb)
    vim.system({ 'ai_session_usage', usage_flags[name] }, { text = true }, function(obj)
        local out = (obj.stdout or ''):gsub('\27%[[0-9;]*m', ''):gsub('%s+$', '')
        cb(out)
    end)
end

function M.usage.get(name)
    return usage_cache[name]
end

-- Cache the 5h usage for claude_code/codex, parsed from the script output; cb
-- re-renders the footer once data lands. Results are reused for USAGE_TTL
-- seconds per adapter
function M.usage.refresh(name, cb)
    if not usage_labels[name] then
        return
    end
    -- Throttle on time regardless of success so a rate-limited window can recover
    if os.time() - (usage_last_run[name] or 0) < USAGE_TTL then
        if cb then
            vim.schedule(cb)
        end
        return
    end
    usage_last_run[name] = os.time()
    M.usage.run(name, function(out)
        local label = usage_labels[name]
        local pct, reset = out:match(label .. '%s+5h:%s+([%d%.]+)%%%s+%(resets ([^)]+)%)')
        pct = pct or out:match(label .. '%s+5h:%s+([%d%.]+)')
        if pct then
            usage_cache[name] = { pct = tonumber(pct), reset = reset }
        end
        if cb then
            vim.schedule(cb)
        end
    end)
end

-- Chat
function M.chat.add_context(files)
    local chat = get_or_create_chat()

    for _, file in ipairs(files) do
        local content = u.read_file(file)

        if not content then
            vim.notify('Could not read file: ' .. file, vim.log.levels.ERROR)
        else
            local normalized_file = vim.fs.normalize(file)
            local id = string.format('<file>%s</file>', normalized_file)

            -- Add context manually (rather than via chat:add_context) because that helper
            -- drops msg.context.path which ACP adapters need to see the file
            chat:add_message({
                role = 'user',
                content = string.format(
                    'Here is the content of %s:%s',
                    normalized_file,
                    content
                ),
            }, {
                visible = false,
                context = { id = id, path = normalized_file },
                _meta = { tag = 'file' },
            })
            chat.context:add({ id = id, path = normalized_file })
        end
    end

    M.window.focus_or_toggle_chat({ startinsert = false })
end

function M.chat.run_slash_command(name, opts)
    opts = opts or {}

    local chat = get_or_create_chat()
    local cmd = config.interactions.chat.slash_commands[name]

    if cmd and type(cmd.callback) == 'function' then
        cmd.callback(chat, opts)
        M.window.focus_or_toggle_chat({ startinsert = false })
    else
        vim.notify('Slash command not found: ' .. tostring(name), vim.log.levels.ERROR)
    end
end

function M.chat.submit_user_message(chat, content)
    chat:add_buf_message({
        role = config.constants.USER_ROLE,
        content = content,
    })
    chat:submit()
end

-- Chat windows
function M.window.try_focus_chat_float()
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        local conf = vim.api.nvim_win_get_config(win_id)
        local bufnr = vim.api.nvim_win_get_buf(win_id)
        local filetype = vim.bo[bufnr].filetype

        if conf.focusable and conf.relative ~= '' and filetype == 'codecompanion' then
            vim.api.nvim_set_current_win(win_id)
            return true
        end
    end

    return false
end

function M.window.focus_or_toggle_chat(opts)
    opts = opts or {}

    if M.window.try_focus_chat_float() then
        return
    end

    local startinsert
    if opts.startinsert ~= nil then
        startinsert = opts.startinsert
    else
        startinsert = next(codecompanion.buf_get_chat()) == nil
    end

    codecompanion.toggle_chat()

    if startinsert then
        vim.defer_fn(function()
            vim.cmd.startinsert()
        end, 10)
    end
end

function M.window.toggle_cc_zoom()
    local win = vim.api.nvim_get_current_win()
    local win_config = vim.api.nvim_win_get_config(win)
    local saved = vim.w.cc_default_float_conf

    if saved then
        vim.api.nvim_win_set_config(win, saved)
        vim.w.cc_default_float_conf = nil
        return
    end

    vim.w.cc_default_float_conf = win_config
    vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        row = 1,
        col = math.floor(vim.o.columns * 0.10),
        width = math.floor(vim.o.columns * 0.80),
        height = vim.o.lines - 4,
    })
end

return M
