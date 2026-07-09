-- luacheck:ignore 631
local utils = require('codecompanion.utils')
local state_helpers = require('plugin-config.codecompanion.helpers').state
local u = require('utils')

local M = {}

local applied = false

local function patch_acp_model_choices()
    -- Upstream PR: https://github.com/olimorris/codecompanion.nvim/pull/3020
    require('codecompanion.interactions.chat.keymaps.change_adapter').list_acp_models = function()
        return nil
    end
end

local function patch_tool_approval_notification()
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
    -- ACP connects asynchronously and reads vim.fn.getcwd() when it spawns the
    -- agent and opens the session; that returns the window-local dir, so agents
    -- spawn in a buffer subdir and scatter empty metadata dirs. Force the git
    -- root of the global cwd instead
    local Connection = require('codecompanion.acp')
    for _, name in ipairs({ 'start_agent_process', '_establish_session' }) do
        local original = Connection[name]
        Connection[name] = function(self, ...)
            local getcwd = vim.fn.getcwd
            vim.fn.getcwd = function(...)
                return u.git_root(vim.uv.cwd()) or getcwd(...)
            end
            local ok, result = pcall(original, self, ...)
            vim.fn.getcwd = getcwd

            if not ok then
                error(result)
            end

            return result
        end
    end
end

function M.apply()
    if applied then
        return
    end

    patch_acp_model_choices()
    patch_tool_approval_notification()
    patch_acp_cwd()

    applied = true
end

return M
