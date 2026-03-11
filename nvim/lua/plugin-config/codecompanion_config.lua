local module_prefix = 'plugin-config.codecompanion.'
local helpers = require(module_prefix .. 'helpers')

-- Load CodeCompanion modules
require(module_prefix .. 'config').setup()
require(module_prefix .. 'ui').setup()
require(module_prefix .. 'mappings').setup()

-- Global variable to be used by other parts of the config (Telescope, NvimTree, etc)
_G.CodeCompanionConfig = {
    add_context = helpers.add_context,
    run_slash_command = helpers.run_slash_command,
}
