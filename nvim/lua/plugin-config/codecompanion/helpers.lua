local codecompanion = require('codecompanion')
local config = require('codecompanion.config')

local M = {
    state = {},
    chat = {},
    window = {},
}

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

function M.state.get_current_system_role_prompt()
    local chat = M.state.get_last_chat()
    if not chat or type(chat.messages) ~= 'table' then
        return nil
    end

    local system_role = nil
    for _, entry in ipairs(chat.messages) do
        if entry.role == 'system' then
            system_role = entry.content
        end
    end

    return system_role
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

function M.state.get_cycle_count()
    local bufnr = vim.api.nvim_get_current_buf()
    local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
    return metadata.cycles or 0
end

function M.state.get_adapter_model(adapter)
    return vim.tbl_get(adapter, 'schema', 'model', 'default')
        or vim.tbl_get(adapter, 'defaults', 'session_config_options', 'model')
        or vim.tbl_get(adapter, 'defaults', 'model')
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
function M.state.format_context_usage(adapter)
    local bufnr = vim.api.nvim_get_current_buf()
    local metadata = (_G.codecompanion_chat_metadata or {})[bufnr] or {}
    local tokens = metadata.tokens or 0
    local max_ctx = M.state.get_adapter_context_window(adapter)

    if not max_ctx then
        return string.format('unknown ctx (%d)', tokens)
    end

    return string.format('%.1f%% (%d)', (tokens / max_ctx) * 100, tokens)
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

            chat:add_context({
                role = 'user',
                content = string.format(
                    'Here is the content of %s:%s',
                    normalized_file,
                    content
                ),
            }, 'file', string.format('<file>%s</file>', normalized_file))
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
    local startinsert = opts.startinsert ~= false

    if M.window.try_focus_chat_float() then
        return
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
