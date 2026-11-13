-- luacheck:ignore 631
local ACP = require('codecompanion.acp')
local chat_helpers = require('codecompanion.interactions.chat.helpers')
local extract_text = require('codecompanion.acp.prompt_builder').extract_text
local state_helpers = require('plugin-config.codecompanion.helpers').state
local utils = require('codecompanion.utils')

local M = {}

-- Helpers
local function has_text_content(message)
    local content = message and message.content
    if type(content) == 'string' then
        return content ~= ''
    elseif type(content) ~= 'table' then
        return false
    end
    return vim.iter(content):any(function(part)
        return part.type == 'text' and part.text and part.text ~= ''
    end)
end

local function model_options(connection)
    for _, option in ipairs(connection:get_config_options()) do
        if option.category == 'model' then
            return ACP.flatten_config_options(option.options or {})
        end
    end
    return {}
end

-- ACP connection
local function ensure_connection(chat)
    local handler = require('codecompanion.interactions.chat.acp.handler').new(chat)
    if not handler:ensure_connection() then
        utils.notify('No ACP connection available', vim.log.levels.WARN)
        return false
    end
    if not chat.acp_connection:can_load_session() then
        utils.notify(
            'This ACP adapter does not support loading sessions',
            vim.log.levels.WARN
        )
        return false
    end
    return true
end

local function claude_context_window(connection)
    local models = connection:get_models()
    local model = models and models.currentModelId or ''
    for _, value in ipairs(model_options(connection)) do
        if value.value == model then
            model =
                table.concat({ model, value.name or '', value.description or '' }, ' ')
            break
        end
    end
    return model:lower():match('%f[%w]1m%f[%W]') and 1000000 or 200000
end

local function claude_restored_model(connection, model)
    local normalized = model:lower():gsub('%[1m%]', '')
    for _, value in ipairs(model_options(connection)) do
        if
            type(value.value) == 'string'
            and value.value:lower():gsub('%[1m%]', '') == normalized
        then
            return value.value
        end
    end
    return model
end

-- Replay reconstruction
local function restored_user_turn_count(updates)
    local count = 0
    local in_user_message = false
    for _, update in ipairs(updates) do
        if update.sessionUpdate == 'user_message_chunk' then
            if not in_user_message then
                count = count + 1
                in_user_message = true
            end
        elseif update.sessionUpdate ~= 'agent_thought_chunk' then
            in_user_message = false
        end
    end
    return count
end

local function restore_agent_message_boundaries(updates)
    -- ACP joins consecutive complete agent messages without spacing during restore
    local previous_id
    local previous_text
    for _, update in ipairs(updates) do
        if update.sessionUpdate == 'user_message_chunk' then
            previous_id = nil
            previous_text = nil
        elseif update.sessionUpdate == 'agent_message_chunk' then
            local text = extract_text(update.content)
            if text and text ~= '' then
                if
                    previous_id
                    and update.messageId
                    and update.messageId ~= previous_id
                    and not previous_text:match('\n$')
                    and not text:match('^\n')
                then
                    update.content.text = '\n\n' .. text
                    text = update.content.text
                end
                previous_id = update.messageId or previous_id
                previous_text = text
            end
        end
    end
end

