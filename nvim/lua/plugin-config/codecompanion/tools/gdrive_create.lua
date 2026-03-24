local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

local M = {}

-- API helpers
local function create_google_drive_file(kind, title)
    local stdout, run_err = gw.run({
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
            mimeType = helper.MIME_TYPES[kind],
            parents = { 'root' }, -- Force creation in My Drive
        }),
    })
    if not stdout then
        return nil, run_err
    end

    local file, decode_err = gw.decode_json(stdout, 'the Google Drive file')
    if not file then
        return nil, decode_err
    end

    local id = gw.trim(file.id)
    if id == '' then
        return nil, 'Created file response did not include an id'
    end

    local name = gw.fallback_text(file.name, title)
    local url = gw.trim(file.webViewLink)
    if url == '' then
        url = helper.EDIT_URLS[file.mimeType]
                and helper.EDIT_URLS[file.mimeType]:format(id)
            or ''
    end

    local lines = {
        ('Created %s "%s" (ID: %s)'):format(helper.KIND_LABELS[kind], name, id),
    }

    if url ~= '' then
        table.insert(lines, ('URL: %s'):format(url))
    end

    return table.concat(lines, '\n')
end

-- Tool helpers
local function run_create_gdrive_tool(kind, args)
    local title = gw.normalize_optional_string(args.title)
    if title == nil then
        return {
            status = 'error',
            data = 'title must be a string',
        }
    end
    if title == '' then
        return {
            status = 'error',
            data = 'Missing title',
        }
    end

    local data, err = create_google_drive_file(kind, title)
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
function M.create_tool(kind)
    local kind_label = helper.validate_kind(kind)

    local tool_name = 'g' .. kind .. '_create'

    return {
        name = tool_name,
        cmds = {
            function(_, args, _)
                return run_create_gdrive_tool(kind, args)
            end,
        },
        schema = {
            type = 'function',
            ['function'] = {
                name = tool_name,
                description = ('Create a %s.'):format(kind_label),
                parameters = {
                    type = 'object',
                    properties = {
                        title = {
                            type = 'string',
                            description = 'Title of the new file.',
                        },
                    },
                    required = { 'title' },
                    additionalProperties = false,
                },
                strict = true,
            },
        },
        output = {
            prompt = function(self, _)
                return ('Create %s `%s`?'):format(kind_label, self.args.title)
            end,
            success = function(self, stdout, meta)
                helper.add_tool_success(
                    meta.tools.chat,
                    self,
                    stdout,
                    ('%s created'):format(kind_label)
                )
            end,
            error = function(self, stderr, meta)
                helper.add_tool_error(
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
