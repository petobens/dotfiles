local M = {}

local prompt_library = require('plugin-config.codecompanion.prompt_library')

-- Constants
local TOOL_MODULE_PREFIX = 'plugin-config.codecompanion.tools.'
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
local function module_tool(description, module_name, opts)
    return {
        description = description,
        callback = function()
            return require(TOOL_MODULE_PREFIX .. module_name)
        end,
        opts = opts,
    }
end

local function gdrive_tool(description, module_name, method_name, kind)
    return {
        description = description,
        callback = function()
            return require(TOOL_MODULE_PREFIX .. module_name)[method_name](kind)
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
    ---- Terminal
    safe_run_command = module_tool(
        'Run approved safe shell commands, require approval otherwise',
        'safe_run_command',
        nil
    ),
    ---- Gdrive
    gdrive_search = module_tool(
        'Search Google Drive files via gws',
        'gdrive_search',
        NO_APPROVAL_OPTS
    ),
    ---- Gsheets
    gsheet_copy = gdrive_tool(
        'Copy a Google Sheet via gws',
        'gdrive_copy',
        'copy_tool',
        'sheet'
    ),
    gsheet_create = gdrive_tool(
        'Create a Google Sheet via gws',
        'gdrive_create',
        'create_tool',
        'sheet'
    ),
    gsheet_trash = gdrive_tool(
        'Move a Google Sheet to trash via gws',
        'gdrive_trash',
        'trash_tool',
        'sheet'
    ),
    gsheet_rename = gdrive_tool(
        'Rename a Google Sheet via gws',
        'gdrive_rename',
        'rename_tool',
        'sheet'
    ),
    gsheet_inspect = module_tool(
        'Inspect a Google Sheet structure via gws',
        'gsheet_inspect',
        NO_APPROVAL_OPTS
    ),
    gsheet_read = module_tool(
        'Read a Google Sheet via gws',
        'gsheet_read',
        NO_APPROVAL_OPTS
    ),
    gsheet_write = module_tool(
        'Write to a Google Sheet via gws',
        'gsheet_write',
        WRITE_APPROVAL_OPTS
    ),
    ---- Gdocs
    gdoc_copy = gdrive_tool(
        'Copy a Google Doc via gws',
        'gdrive_copy',
        'copy_tool',
        'doc'
    ),
    gdoc_create = gdrive_tool(
        'Create a Google Doc via gws',
        'gdrive_create',
        'create_tool',
        'doc'
    ),
    gdoc_trash = gdrive_tool(
        'Move a Google Doc to trash via gws',
        'gdrive_trash',
        'trash_tool',
        'doc'
    ),
    gdoc_rename = gdrive_tool(
        'Rename a Google Doc via gws',
        'gdrive_rename',
        'rename_tool',
        'doc'
    ),
    gdoc_inspect = module_tool(
        'Inspect a Google Doc structure via gws',
        'gdoc_inspect',
        NO_APPROVAL_OPTS
    ),
    gdoc_read = module_tool('Read a Google Doc via gws', 'gdoc_read', NO_APPROVAL_OPTS),
    gdoc_write = module_tool(
        'Write to a Google Doc via gws',
        'gdoc_write',
        WRITE_APPROVAL_OPTS
    ),
    ---- Gslides
    gslides_copy = gdrive_tool(
        'Copy a Google Slides presentation via gws',
        'gdrive_copy',
        'copy_tool',
        'slides'
    ),
    gslides_create = gdrive_tool(
        'Create a Google Slides presentation via gws',
        'gdrive_create',
        'create_tool',
        'slides'
    ),
    gslides_trash = gdrive_tool(
        'Move a Google Slides presentation to trash via gws',
        'gdrive_trash',
        'trash_tool',
        'slides'
    ),
    gslides_rename = gdrive_tool(
        'Rename a Google Slides presentation via gws',
        'gdrive_rename',
        'rename_tool',
        'slides'
    ),
    gslides_inspect = module_tool(
        'Inspect a Google Slides presentation structure via gws',
        'gslides_inspect',
        NO_APPROVAL_OPTS
    ),
    gslides_read = module_tool(
        'Read a Google Slides presentation via gws',
        'gslides_read',
        NO_APPROVAL_OPTS
    ),
    gslides_write = module_tool(
        'Write to a Google Slides presentation via gws',
        'gslides_write',
        WRITE_APPROVAL_OPTS
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
                'safe_run_command',
            },
            opts = GROUP_OPTS,
        },
        gsheet_tools = {
            description = 'Google Sheets tools',
            tools = {
                'gdrive_search',
                'gsheet_copy',
                'gsheet_create',
                'gsheet_inspect',
                'gsheet_read',
                'gsheet_rename',
                'gsheet_trash',
                'gsheet_write',
            },
            opts = GROUP_OPTS,
        },
        gdoc_tools = {
            description = 'Google Docs tools',
            tools = {
                'gdrive_search',
                'gdoc_copy',
                'gdoc_create',
                'gdoc_inspect',
                'gdoc_read',
                'gdoc_rename',
                'gdoc_trash',
                'gdoc_write',
            },
            opts = GROUP_OPTS,
        },
        gslides_tools = {
            description = 'Google Slides tools',
            tools = {
                'gdrive_search',
                'gslides_copy',
                'gslides_create',
                'gslides_inspect',
                'gslides_read',
                'gslides_rename',
                'gslides_trash',
                'gslides_write',
            },
            opts = GROUP_OPTS,
        },

        -- Agents
        mutt_slides_agent = {
            description = 'Create muttdata slides',
            system_prompt = prompt_library.prompt_file('mutt_slides'),
            tools = {
                'gdrive_search',
                'gslides_copy',
                'gslides_create',
                'gslides_inspect',
                'gslides_read',
                'gslides_rename',
                'gslides_trash',
                'gslides_write',
            },
            opts = GROUP_OPTS,
        },
    },
}

function M.build()
    return tools
end

return M
