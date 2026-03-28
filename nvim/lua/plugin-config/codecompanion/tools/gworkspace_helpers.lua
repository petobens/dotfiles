-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')

local M = {}

-- Constants
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

-- Validation helpers
function M.normalize_required_string_arg(value, name, opts)
    opts = opts or {}

    local normalized = gws_helpers.normalize_optional_string(value)
    if normalized == nil then
        return nil, ('%s must be a string'):format(name)
    end

    if not opts.allow_empty and normalized == '' then
        return nil, opts.empty_error or ('Missing %s'):format(name)
    end

    return normalized
end

function M.normalize_json_array_arg(value, opts)
    opts = opts or {}

    if value == vim.NIL then
        value = nil
    end

    if type(value) == 'string' then
        local ok, decoded = pcall(vim.json.decode, value)
        if not ok then
            return nil, opts.invalid_json_error or 'value must be valid JSON'
        end
        value = decoded
    end

    if type(value) ~= 'table' or vim.tbl_isempty(value) then
        return nil, opts.empty_error or 'value must be a non-empty JSON array'
    end

    return value
end

-- Google Drive file helpers
function M.validate_kind(kind)
    local kind_label = M.KIND_LABELS[kind]
    if not kind_label then
        error(('Unsupported Google Workspace kind: %s'):format(tostring(kind)))
    end

    return kind_label
end

function M.extract_google_id_arg(value, kind, label)
    local id, err = gws_helpers.extract_google_id(value, kind)
    if not id then
        return nil, err or ('Missing %s'):format(label or kind)
    end

    return id
end

function M.extract_file_id(target, kind)
    local url_kind = M.URL_KIND_MAP[kind]
    if url_kind then
        local id = gws_helpers.extract_google_id(target, url_kind)
        if id then
            return id
        end
    end

    if type(target) == 'string' then
        target = gws_helpers.trim(target)
        if target:match('^[%w%-_]+$') then
            return target
        end
    end

    return nil
end

function M.fetch_file_metadata(file_id)
    local stdout, run_err = gws_helpers.run({
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

    return gws_helpers.decode_json(stdout, 'the Google Workspace file metadata')
end

-- Tool result helpers
function M.tool_success(data)
    return {
        status = 'success',
        data = data,
    }
end

function M.tool_error(data)
    return {
        status = 'error',
        data = data,
    }
end

-- Factory helpers
function M.build_read_tool(spec)
    return {
        name = spec.name,
        cmds = {
            function(_, args, _)
                local item, err = spec.reader(args[spec.input_key])
                if not item then
                    return M.tool_error(err)
                end

                return M.tool_success(
                    string.format(
                        spec.template,
                        gws_helpers.fallback_text(item.title, 'Untitled'),
                        gws_helpers.fallback_text(item.id, 'unknown'),
                        gws_helpers.fallback_text(item.text, '')
                    )
                )
            end,
        },
        schema = {
            type = 'function',
            ['function'] = {
                name = spec.name,
                description = spec.description,
                parameters = {
                    type = 'object',
                    properties = {
                        [spec.input_key] = {
                            type = 'string',
                            description = spec.input_description,
                        },
                    },
                    required = { spec.input_key },
                    additionalProperties = false,
                },
                strict = true,
            },
        },
        output = {
            prompt = function(self, _)
                return spec.prompt_template:format(self.args[spec.input_key])
            end,
            success = function(self, stdout, meta)
                M.add_tool_success(
                    meta.tools.chat,
                    self,
                    stdout,
                    spec.success_user_output
                )
            end,
            error = function(self, stderr, meta)
                M.add_tool_error(meta.tools.chat, self, stderr, spec.error_user_output)
            end,
        },
    }
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
