local action_config = require('plugin-config.telescope.actions')
local config = require('plugin-config.telescope.config')
local customizations = require('plugin-config.telescope.customizations')
local extensions = require('plugin-config.telescope.extensions')
local mappings = require('plugin-config.telescope.mappings')
local pickers = require('plugin-config.telescope.pickers')
local previewers = require('plugin-config.telescope.previewers')

local M = {}

function M.setup()
    customizations.setup()
    previewers.setup()
    config.setup()
    extensions.setup()
    mappings.setup()

    -- Public API used by NvimTree, Aerial, and other plugin configurations
    _G.TelescopeConfig = {
        custom_actions = action_config.custom,
        find_dirs = pickers.find_dirs,
        parent_dirs = pickers.parent_dirs,
        bookmark_dirs = pickers.bookmark_dirs,
        find_files_cwd = pickers.find_files_cwd,
        z_with_tree_preview = pickers.z_with_tree_preview,
    }
end

return M
