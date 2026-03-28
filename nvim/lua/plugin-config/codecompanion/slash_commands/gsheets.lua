local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')

local M = {}

-- Const
local DEFAULT_RANGE = 'A1:AZ2000'

-- API
local function fetch_google_sheet_metadata(sheet_id)
    local stdout, run_err = gws_helpers.run({
        'gws',
        'sheets',
        'spreadsheets',
        'get',
        '--params',
        vim.json.encode({ spreadsheetId = sheet_id }),
    })
    if not stdout then
        return nil, run_err
    end

    return gws_helpers.decode_json(stdout, 'the Google Sheet metadata')
end

local function fetch_google_sheet_values(sheet_id, ranges, value_render_option)
    local stdout, run_err = gws_helpers.run({
        'gws',
        'sheets',
        'spreadsheets',
        'values',
        'batchGet',
        '--params',
        vim.json.encode({
            spreadsheetId = sheet_id,
            ranges = ranges,
            valueRenderOption = value_render_option,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return gws_helpers.decode_json(stdout, 'the Google Sheet values')
end

-- Format
local function get_spreadsheet_title(metadata)
    return gws_helpers.fallback_text(
        vim.tbl_get(metadata, 'properties', 'title'),
        'Untitled spreadsheet'
    )
end

local function sheet_range_to_title(range)
    range = gws_helpers.trim(range)

    local title = gws_helpers.trim(range:match("^'(.+)'!"))
    if title ~= '' then
        return title:gsub("''", "'")
    end

    title = gws_helpers.trim(range:match('^([^!]+)!'))
    return title ~= '' and title or 'Unknown worksheet'
end

local function worksheet_lines(metadata)
    return vim.iter(metadata.sheets or {})
        :map(function(sheet)
            local properties = sheet.properties or {}
            if
                type(properties.title) ~= 'string'
                or gws_helpers.is_blank(properties.title)
            then
                return nil
            end

            local suffix = {}
            local grid = properties.gridProperties or {}
            if type(grid.rowCount) == 'number' then
                suffix[#suffix + 1] = ('rows: %d'):format(grid.rowCount)
            end
            if type(grid.columnCount) == 'number' then
                suffix[#suffix + 1] = ('cols: %d'):format(grid.columnCount)
            end

            return ('- %s (sheetId: %d%s)'):format(
                properties.title,
                properties.sheetId or -1,
                #suffix > 0 and (', ' .. table.concat(suffix, ', ')) or ''
            )
        end)
        :filter(function(line)
            return line ~= nil
        end)
        :totable()
end

local function render_value_ranges(label, value_ranges)
    if vim.tbl_isempty(value_ranges or {}) then
        return nil
    end

    local sections = { ('Mode: %s'):format(label), '' }
    local nonempty_tabs = 0

    for _, value_range in ipairs(value_ranges) do
        local values = value_range.values or {}
        if not vim.tbl_isempty(values) then
            nonempty_tabs = nonempty_tabs + 1
            sections[#sections + 1] = ('Worksheet: %s'):format(
                sheet_range_to_title(value_range.range)
            )
            vim.list_extend(
                sections,
                vim.iter(values)
                    :map(function(row)
                        return vim.iter(row):map(tostring):join(' | ')
                    end)
                    :totable()
            )
            sections[#sections + 1] = ''
        end
    end

    return nonempty_tabs > 0 and gws_helpers.normalize_text(table.concat(sections, '\n'))
        or nil
end

local function summarize_google_sheet_metadata(metadata)
    return {
        id = metadata.spreadsheetId,
        title = get_spreadsheet_title(metadata),
        text = gws_helpers.normalize_text(
            table.concat(
                vim.list_extend({ 'Worksheets:' }, worksheet_lines(metadata)),
                '\n'
            )
        ),
    }
end

-- Read
local function read_google_sheet(input)
    local sheet_id, id_err = gws_helpers.extract_google_id(input, 'sheets')
    if not sheet_id then
        return nil, id_err
    end

    local metadata, metadata_err = fetch_google_sheet_metadata(sheet_id)
    if not metadata then
        return nil, metadata_err
    end
    if vim.tbl_isempty(metadata.sheets or {}) then
        return nil, 'No worksheets found in the Google Sheet'
    end

    local titles = vim.iter(metadata.sheets or {})
        :map(function(sheet)
            return vim.tbl_get(sheet, 'properties', 'title')
        end)
        :filter(function(title)
            return type(title) == 'string' and not gws_helpers.is_blank(title)
        end)
        :totable()
    if vim.tbl_isempty(titles) then
        return nil, 'No readable worksheets found in the Google Sheet'
    end

    local ranges = vim.iter(titles)
        :map(function(title)
            return ("'%s'!%s"):format(title:gsub("'", "''"), DEFAULT_RANGE)
        end)
        :totable()

    local values_data, values_err =
        fetch_google_sheet_values(sheet_id, ranges, 'FORMATTED_VALUE')
    if not values_data then
        return nil, values_err
    end

    local formulas_data, formulas_err =
        fetch_google_sheet_values(sheet_id, ranges, 'FORMULA')
    if not formulas_data then
        return nil, formulas_err
    end

    local values_text = render_value_ranges('values', values_data.valueRanges)
    local formulas_text = render_value_ranges('formulas', formulas_data.valueRanges)
    if not values_text and not formulas_text then
        return nil, 'The Google Sheet appears to be empty'
    end

    local parts = {
        ('Range: %s'):format(DEFAULT_RANGE),
        'Tabs: all',
        '',
        'Worksheets:',
    }
    vim.list_extend(parts, worksheet_lines(metadata))
    parts[#parts + 1] = ''
    if values_text then
        parts[#parts + 1] = values_text
        parts[#parts + 1] = ''
    end
    if formulas_text then
        parts[#parts + 1] = formulas_text
    end

    return {
        id = sheet_id,
        title = get_spreadsheet_title(metadata),
        text = gws_helpers.normalize_text(table.concat(parts, '\n')),
    }
end

local function read_google_sheet_metadata(input)
    local sheet_id, id_err = gws_helpers.extract_google_id(input, 'sheets')
    if not sheet_id then
        return nil, id_err
    end

    local metadata, metadata_err = fetch_google_sheet_metadata(sheet_id)
    if not metadata then
        return nil, metadata_err
    end

    return summarize_google_sheet_metadata(metadata)
end

-- Exports
M.read_google_sheet = read_google_sheet
M.read_google_sheet_metadata = read_google_sheet_metadata

-- Command
function M.gsheet_read(chat)
    vim.ui.input({ prompt = 'Google Sheet URL or ID: ' }, function(input)
        if not input or gws_helpers.is_blank(input) then
            return
        end

        local sheet, err = read_google_sheet(input)
        if not sheet then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        gws_helpers.add_context(chat, 'Sheet', sheet, 'gsheet')
    end)
end

return M
