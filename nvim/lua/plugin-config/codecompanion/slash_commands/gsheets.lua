local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')

local M = {}

local DEFAULT_RANGE = 'A1:AZ2000'

-- API fetch
local function fetch_google_sheet_metadata(sheet_id)
    local stdout, run_err = gw.run({
        'gws',
        'sheets',
        'spreadsheets',
        'get',
        '--params',
        vim.json.encode({
            spreadsheetId = sheet_id,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return gw.decode_json(stdout, 'the Google Sheet metadata')
end

local function fetch_google_sheet_values(sheet_id, ranges, value_render_option)
    local stdout, run_err = gw.run({
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

    return gw.decode_json(stdout, 'the Google Sheet values')
end

-- Content extraction
local function sheet_range_to_title(range)
    local title = gw.trim((range or ''):match("^'(.+)'!"))
    if title ~= '' then
        return title:gsub("''", "'")
    end

    title = gw.trim((range or ''):match('^([^!]+)!'))
    if title ~= '' then
        return title
    end

    return 'Unknown worksheet'
end

local function render_value_ranges(label, value_ranges)
    if vim.tbl_isempty(value_ranges or {}) then
        return nil
    end

    local sections = { ('Mode: %s'):format(label), '' }
    local nonempty_tabs = 0

    for _, value_range in ipairs(value_ranges) do
        local title = sheet_range_to_title(value_range.range)
        local values = value_range.values or {}

        if not vim.tbl_isempty(values) then
            nonempty_tabs = nonempty_tabs + 1
            table.insert(sections, ('Worksheet: %s'):format(title))

            local lines = vim.iter(values)
                :map(function(row)
                    return table.concat(vim.tbl_map(tostring, row), ' | ')
                end)
                :totable()

            vim.list_extend(sections, lines)
            table.insert(sections, '')
        end
    end

    if nonempty_tabs == 0 then
        return nil
    end

    return gw.normalize_text(table.concat(sections, '\n'))
end

-- Read helpers
local function read_google_sheet(input)
    local sheet_id, id_err = gw.extract_google_id(input, 'sheets')
    if not sheet_id then
        return nil, id_err
    end

    local metadata, metadata_err = fetch_google_sheet_metadata(sheet_id)
    if not metadata then
        return nil, metadata_err
    end

    local sheets = metadata.sheets or {}
    if vim.tbl_isempty(sheets) then
        return nil, 'No worksheets found in the Google Sheet'
    end

    local titles = vim.iter(sheets)
        :map(function(sheet)
            return vim.tbl_get(sheet, 'properties', 'title')
        end)
        :filter(function(title)
            return type(title) == 'string' and title ~= ''
        end)
        :totable()

    if vim.tbl_isempty(titles) then
        return nil, 'No readable worksheets found in the Google Sheet'
    end

    local ranges = vim.iter(titles)
        :map(function(title)
            return string.format("'%s'!%s", title:gsub("'", "''"), DEFAULT_RANGE)
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
    }

    if values_text then
        table.insert(parts, values_text)
        table.insert(parts, '')
    end

    if formulas_text then
        table.insert(parts, formulas_text)
    end

    return {
        id = sheet_id,
        title = gw.trim(vim.tbl_get(metadata, 'properties', 'title')) ~= '' and gw.trim(
            vim.tbl_get(metadata, 'properties', 'title')
        ) or 'Untitled spreadsheet',
        text = gw.normalize_text(table.concat(parts, '\n')),
    }
end

-- Slash commands
function M.gsheet(chat)
    vim.ui.input({ prompt = 'Google Sheet URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        local sheet, err = read_google_sheet(input)
        if not sheet then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        gw.add_context(chat, 'Sheet', sheet, 'gsheet')
    end)
end

return M
