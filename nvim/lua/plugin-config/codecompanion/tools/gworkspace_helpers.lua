-- luacheck:ignore 631
local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')

local M = {}

-- Google Workspace constants
M.MIME_TYPES = {
    doc = 'application/vnd.google-apps.document',
    sheet = 'application/vnd.google-apps.spreadsheet',
    slides = 'application/vnd.google-apps.presentation',
}

M.KIND_LABELS = {
    doc = 'Google Doc',
    sheet = 'Google Sheet',
    slides = 'Google Slides presentation',
}

M.EDIT_URLS = {
    ['application/vnd.google-apps.document'] = 'https://docs.google.com/document/d/%s/edit',
    ['application/vnd.google-apps.spreadsheet'] = 'https://docs.google.com/spreadsheets/d/%s/edit',
    ['application/vnd.google-apps.presentation'] = 'https://docs.google.com/presentation/d/%s/edit',
}

M.URL_KIND_MAP = {
    doc = 'docs',
    sheet = 'sheets',
    slides = 'slides',
}

-- Google Workspace file helpers
function M.validate_kind(kind)
    local kind_label = M.KIND_LABELS[kind]
    if not kind_label then
        error(('Unsupported Google Workspace kind: %s'):format(tostring(kind)))
    end

    return kind_label
end

function M.extract_file_id(target, kind)
    local url_kind = M.URL_KIND_MAP[kind]
    if url_kind then
        local id = gw.extract_google_id(target, url_kind)
        if id then
            return id
        end
    end

    if type(target) == 'string' then
        target = gw.trim(target)
        if target:match('^[%w%-_]+$') then
            return target
        end
    end

    return nil
end

function M.fetch_file_metadata(file_id)
    local stdout, run_err = gw.run({
        'gws',
        'drive',
        'files',
        'get',
        '--params',
        vim.json.encode({
            fileId = file_id,
            fields = 'id,name,mimeType',
            supportsAllDrives = true,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return gw.decode_json(stdout, 'the Google Workspace file metadata')
end

-- Tool output helpers
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
