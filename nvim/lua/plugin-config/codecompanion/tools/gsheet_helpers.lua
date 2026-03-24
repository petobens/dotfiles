local M = {}

-- Helpers
local function normalize_tool_output(output)
    if output == nil or output == vim.NIL then
        return ''
    end

    if type(output) == 'string' then
        return output
    end

    if type(output) == 'table' then
        return vim.iter(output)
            :flatten()
            :map(function(value)
                if value == nil or value == vim.NIL then
                    return nil
                end
                return tostring(value)
            end)
            :join('\n')
    end

    return tostring(output)
end

function M.add_tool_success(chat, tool, stdout, user_output)
    local llm_output = normalize_tool_output(stdout)
    chat:add_tool_output(tool, llm_output, user_output)
end

function M.add_tool_error(chat, tool, stderr, user_output)
    local llm_output = normalize_tool_output(stderr)
    local detailed_user_output = user_output

    if llm_output ~= '' then
        if detailed_user_output and detailed_user_output ~= '' then
            detailed_user_output = detailed_user_output .. '\n\n' .. llm_output
        else
            detailed_user_output = llm_output
        end
    end

    chat:add_tool_output(tool, llm_output, detailed_user_output)
end

return M
