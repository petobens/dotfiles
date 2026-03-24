local M = {}

local tools = {
    -- Builtin tools
    grep_search = {
        opts = {
            require_approval_before = false,
        },
    },
    read_file = {
        opts = {
            require_approval_before = false,
        },
    },
    -- Custom tools
    ---- Gsheets
    gsheet_inspect = {
        description = 'Inspect a Google Sheet structure via gws',
        callback = function()
            return require('plugin-config.codecompanion.tools.gsheet_inspect')
        end,
        opts = {
            require_approval_before = false,
        },
    },
    gsheet_read = {
        description = 'Read a Google Sheet via gws',
        callback = function()
            return require('plugin-config.codecompanion.tools.gsheet_read')
        end,
        opts = {
            require_approval_before = false,
        },
    },
    gsheet_write = {
        description = 'Write to a Google Sheet via gws',
        callback = function()
            return require('plugin-config.codecompanion.tools.gsheet_write')
        end,
        opts = {
            require_approval_before = true,
            allowed_in_yolo_mode = false,
        },
    },
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
            opts = {
                collapse_tools = true,
                ignore_system_prompt = false,
                ignore_tool_system_prompt = false,
            },
        },
        gsheet_tools = {
            description = 'Tool group with Google Sheets read and write capabilities',
            tools = {
                'gsheet_inspect',
                'gsheet_read',
                'gsheet_write',
            },
            opts = {
                collapse_tools = true,
                ignore_system_prompt = false,
                ignore_tool_system_prompt = false,
            },
        },
    },
}

function M.build()
    return tools
end

return M
