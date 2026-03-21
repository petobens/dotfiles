local M = {}

function M.build()
    return {
        read_file = {
            opts = {
                require_approval_before = false,
            },
        },
        groups = {
            ws_agent = {
                description = 'Agent with workspace file editing and command execution',
                tools = {
                    'create_file',
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
        },
    }
end

return M
