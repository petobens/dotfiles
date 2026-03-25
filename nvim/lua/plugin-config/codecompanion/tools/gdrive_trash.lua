local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

local M = {}

-- API helpers
local function trash_google_drive_file(kind, target)
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
        'update',
        '--params',
        vim.json.encode({
            fileId = file_id,
            supportsAllDrives = true,
        }),
        '--json',
        vim.json.encode({
            trashed = true,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return ('Moved %s "%s" to trash (ID: %s)'):format(
        gws_tool_helpers.KIND_LABELS[kind],
        gws_helpers.fallback_text(metadata.name, 'Untitled'),
        file_id
    )
end

-- Tool helpers
local function run_trash_gdrive_tool(kind, args)
    local target = gws_helpers.normalize_optional_string(args.target)
    if target == nil then
        return {
            status = 'error',
            data = 'target must be a string',
        }
    end
    if target == '' then
        return {
            status = 'error',
            data = 'Missing target',
        }
    end

    local data, err = trash_google_drive_file(kind, target)
    if not data then
        return {
            status = 'error',
            data = err,
        }
    end

    return {
        status = 'success',
        data = data,
    }
end

-- Tool factories
function M.trash_tool(kind)
    local kind_label = gws_tool_helpers.validate_kind(kind)

    local tool_name = 'g' .. kind .. '_trash'

    return {
        name = tool_name,
        cmds = {
            function(_, args, _)
                return run_trash_gdrive_tool(kind, args)
            end,
        },
        schema = {
            type = 'function',
            ['function'] = {
                name = tool_name,
                description = ('Move a %s to trash.'):format(kind_label),
                parameters = {
                    type = 'object',
                    properties = {
                        target = {
                            type = 'string',
                            description = 'File URL or file ID.',
                        },
                    },
                    required = { 'target' },
                    additionalProperties = false,
                },
                strict = true,
            },
        },
        output = {
            prompt = function(self, _)
                return ('Move %s `%s` to trash?'):format(kind_label, self.args.target)
            end,
            success = function(self, stdout, meta)
                gws_tool_helpers.add_tool_success(
                    meta.tools.chat,
                    self,
                    stdout,
                    ('%s moved to trash'):format(kind_label)
                )
            end,
            error = function(self, stderr, meta)
                gws_tool_helpers.add_tool_error(
                    meta.tools.chat,
                    self,
                    stderr,
                    ('Failed to move %s to trash'):format(kind_label)
                )
            end,
        },
    }
end

return M
