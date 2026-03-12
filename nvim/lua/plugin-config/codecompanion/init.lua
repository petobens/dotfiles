local module_prefix = 'plugin-config.codecompanion.'
local chat_helpers = require(module_prefix .. 'helpers').chat

local M = {}

function M.setup()
    require(module_prefix .. 'config').setup()
    require(module_prefix .. 'ui').setup()
    require(module_prefix .. 'mappings').setup()

    -- Global variable to be used by other parts of the config (Telescope, NvimTree, etc)
    _G.CodeCompanionConfig = {
        add_context = chat_helpers.add_context,
        run_slash_command = chat_helpers.run_slash_command,
    }
end

return M
