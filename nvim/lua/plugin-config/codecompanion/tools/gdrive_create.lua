local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

local M = {}

-- API
local function create_drive_file(kind, title)
    local stdout, run_err = gws_helpers.run({
        'gws',
        'drive',
        'files',
        'create',
        '--params',
        vim.json.encode({
            fields = 'id,name,mimeType,webViewLink',
            supportsAllDrives = true,
        }),
        '--json',
        vim.json.encode({
            name = title,
            mimeType = gws_tool_helpers.MIME_TYPES[kind],
            parents = { 'root' },
        }),
    })
    if not stdout then
        return nil, run_err
    end

    local file, decode_err = gws_helpers.decode_json(stdout, 'the Google Drive file')
    if not file then
        return nil, decode_err
    end

    local id = gws_helpers.trim(file.id)
    if id == '' then
        return nil, 'Created file response did not include an id'
    end

    local name = gws_helpers.fallback_text(file.name, title)
    local url = gws_helpers.trim(file.webViewLink)
    if url == '' then
        local edit_url = gws_tool_helpers.EDIT_URLS[file.mimeType]
        url = edit_url and edit_url:format(id) or ''
    end

    local lines = {
        ('Created %s "%s" (ID: %s)'):format(gws_tool_helpers.KIND_LABELS[kind], name, id),
    }
    if url ~= '' then
        lines[#lines + 1] = ('URL: %s'):format(url)
    end

    return table.concat(lines, '\n')
end

-- Ops
local function create_operation(kind, args)
    local title, title_err =
        gws_tool_helpers.normalize_required_string_arg(args.title, 'title')
    if not title then
        return gws_tool_helpers.tool_error(title_err)
    end

    local data, err = create_drive_file(kind, title)
    if not data then
        return gws_tool_helpers.tool_error(err)
    end

    return gws_tool_helpers.tool_success(data)
end

-- Prompt builders
local function build_prompt(kind_label, args)
    return ('Create %s `%s`?'):format(kind_label, args.title)
end

local SCHEMA_PROPERTIES = {
    title = {
        type = 'string',
        description = 'Title of the new file.',
    },
}

-- Factory
function M.create_tool(kind)
    local kind_label = gws_tool_helpers.validate_kind(kind)
    local tool_name = 'g' .. kind .. '_create'

    return {
        name = tool_name,
        cmds = {
            function(_, args, _)
                return create_operation(kind, args)
            end,
        },
        schema = {
            type = 'function',
            ['function'] = {
                name = tool_name,
                description = ('Create a %s.'):format(kind_label),
                parameters = {
                    type = 'object',
                    properties = SCHEMA_PROPERTIES,
                    required = { 'title' },
                    additionalProperties = false,
                },
                strict = true,
            },
        },
        output = {
            prompt = function(self, _)
                return build_prompt(kind_label, self.args)
            end,
            success = function(self, stdout, meta)
                gws_tool_helpers.add_tool_success(
                    meta.tools.chat,
                    self,
                    stdout,
                    ('%s created'):format(kind_label)
                )
            end,
            error = function(self, stderr, meta)
                gws_tool_helpers.add_tool_error(
                    meta.tools.chat,
                    self,
                    stderr,
                    ('%s creation failed'):format(kind_label)
                )
            end,
        },
    }
end

return M
