local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

local M = {}

-- API helpers
local function rename_google_drive_file(kind, target, new_title)
    local file_id = helper.extract_file_id(target, kind)
    if not file_id then
        return nil, 'Could not extract a valid Google file id from target'
    end

    local metadata, metadata_err = helper.fetch_file_metadata(file_id)
    if not metadata then
        return nil, metadata_err
    end

    if gw.trim(metadata.mimeType) ~= helper.MIME_TYPES[kind] then
        return nil, ('Target is not a %s'):format(helper.KIND_LABELS[kind])
    end

    local stdout, run_err = gw.run({
        'gws',
        'drive',
        'files',
        'update',
        '--params',
        vim.json.encode({
            fileId = file_id,
            supportsAllDrives = true,
            fields = 'id,name,mimeType,webViewLink',
        }),
        '--json',
        vim.json.encode({
            name = new_title,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    local file, decode_err = gw.decode_json(stdout, 'the Google Drive file')
    if not file then
        return nil, decode_err
    end

    local updated_name = gw.fallback_text(file.name, new_title)

    return ('Renamed %s "%s" to "%s" (ID: %s)'):format(
        helper.KIND_LABELS[kind],
        gw.fallback_text(metadata.name, 'Untitled'),
        updated_name,
        file_id
    )
end

-- Tool helpers
local function run_rename_gdrive_tool(kind, args)
    local target = gw.normalize_optional_string(args.target)
    local new_title = gw.normalize_optional_string(args.new_title)

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

    if new_title == nil then
        return {
            status = 'error',
            data = 'new_title must be a string',
        }
    end
    if new_title == '' then
        return {
            status = 'error',
            data = 'Missing new_title',
        }
    end

    local data, err = rename_google_drive_file(kind, target, new_title)
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
function M.rename_tool(kind)
    local kind_label = helper.validate_kind(kind)

    local tool_name = 'g' .. kind .. '_rename'

    return {
        name = tool_name,
        cmds = {
            function(_, args, _)
                return run_rename_gdrive_tool(kind, args)
            end,
        },
        schema = {
            type = 'function',
            ['function'] = {
                name = tool_name,
                description = ('Rename a %s.'):format(kind_label),
                parameters = {
                    type = 'object',
                    properties = {
                        target = {
                            type = 'string',
                            description = 'File URL or file ID.',
                        },
                        new_title = {
                            type = 'string',
                            description = 'New title for the file.',
                        },
                    },
                    required = { 'target', 'new_title' },
                    additionalProperties = false,
                },
                strict = true,
            },
        },
        output = {
            prompt = function(self, _)
                return ('Rename %s `%s` to `%s`?'):format(
                    kind_label,
                    self.args.target,
                    self.args.new_title
                )
            end,
            success = function(self, stdout, meta)
                helper.add_tool_success(
                    meta.tools.chat,
                    self,
                    stdout,
                    ('%s renamed'):format(kind_label)
                )
            end,
            error = function(self, stderr, meta)
                helper.add_tool_error(
                    meta.tools.chat,
                    self,
                    stderr,
                    ('%s rename failed'):format(kind_label)
                )
            end,
        },
    }
end

return M
