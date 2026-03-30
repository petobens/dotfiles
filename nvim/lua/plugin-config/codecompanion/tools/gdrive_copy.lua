local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

local M = {}

-- API
local function copy_drive_file(kind, target, new_title)
    local file_id = gws_tool_helpers.extract_file_id(target, kind)
    if not file_id then
        return nil, 'Could not extract a valid Google file id from target'
    end

    local metadata, metadata_err = gws_tool_helpers.fetch_file_metadata(file_id)
    if not metadata then
        return nil, metadata_err
    end
    if gws_helpers.trim(metadata.mimeType) ~= gws_tool_helpers.MIME_TYPES[kind] then
        return nil, ('Target is not a %s'):format(gws_tool_helpers.KIND_LABELS[kind])
    end

    local stdout, run_err = gws_helpers.run({
        'gws',
        'drive',
        'files',
        'copy',
        '--params',
        vim.json.encode({
            fileId = file_id,
            supportsAllDrives = true,
            fields = 'id,name,mimeType,webViewLink',
        }),
        '--json',
        vim.json.encode({ name = new_title }),
    })
    if not stdout then
        return nil, run_err
    end

    local file, decode_err =
        gws_helpers.decode_json(stdout, 'the copied Google Drive file')
    if not file then
        return nil, decode_err
    end

    local copied_file_id = gws_helpers.trim(file.id)
    if copied_file_id == '' then
        return nil, 'Copied file response did not include an id'
    end

    local name = gws_helpers.fallback_text(file.name, new_title)
    local url = gws_helpers.trim(file.webViewLink)
    if url == '' then
        local edit_url = gws_tool_helpers.EDIT_URLS[file.mimeType]
        url = edit_url and edit_url:format(copied_file_id) or ''
    end

    local lines = {
        ('Copied %s "%s" to "%s" (ID: %s)'):format(
            gws_tool_helpers.KIND_LABELS[kind],
            gws_helpers.fallback_text(metadata.name, 'Untitled'),
            name,
            copied_file_id
        ),
    }
    if url ~= '' then
        lines[#lines + 1] = ('URL: %s'):format(url)
    end

    return table.concat(lines, '\n')
end

-- Ops
local function copy_operation(kind, args)
    local target, target_err =
        gws_tool_helpers.normalize_required_string_arg(args.target, 'target')
    if not target then
        return gws_tool_helpers.tool_error(target_err)
    end

    local new_title, new_title_err =
        gws_tool_helpers.normalize_required_string_arg(args.new_title, 'new_title')
    if not new_title then
        return gws_tool_helpers.tool_error(new_title_err)
    end

    local data, err = copy_drive_file(kind, target, new_title)
    if not data then
        return gws_tool_helpers.tool_error(err)
    end

    return gws_tool_helpers.tool_success(data)
end

-- Prompt builders
local function build_prompt(kind_label, args)
    return ('Copy %s `%s` to new file `%s`?'):format(
        kind_label,
        args.target,
        args.new_title
    )
end

local SCHEMA_PROPERTIES = {
    target = {
        type = 'string',
        description = 'File URL or file ID.',
    },
    new_title = {
        type = 'string',
        description = 'Title for the copied file.',
    },
}

-- Factory
function M.copy_tool(kind)
    local kind_label = gws_tool_helpers.validate_kind(kind)
    local tool_name = 'g' .. kind .. '_copy'

    return {
        name = tool_name,
        cmds = {
            function(_, args, _)
                return copy_operation(kind, args)
            end,
        },
        schema = {
            type = 'function',
            ['function'] = {
                name = tool_name,
                description = ('Copy a %s.'):format(kind_label),
                parameters = {
                    type = 'object',
                    properties = SCHEMA_PROPERTIES,
                    required = { 'target', 'new_title' },
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
                    ('%s copied'):format(kind_label)
                )
            end,
            error = function(self, stderr, meta)
                gws_tool_helpers.add_tool_error(
                    meta.tools.chat,
                    self,
                    stderr,
                    ('%s copy failed'):format(kind_label)
                )
            end,
        },
    }
end

return M
