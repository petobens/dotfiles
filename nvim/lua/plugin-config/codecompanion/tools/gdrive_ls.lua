local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Constants
local FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'
local MIME_URLS = {
    ['application/vnd.google-apps.document'] = 'https://docs.google.com/document/d/%s/edit',
    ['application/vnd.google-apps.folder'] = 'https://drive.google.com/drive/folders/%s',
    ['application/vnd.google-apps.presentation'] = 'https://docs.google.com/presentation/d/%s/edit',
    ['application/vnd.google-apps.spreadsheet'] = 'https://docs.google.com/spreadsheets/d/%s/edit',
}

-- Input parsing
local function parse_folder_id(input)
    input = gws_helpers.trim(input)

    local id = input:match('/drive/folders/([%w%-_]+)')
    if id then
        return id
    end

    if input:match('^[%w%-_]+$') then
        return input
    end

    return nil, 'Could not extract a Google Drive folder ID from the provided value'
end

-- Drive API
local function fetch_file_name(file_id)
    local stdout, run_err = gws_helpers.run({
        'gws',
        'drive',
        'files',
        'get',
        '--params',
        vim.json.encode({
            fileId = file_id,
            fields = 'id,name',
            supportsAllDrives = true,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    local file, decode_err =
        gws_helpers.decode_json(stdout, 'the Google Drive file metadata')
    if not file then
        return nil, decode_err
    end

    return gws_helpers.fallback_text(file.name, 'Untitled')
end

local function fetch_children(folder_id)
    local files = {}
    local page_token

    repeat
        local params = {
            q = ("'%s' in parents and trashed = false"):format(folder_id),
            pageSize = 1000,
            fields = 'nextPageToken,files(id,name,mimeType,webViewLink,modifiedTime)',
            orderBy = 'folder,name',
            includeItemsFromAllDrives = true,
            supportsAllDrives = true,
        }
        if page_token then
            params.pageToken = page_token
        end

        local stdout, run_err = gws_helpers.run({
            'gws',
            'drive',
            'files',
            'list',
            '--params',
            vim.json.encode(params),
        })
        if not stdout then
            return nil, run_err
        end

        local response, decode_err =
            gws_helpers.decode_json(stdout, 'the Google Drive folder listing')
        if not response then
            return nil, decode_err
        end

        vim.list_extend(files, response.files or {})
        page_token = gws_helpers.fallback_text(response.nextPageToken, nil)
    until not page_token

    return files
end

-- Output formatting
local function build_url(file)
    local web_view_link = gws_helpers.trim(file.webViewLink)
    if web_view_link ~= '' then
        return web_view_link
    end

    local template = MIME_URLS[file.mimeType]
    return template and template:format(file.id)
        or ('https://drive.google.com/file/d/%s/view'):format(file.id)
end

local function format_entry(file, depth)
    return ('%s%s %s\n%s  %s'):format(
        ('  '):rep(depth),
        file.mimeType == FOLDER_MIME_TYPE and '+' or '-',
        gws_helpers.fallback_text(file.name, 'Untitled'),
        ('  '):rep(depth),
        build_url(file)
    )
end

-- Folder traversal
local function append_entries(folder_id, depth, seen, entries)
    if seen[folder_id] then
        return true
    end
    seen[folder_id] = true

    local files, err = fetch_children(folder_id)
    if not files then
        return nil, err
    end

    for _, file in ipairs(files) do
        entries[#entries + 1] = format_entry(file, depth)
        if file.mimeType == FOLDER_MIME_TYPE then
            local ok, child_err = append_entries(file.id, depth + 1, seen, entries)
            if not ok then
                return nil, child_err
            end
        end
    end

    return true
end

local function list_folder(folder)
    local folder_id, folder_id_err = parse_folder_id(folder)
    if not folder_id then
        return nil, folder_id_err
    end

    local folder_name, folder_name_err = fetch_file_name(folder_id)
    if not folder_name then
        return nil, folder_name_err
    end

    local entries = {}
    local ok, list_err = append_entries(folder_id, 0, {}, entries)
    if not ok then
        return nil, list_err
    end

    return gws_helpers.normalize_text(table.concat(
        vim.list_extend({
            ('Folder: %s'):format(folder_name),
            ('ID: %s'):format(folder_id),
            ('Results: %d'):format(#entries),
            '',
        }, entries),
        '\n'
    ))
end

-- Tool execution
local function list_drive_folder(args)
    local folder, folder_err =
        gws_tool_helpers.normalize_required_string_arg(args.folder, 'folder')
    if not folder then
        return gws_tool_helpers.tool_error(folder_err)
    end

    local result, err = list_folder(folder)
    if not result then
        return gws_tool_helpers.tool_error(err)
    end

    return gws_tool_helpers.tool_success(
        ('Here is the recursive Google Drive folder listing for `%s`:\n\n%s'):format(
            gws_helpers.trim(folder),
            result
        )
    )
end

-- Tool definition
local M = {
    name = 'gdrive_ls',
    cmds = {
        function(_, args, _)
            return list_drive_folder(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gdrive_ls',
            description = 'List Google Drive folder files recursively.',
            parameters = {
                type = 'object',
                properties = {
                    folder = {
                        type = 'string',
                        description = 'Google Drive folder URL or ID.',
                    },
                },
                required = { 'folder' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            return ('List Google Drive folder `%s` recursively?'):format(self.args.folder)
        end,
        success = function(self, stdout, meta)
            gws_tool_helpers.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Drive folder listing succeeded'
            )
        end,
        error = function(self, stderr, meta)
            gws_tool_helpers.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Drive folder listing failed'
            )
        end,
    },
}

return M
