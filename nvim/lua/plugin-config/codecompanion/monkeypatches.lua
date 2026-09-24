-- luacheck:ignore 631
local utils = require('codecompanion.utils')
local state_helpers = require('plugin-config.codecompanion.helpers').state
local u = require('utils')

local M = {}

local applied = false

local function patch_acp_model_choices()
    local change_adapter =
        require('codecompanion.interactions.chat.keymaps.change_adapter')
    -- Upstream PR: https://github.com/olimorris/codecompanion.nvim/pull/3020
    change_adapter.list_acp_models = function()
        return nil
    end
end

local function patch_tool_approval_notification()
    -- Identify the requesting chat because CodeCompanion's generic notification
    -- is ambiguous when several chats are open
    local approval_prompt =
        require('codecompanion.interactions.chat.helpers.approval_prompt')
    local original_request = approval_prompt.request

    approval_prompt.request = function(chat, opts)
        local original_notify = utils.notify

        utils.notify = function(msg, level)
            if msg == 'Tool approval required' then
                msg = string.format('%s: %s', msg, state_helpers.get_chat_label(chat))
                level = vim.log.levels.WARN
            end

            return original_notify(msg, level)
        end

        local ok, result = pcall(original_request, chat, opts)
        utils.notify = original_notify

        if not ok then
            error(result)
        end

        return result
    end
end

local function patch_acp_cwd()
    -- Capture the invoking buffer's Git root when creating a chat and keep it on reopen
    -- Keep directories per connection so overlapping requests cannot affect each other
    local Chat = require('codecompanion.interactions.chat')
    local new_chat = Chat.new
    Chat.new = function(args)
        if not args.cwd then
            local context = args.buffer_context or {}
            local path = context.buftype == '' and context.path or ''
            args.cwd = u.git_root(path) or vim.uv.cwd()
        end
        return new_chat(args)
    end

    local Connection = require('codecompanion.acp')
    local new = Connection.new
    Connection.new = function(...)
        local connection = new(...)
        local cwd = connection.chat and connection.chat.opts.cwd or vim.uv.cwd()
        local job = connection.methods.job
        connection.methods.job = function(cmd, opts, ...)
            opts.cwd = cwd
            return job(cmd, opts, ...)
        end

        local send_rpc_request = connection.send_rpc_request
        connection.send_rpc_request = function(self, method, params, ...)
            if
                method == Connection.METHODS.SESSION_NEW
                or method == Connection.METHODS.SESSION_LOAD
            then
                -- Session requests can yield; retain this connection's launch directory
                params = vim.tbl_extend('force', params, { cwd = cwd })
            end
            return send_rpc_request(self, method, params, ...)
        end
        return connection
    end
end

local function patch_image_paths()
    -- ACP image blocks discard local paths, so persist each path as hidden text
    -- that can be recovered when the agent session is restored
    local Chat = require('codecompanion.interactions.chat')
    local add_image_message = Chat.add_image_message

    Chat.add_image_message = function(self, image, opts)
        if image.path then
            self:add_message({
                role = 'user',
                content = 'Image path: ' .. image.path,
            }, { visible = false })
        end
        return add_image_message(self, image, opts)
    end
end

local function patch_acp_context_separator()
    -- ACP shares each file as a bare "Sharing the following file as context:
    -- <path>" block with no trailing newline, so consecutive markers and the
    -- following user prompt render glued together. Terminate each marker with
    -- a newline to keep them on their own lines
    local helpers = require('codecompanion.adapters.acp.helpers')
    local form_messages = helpers.form_messages

    helpers.form_messages = function(...)
        local parts = form_messages(...)
        for _, part in ipairs(parts) do
            if
                type(part.text) == 'string'
                and part.text:match('^Sharing the following file as context:')
            then
                part.text = part.text .. '\n'
            end
        end
        return parts
    end
end

local function patch_acp_context_window()
    -- Preserve the context size reported with ACP token usage because
    -- CodeCompanion otherwise discards it
    local Connection = require('codecompanion.acp')
    local handle_message = Connection.handle_incoming_request_or_notification

    Connection.handle_incoming_request_or_notification = function(self, message)
        local update = type(message) == 'table'
            and vim.tbl_get(message, 'params', 'update')
        if
            update
            and update.sessionUpdate == 'usage_update'
            and type(update.size) == 'number'
        then
            local chat = self:get_chat(message.params.sessionId)
            local models = self:get_models()
            local model = models and models.currentModelId
            if chat and model then
                chat.context_windows = chat.context_windows or {}
                chat.context_windows[model] = update.size
            end
        end

        return handle_message(self, message)
    end
end

function M.apply()
    if applied then
        return
    end

    patch_acp_model_choices()
    patch_tool_approval_notification()
    patch_acp_cwd()
    patch_image_paths()
    patch_acp_context_separator()
    patch_acp_context_window()

    applied = true
end

return M
