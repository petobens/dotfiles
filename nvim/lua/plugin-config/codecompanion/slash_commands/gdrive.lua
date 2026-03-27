-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')

local M = {}

-- Constants
local DEFAULT_PAGE_SIZE = 10
local ALL_FILE_TYPES_QUERY = table.concat({
    "mimeType = 'application/vnd.google-apps.document'",
    "mimeType = 'application/vnd.google-apps.spreadsheet'",
    "mimeType = 'application/vnd.google-apps.presentation'",
}, ' or ')
local FILE_TYPES = {
    all = {
        label = 'docs, sheets, slides',
        query_suffix = ALL_FILE_TYPES_QUERY,
    },
    docs = {
        label = 'docs',
        query_suffix = "mimeType = 'application/vnd.google-apps.document'",
    },
    sheets = {
        label = 'sheets',
        query_suffix = "mimeType = 'application/vnd.google-apps.spreadsheet'",
    },
    slides = {
        label = 'slides',
        query_suffix = "mimeType = 'application/vnd.google-apps.presentation'",
    },
}
local FILE_TYPE_ALIASES = {
    doc = FILE_TYPES.docs,
    docs = FILE_TYPES.docs,
    sheet = FILE_TYPES.sheets,
    sheets = FILE_TYPES.sheets,
    slide = FILE_TYPES.slides,
    slides = FILE_TYPES.slides,
    all = FILE_TYPES.all,
}
local MIME_URLS = {
    ['application/vnd.google-apps.document'] = 'https://docs.google.com/document/d/%s/edit',
    ['application/vnd.google-apps.presentation'] = 'https://docs.google.com/presentation/d/%s/edit',
    ['application/vnd.google-apps.spreadsheet'] = 'https://docs.google.com/spreadsheets/d/%s/edit',
}
local ROOT_LOCATION_NAMES = {
    ['root'] = 'My Drive',
}

-- Input parsing
local function parse_file_type(input)
    input = gws_helpers.trim(input):lower()

    if gws_helpers.is_blank(input) or input == 'all' then
        return FILE_TYPES.all
    end

    local file_type = FILE_TYPE_ALIASES[input]
    if file_type then
        return file_type
    end

    return nil,
        'Invalid file type. Use one of: docs, sheets, slides, doc, sheet, slide, all, or leave empty'
end

local function build_drive_query(query, file_type)
    local clauses = {
        ("(name contains '%s')"):format(
            gws_helpers.trim(query):gsub('\\', '\\\\'):gsub("'", "\\'")
        ),
    }

    if file_type and file_type.query_suffix then
        table.insert(clauses, ('(%s)'):format(file_type.query_suffix))
    end

    return table.concat(clauses, ' and ')
end

-- API fetch
local function fetch_drive_file_name(file_id)
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

    local name = gws_helpers.fallback_text(file.name, nil)
    if not name then
        return nil, 'Google Drive file metadata did not include a name'
    end

    return name
end

