local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local u = require('utils')

local M = {
    repo = {},
    state = {},
    chat = {},
    window = {},
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
function M.state.get_last_chat()
    local ok, chat = pcall(codecompanion.last_chat)
    if ok and chat then
        return chat
    end
    return nil
end

function M.chat.get_or_create_chat()
    return M.state.get_last_chat() or codecompanion.chat()
end

function M.state.get_last_user_prompt()
    local chat = M.state.get_last_chat()
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

function M.state.get_adapter_context_window(adapter)
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
    -- Prefer the live token count the plugin maintains on the chat object; fall
    -- back to the history estimate for a restored chat before its first turn
    local tokens = chat and chat.tokens
    if not tokens then
        local bufnr = (chat and chat.bufnr) or vim.api.nvim_get_current_buf()
        local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
        tokens = metadata.tokens or 0
    end

    local max_ctx = M.state.get_adapter_context_window(chat and chat.adapter)
    if not max_ctx then
        return 'unknown ctx'
    end

    return string.format('%.1f%%', (tokens / max_ctx) * 100)
end

-- Usage limits: shell out to the ai_usage script
local usage_cache = {}
local usage_labels = { claude_code = 'Claude', codex = 'Codex' }
local usage_last_run = 0
local USAGE_TTL = 120

-- Run the ai_usage script and hand back its ANSI-stripped output
function M.usage.run(cb)
    vim.system({ 'ai_usage' }, { text = true }, function(obj)
        local out = (obj.stdout or ''):gsub('\27%[[0-9;]*m', ''):gsub('%s+$', '')
        cb(out)
    end)
end

function M.usage.get(name)
    return usage_cache[name]
end

-- Cache the 5h usage for claude_code/codex, parsed from the script output; cb
-- re-renders the footer once data lands. One run populates both adapters, and
-- results are reused for USAGE_TTL seconds
function M.usage.refresh(name, cb)
    if not usage_labels[name] then
        return
    end
    -- Throttle on time regardless of success so a rate-limited window can recover
    if os.time() - usage_last_run < USAGE_TTL then
        if cb then
            vim.schedule(cb)
        end
        return
    end
    usage_last_run = os.time()
    M.usage.run(function(out)
        for adapter, label in pairs(usage_labels) do
            local pct, reset =
                out:match(label .. '%s+5h:%s+([%d%.]+)%%%s+%(resets ([^)]+)%)')
            pct = pct or out:match(label .. '%s+5h:%s+([%d%.]+)')
            if pct then
                usage_cache[adapter] = { pct = tonumber(pct), reset = reset }
            end
        end
        if cb then
            vim.schedule(cb)
        end
    end)
end

-- Chat
function M.chat.add_context(files)
    local chat = M.chat.get_or_create_chat()

    for _, file in ipairs(files) do
        local fd = io.open(file, 'r')
        local content
        if fd then
            content = fd:read('*a')
            fd:close()
        end

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

    local chat = M.chat.get_or_create_chat()
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
    chat:add_message({
        role = config.constants.USER_ROLE,
        content = content,
    }, {
        visible = false,
    })
    chat:submit({ auto_submit = true })
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
