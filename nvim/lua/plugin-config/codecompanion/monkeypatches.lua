-- luacheck:ignore 631
local M = {}

local applied = false

local function patch_acp_model_choices()
    -- Upstream PR: https://github.com/olimorris/codecompanion.nvim/pull/3020
    require('codecompanion.interactions.chat.keymaps.change_adapter').list_acp_models = function()
        return nil
    end
end

function M.apply()
    if applied then
        return
    end

    patch_acp_model_choices()
    applied = true
end

return M