local function fetch_google_drive_files(query, file_type)
    local stdout, run_err = gws_helpers.run({
        'gws',
        'drive',
        'files',
        'list',
        '--params',
        vim.json.encode({
            q = build_drive_query(query, file_type),
            pageSize = DEFAULT_PAGE_SIZE,
            fields = 'files(id,name,mimeType,webViewLink,modifiedTime,owners(displayName),parents)',
            orderBy = 'modifiedTime desc',
            includeItemsFromAllDrives = true,
            supportsAllDrives = true,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return gws_helpers.decode_json(stdout, 'the Google Drive search results')
end

-- Formatting helpers
local function build_drive_url(file)
    local id = gws_helpers.trim(file.id)
    if id == '' then
        return nil
    end

    local web_view_link = gws_helpers.trim(file.webViewLink)
    if web_view_link ~= '' then
        return web_view_link
    end

    local template = MIME_URLS[file.mimeType]
    if template then
        return template:format(id)
    end

    return ('https://drive.google.com/file/d/%s/view'):format(id)
end

local function format_modified_time(value)
    value = gws_helpers.trim(value)
    if gws_helpers.is_blank(value) then
        return nil
    end

    local year, month, day, hour, minute, second =
        value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)')
    if not year then
        return value
    end

    return os.date(
        '%Y-%m-%d %H:%M',
        os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(minute),
            sec = tonumber(second),
        })
    )
end

local function get_file_location(file, location_cache)
    local parent_id = vim.tbl_get(file, 'parents', 1)
    parent_id = gws_helpers.trim(parent_id)

    if gws_helpers.is_blank(parent_id) then
        return nil
    end

    if ROOT_LOCATION_NAMES[parent_id] then
        return ROOT_LOCATION_NAMES[parent_id]
    end

    if location_cache[parent_id] ~= nil then
        return location_cache[parent_id]
    end

    local name = fetch_drive_file_name(parent_id)
    location_cache[parent_id] = name or false

    if name and not gws_helpers.is_blank(name) then
        return name
    end

    return nil
end

local function format_drive_entry(file, location_cache)
    local url = build_drive_url(file)
    if not url then
        return nil
    end

    local title = gws_helpers.fallback_text(file.name, 'Untitled')

    local lines = {
        ('- %s'):format(title),
        ('  %s'):format(url),
    }

    local modified_time = format_modified_time(file.modifiedTime)
    if modified_time then
        table.insert(lines, ('  modified: %s'):format(modified_time))
    end

    local owner =
        gws_helpers.fallback_text(vim.tbl_get(file, 'owners', 1, 'displayName'), nil)
    if owner then
        table.insert(lines, ('  owner: %s'):format(owner))
    end

    local location = get_file_location(file, location_cache)
    if location then
        table.insert(lines, ('  location: %s'):format(location))
    end

    return table.concat(lines, '\n')
end

-- Content extraction
local function google_drive_search_to_text(query, file_type, files)
    local entries = {}
    local location_cache = {}

    for _, file in ipairs(files or {}) do
        local entry = format_drive_entry(file, location_cache)
        if entry then
            table.insert(entries, entry)
        end
    end

    vim.list.unique(entries)

    if vim.tbl_isempty(entries) then
        return nil, ('No Google Drive files found for query: %s'):format(query)
    end

    local lines = {
        ('Query: %s'):format(query),
        ('Type: %s'):format(file_type.label),
        ('Results: %d'):format(#entries),
        '',
    }

    vim.list_extend(lines, entries)

    return gws_helpers.normalize_text(table.concat(lines, '\n'))
end

-- Read helpers
local function search_google_drive(query, file_type)
    query = gws_helpers.trim(query)
    if gws_helpers.is_blank(query) then
        return nil, 'Missing Google Drive search query'
    end

    file_type = file_type or FILE_TYPES.all

    local response, response_err = fetch_google_drive_files(query, file_type)
    if not response then
        return nil, response_err
    end

    local text, text_err = google_drive_search_to_text(query, file_type, response.files)
    if not text then
        return nil, text_err
    end

    return {
        text = text,
    }
end

-- Exports for reuse by tools
M.parse_file_type = parse_file_type
M.search_google_drive = search_google_drive

-- Slash command
function M.gdrive_search(chat)
    vim.ui.input({ prompt = 'Google Drive search query: ' }, function(input)
        if gws_helpers.is_blank(input) then
            return
        end

        input = gws_helpers.trim(input)

        vim.ui.input({
            prompt = 'Google Drive file type (doc(s)/sheet(s)/slide(s), all, empty = all): ',
        }, function(file_type_input)
            if file_type_input == nil then
                return
            end

            local file_type, file_type_err = parse_file_type(file_type_input)
            if not file_type then
                vim.notify(file_type_err, vim.log.levels.ERROR)
                return
            end

            local result, err = search_google_drive(input, file_type)
            if not result then
                vim.notify(err, vim.log.levels.ERROR)
                return
            end

            chat:add_buf_message({
                role = 'user',
                content = ('Searching for "%s"...'):format(input),
            })
            chat:add_buf_message({
                role = 'llm',
                content = ('Here are the Google Drive %s results for "%s":\n\n%s'):format(
                    file_type.label,
                    input,
                    result.text
                ),
            })
            chat:add_buf_message({
                role = 'user',
                content = '',
            })
        end)
    end)
end

return M
