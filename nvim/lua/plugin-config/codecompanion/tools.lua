local M = {}

-- Constants
local GROUP_OPTS = {
    collapse_tools = true,
    ignore_system_prompt = false,
    ignore_tool_system_prompt = false,
}
local NO_APPROVAL_OPTS = {
    require_approval_before = false,
}
local WRITE_APPROVAL_OPTS = {
    require_approval_before = true,
    allowed_in_yolo_mode = false,
}

-- Helpers
local function module_tool(description, module_path, opts)
    return {
        description = description,
        callback = function()
            return require(module_path)
        end,
        opts = opts,
    }
end

local function gdrive_tool(description, module_path, method_name, kind)
    return {
        description = description,
        callback = function()
            return require(module_path)[method_name](kind)
        end,
        opts = WRITE_APPROVAL_OPTS,
    }
end

-- Tool definition
local tools = {
    -- Builtin tools
    grep_search = {
        opts = NO_APPROVAL_OPTS,
    },
    read_file = {
        opts = NO_APPROVAL_OPTS,
    },
    -- Custom tools
    ---- Gsheets
    gsheet_create = gdrive_tool(
        'Create a Google Sheet via gws',
        'plugin-config.codecompanion.tools.gdrive_create',
        'create_tool',
        'sheet'
    ),
    gsheet_delete = gdrive_tool(
        'Move a Google Sheet to trash via gws',
        'plugin-config.codecompanion.tools.gdrive_delete',
        'delete_tool',
        'sheet'
    ),
    gsheet_rename = gdrive_tool(
        'Rename a Google Sheet via gws',
        'plugin-config.codecompanion.tools.gdrive_rename',
        'rename_tool',
        'sheet'
    ),
    gsheet_inspect = module_tool(
        'Inspect a Google Sheet structure via gws',
        'plugin-config.codecompanion.tools.gsheet_inspect',
        NO_APPROVAL_OPTS
    ),
    gsheet_read = module_tool(
        'Read a Google Sheet via gws',
        'plugin-config.codecompanion.tools.gsheet_read',
        NO_APPROVAL_OPTS
    ),
    gsheet_write = module_tool(
        'Write to a Google Sheet via gws',
        'plugin-config.codecompanion.tools.gsheet_write',
        WRITE_APPROVAL_OPTS
    ),
    ---- Gdocs
    gdoc_create = gdrive_tool(
        'Create a Google Doc via gws',
        'plugin-config.codecompanion.tools.gdrive_create',
        'create_tool',
        'doc'
    ),
    gdoc_delete = gdrive_tool(
        'Move a Google Doc to trash via gws',
        'plugin-config.codecompanion.tools.gdrive_delete',
        'delete_tool',
        'doc'
    ),
    gdoc_rename = gdrive_tool(
        'Rename a Google Doc via gws',
        'plugin-config.codecompanion.tools.gdrive_rename',
        'rename_tool',
        'doc'
    ),
    ---- Gslides
    gslides_create = gdrive_tool(
        'Create a Google Slides presentation via gws',
        'plugin-config.codecompanion.tools.gdrive_create',
        'create_tool',
        'slides'
    ),
    gslides_delete = gdrive_tool(
        'Move a Google Slides presentation to trash via gws',
        'plugin-config.codecompanion.tools.gdrive_delete',
        'delete_tool',
        'slides'
    ),
    gslides_rename = gdrive_tool(
        'Rename a Google Slides presentation via gws',
        'plugin-config.codecompanion.tools.gdrive_rename',
        'rename_tool',
        'slides'
    ),
    -- Groups
    groups = {
        agent_tools = {
            description = 'Tool group with workspace file editing and command execution',
            tools = {
                'create_file',
                'delete_file',
                'file_search',
                'get_changed_files',
                'grep_search',
                'insert_edit_into_file',
                'read_file',
                'run_command',
            },
            opts = GROUP_OPTS,
        },
        gsheet_tools = {
            description = 'Google Sheets tools',
            tools = {
                'gsheet_create',
                'gsheet_delete',
                'gsheet_inspect',
                'gsheet_read',
                'gsheet_rename',
                'gsheet_write',
            },
            opts = GROUP_OPTS,
        },
    },
}

function M.build()
    return tools
end

return M
