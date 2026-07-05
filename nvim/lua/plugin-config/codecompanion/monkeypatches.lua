-- luacheck:ignore 631
local state_helpers = require('plugin-config.codecompanion.helpers').state
local utils = require('codecompanion.utils')

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

function M.apply()
    if applied then
        return
    end

    patch_acp_model_choices()
    patch_tool_approval_notification()

    applied = true
end

return M