local function restored_messages(updates)
    local messages = {}
    for _, update in ipairs(updates) do
        local role = ({
            user_message_chunk = 'user',
            agent_message_chunk = 'llm',
        })[update.sessionUpdate]
        local text = role and extract_text(update.content)
        if text and text ~= '' then
            local previous = messages[#messages]
            if previous and previous.role == role then
                previous.content = previous.content .. text
            else
                table.insert(messages, { role = role, content = text })
            end
        end
    end
    return messages
end

local function restore_header_metadata(chat, headers)
    local lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
    local marker = ' |  '
    local header_index = 1
    for i, line in ipairs(lines) do
        local prefix, label, timestamp =
            line:match('^(## .-)%((.-)%)' .. marker .. '(.*)$')
        if prefix then
            local header = headers[header_index] or {}
            if header.model then
                label = state_helpers.format_model_label(chat.adapter, header.model)
                local effort = header.effort
                    or state_helpers.get_adapter_effort(chat.adapter)
                label = effort and string.format('%s %s', label, effort) or label
            end
            local restored_timestamp = type(header.timestamp) == 'string'
                    and utils.timestamp_from_iso(header.timestamp)
                or nil
            if restored_timestamp then
                timestamp = os.date('%Y-%m-%d %H:%M:%S', restored_timestamp)
            end
            local restored_line = prefix .. '(' .. label .. ')' .. marker .. timestamp
            if restored_line ~= line then
                vim.api.nvim_buf_set_text(
                    chat.bufnr,
                    i - 1,
                    0,
                    i - 1,
                    #line,
                    { restored_line }
                )
            end
            header_index = header_index + 1
        end
    end
end

-- Native transcript metadata
-- Read metadata omitted by ACP replay from the agent's native session file
local function restored_session_metadata(entry)
    local tokens, context_window
    local model, effort
    local headers = {}
    local awaiting_agent = false
    local ok, iter = pcall(io.lines, entry.path)
    if not ok then
        return nil, headers
    end
    for line in iter do
        local decoded_ok, d = pcall(vim.json.decode, line)
        if decoded_ok then
            local role
            if entry.adapter == 'codex' then
                local payload = d.payload or {}
                if d.type == 'turn_context' and type(payload.model) == 'string' then
                    model = payload.model
                    effort = type(payload.effort) == 'string' and payload.effort or nil
                end
                local total =
                    vim.tbl_get(payload, 'info', 'last_token_usage', 'total_tokens')
                if type(total) == 'number' then
                    tokens = total
                end
                local size = vim.tbl_get(payload, 'info', 'model_context_window')
                if type(size) == 'number' then
                    context_window = size
                end
                if d.type == 'response_item' and payload.type == 'message' then
                    role = ({ user = 'user', assistant = 'agent' })[payload.role]
                    local kinds = vim.tbl_get(
                        payload,
                        'internal_chat_message_metadata_passthrough',
                        'content_item_kinds'
                    ) or {}
                    if
                        role == 'user'
                        and #kinds > 0
                        and not vim.iter(kinds):any(function(kind)
                            return vim.startswith(kind, 'user.')
                        end)
                    then
                        role = nil
                    end
                end
            elseif entry.adapter == 'claude_code' then
                local message = d.message or {}
                if d.type == 'assistant' and type(message.model) == 'string' then
                    model = message.model
                    effort = type(d.effort) == 'string' and d.effort or nil
                end
                local usage = message.usage
                if usage then
                    tokens = (tonumber(usage.input_tokens) or 0)
                        + (tonumber(usage.output_tokens) or 0)
                        + (tonumber(usage.cache_read_input_tokens) or 0)
                        + (tonumber(usage.cache_creation_input_tokens) or 0)
                end
                if has_text_content(message) then
                    role = ({ user = 'user', assistant = 'agent' })[d.type]
                end
            end
            if role == 'user' then
                awaiting_agent = true
            elseif role == 'agent' and awaiting_agent then
                table.insert(headers, {
                    timestamp = d.timestamp,
                    model = model,
                    effort = effort,
                })
                awaiting_agent = false
            end
        end
    end
    return tokens, headers, model, effort, context_window
end

-- Restored context
local function restore_context(context, paths, icon, path)
    if not paths[path] then
        table.insert(context, { icon = icon, path = path })
        paths[path] = true
    end
end

-- Extract context markers and discard encoded media from ACP replay updates
local function collect_session_update(update, updates, context, paths)
    local text = vim.tbl_get(update, 'content', 'text')
    if type(text) == 'string' then
        for _, extension in ipairs({ 'png', 'jpg', 'jpeg', 'svg', 'bmp' }) do
            local pattern = 'Image path: (/%S-%.' .. extension .. ')'
            text = text:gsub(pattern, function(path)
                restore_context(context, paths, '󰋩', path)
                return ''
            end)
        end
        text = text:gsub(
            'Sharing the following file as context: (/%S+)',
            function(candidate)
                local path = candidate
                while not vim.uv.fs_stat(path) and path ~= '/' do
                    path = path:sub(1, -2)
                end
                if path == '/' then
                    return candidate
                end
                restore_context(context, paths, '󰈙', path)
                return candidate:sub(#path + 1)
            end
        )
        text = text:gsub('Sharing `([^`]+)`:', function(path)
            restore_context(context, paths, '󰈙', path)
            return ''
        end)
        text = text:gsub('(<comment [^\n]+>\n)````[^\n]*\n[ \t\n]-````\n', '%1')
        text = text:gsub('(<comment [^\n]+>)\n(```+)', '%1\n\n%2')
        text = text:gsub('</comment>(%S)', '</comment>\n\n%1')
        update.content.text = text
        if text == '' then
            return
        end
    end
    if
        vim.tbl_get(update, 'content', 'type') == 'image'
        or type(text) == 'string' and text:match('^%[@image%]%(data:image/')
    then
        return
    end
    table.insert(updates, update)
end

-- Session loading
-- Reuse a compatible empty chat for the selected session, otherwise create one
local function target_chat(chat, entry)
    local reusable = chat
        and chat.adapter
        and chat.adapter.name == entry.adapter
        and (not entry.cwd or chat.opts.cwd == entry.cwd)
        and not chat._acp_session_loaded
        and (
            (chat.cycle or 1) <= 1
            or not chat_helpers.has_user_messages(chat.messages or {})
        )

    if reusable then
        return chat
    end

    local args = {
        adapter = entry.adapter,
        cwd = entry.cwd or vim.uv.cwd(),
        buffer_context = require('codecompanion.utils.context').get(),
        auto_submit = false,
    }
    args.callbacks =
        require('codecompanion.interactions.shared.rules.helpers').add_callbacks(args)
    local new_chat = require('codecompanion.interactions.chat').new(args)

    if not new_chat then
        local labels = { claude_code = 'Claude', codex = 'Codex' }
        utils.notify(
            'Failed to create ' .. (labels[entry.adapter] or entry.adapter) .. ' chat',
            vim.log.levels.ERROR
        )
    end

    return new_chat
end

local function load_entry(chat, entry)
    local restored_tokens, restored_headers, restored_model, restored_effort, restored_context_window =
        restored_session_metadata(entry)
    if not ensure_connection(chat) then
        return
    end

    local updates = {}
    local restored_context = {}
    local restored_context_paths = {}
    local ok = chat.acp_connection:load_session(entry.session_id, {
        on_session_update = function(update)
            collect_session_update(
                update,
                updates,
                restored_context,
                restored_context_paths
            )
        end,
    })
    if not ok then
        return utils.notify('Failed to load ACP session', vim.log.levels.ERROR)
    end

    if restored_model then
        local model = entry.adapter == 'claude_code'
                and claude_restored_model(chat.acp_connection, restored_model)
            or restored_model
        local settings_ok = chat.acp_connection:set_model(model)
        if settings_ok and restored_effort then
            local effort_config_id = entry.adapter == 'claude_code' and 'effort'
                or 'reasoning_effort'
            settings_ok =
                chat.acp_connection:set_config_option(effort_config_id, restored_effort)
        end
        if not settings_ok then
            utils.notify(
                'Failed to restore ACP session model settings',
                vim.log.levels.WARN
            )
        end
    end
    if entry.adapter == 'claude_code' then
        restored_context_window = claude_context_window(chat.acp_connection)
    end
    local models = chat.acp_connection:get_models()
    local restored_context_model = models and models.currentModelId
    if entry.adapter == 'codex' and restored_context_model ~= restored_model then
        restored_context_window = nil
    end

    restore_agent_message_boundaries(updates)
    local restored_turns = restored_user_turn_count(updates)
    require('codecompanion.interactions.chat.acp.commands').link_buffer_to_session(
        chat.bufnr,
        chat.acp_connection.session_id
    )
    require('codecompanion.interactions.chat.acp.render').restore_session(chat, updates)
    restore_header_metadata(chat, restored_headers)
    chat._acp_restored_messages = restored_messages(updates)
    for _, context in ipairs(restored_context) do
        chat.context:add({
            id = ('%s %s'):format(context.icon, context.path),
            path = context.path,
        })
    end
    chat.cycle = math.max(chat.cycle or 1, restored_turns + 1)
    chat.tokens = restored_tokens or chat.tokens
    if restored_context_model and restored_context_window then
        chat.context_windows = chat.context_windows or {}
        if type(chat.context_windows[restored_context_model]) ~= 'number' then
            chat.context_windows[restored_context_model] = restored_context_window
        end
    end
    chat._acp_session_loaded = true

    local restored_event = {
        bufnr = chat.bufnr,
        id = chat.id,
        session_id = chat.acp_connection.session_id,
        title = chat.title,
    }
    if entry.title and entry.title ~= '' then
        chat:set_title(entry.title)
        restored_event.title = entry.title
    end
    utils.fire('ACPChatRestored', restored_event)
end

function M.load(chat, entry)
    if entry.cwd then
        local stat = vim.uv.fs_stat(entry.cwd)
        if not stat or stat.type ~= 'directory' then
            return utils.notify(
                'Session directory not found: ' .. entry.cwd,
                vim.log.levels.ERROR
            )
        end
    end
    local selected_chat = target_chat(chat, entry)
    if selected_chat then
        load_entry(selected_chat, entry)
    end
end

return M
