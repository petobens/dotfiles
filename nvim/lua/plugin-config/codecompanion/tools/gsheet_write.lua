-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Constants
local OPERATION_ENUM = {
    'set_range',
    'append_rows',
    'clear_range',
    'raw_batch_update',
}

-- Validate
local function validate_values(values)
    if type(values) ~= 'table' or vim.tbl_isempty(values) then
        return nil, 'values must be a non-empty 2D array'
    end
    return values
end

local function resolve_sheet_range(args)
    local range, range_err = gws_tool_helpers.normalize_required_string_arg(
        args.range,
        'range',
        { allow_empty = true }
    )
    if range == nil then
        return nil, range_err
    end
    if range == '' then
        return nil, 'range is required for set_range, append_rows, and clear_range'
    end
    return range
end

local function normalize_requests_payload(value)
    local decoded, decode_err = gws_tool_helpers.normalize_json_arg(value, {
        invalid_json_error = 'requests_json must be valid JSON',
    })
    if decoded == nil then
        return nil, decode_err
    end

    if vim.islist(decoded) then
        if vim.tbl_isempty(decoded) then
            return nil, 'requests_json must be a non-empty JSON array'
        end
        return decoded
    end

    if type(decoded) == 'table' and vim.islist(decoded.requests) then
        if vim.tbl_isempty(decoded.requests) then
            return nil, 'requests_json.requests must be a non-empty JSON array'
        end
        return decoded.requests
    end

    return nil,
        'requests_json must be either a JSON array or an object with a non-empty requests array'
end

-- API
local function update_sheet_values(spreadsheet_id, action, range, values)
    local cmd = {
        'gws',
        'sheets',
        'spreadsheets',
        'values',
        action,
        '--params',
        vim.json.encode({
            spreadsheetId = spreadsheet_id,
            range = range,
            valueInputOption = 'USER_ENTERED',
        }),
    }
    if values ~= nil then
        cmd[#cmd + 1] = '--json'
        cmd[#cmd + 1] = vim.json.encode({ values = values })
    end
    return gws_helpers.run(cmd)
end

local function clear_sheet_values(spreadsheet_id, range)
    return gws_helpers.run({
        'gws',
        'sheets',
        'spreadsheets',
        'values',
        'clear',
        '--params',
        vim.json.encode({ spreadsheetId = spreadsheet_id, range = range }),
    })
end

local function batch_update_sheet(spreadsheet_id, requests)
    return gws_helpers.run({
        'gws',
        'sheets',
        'spreadsheets',
        'batchUpdate',
        '--params',
        vim.json.encode({ spreadsheetId = spreadsheet_id }),
        '--json',
        vim.json.encode({ requests = requests }),
    })
end

-- Ops
local function append_rows_operation(spreadsheet_id, args)
    local range, range_err = resolve_sheet_range(args)
    if not range then
        return gws_tool_helpers.tool_error(range_err)
    end

    local values, values_err = validate_values(args.values)
    if not values then
        return gws_tool_helpers.tool_error(values_err)
    end

    local stdout, run_err = update_sheet_values(spreadsheet_id, 'append', range, values)
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Appended %d row(s) to Google Sheet %s at %s'):format(
            #values,
            spreadsheet_id,
            range
        )
    )
end

local function set_range_operation(spreadsheet_id, args)
    local range, range_err = resolve_sheet_range(args)
    if not range then
        return gws_tool_helpers.tool_error(range_err)
    end

    local values, values_err = validate_values(args.values)
    if not values then
        return gws_tool_helpers.tool_error(values_err)
    end

    local stdout, run_err = update_sheet_values(spreadsheet_id, 'update', range, values)
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Wrote %d row(s) to Google Sheet %s at %s'):format(
            #values,
            spreadsheet_id,
            range
        )
    )
end

local function clear_range_operation(spreadsheet_id, args)
    local range, range_err = resolve_sheet_range(args)
    if not range then
        return gws_tool_helpers.tool_error(range_err)
    end

    local stdout, run_err = clear_sheet_values(spreadsheet_id, range)
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Cleared Google Sheet %s at %s'):format(spreadsheet_id, range)
    )
end

local function raw_batch_update_operation(spreadsheet_id, args)
    local requests, requests_err = normalize_requests_payload(args.requests_json)
    if not requests then
        return gws_tool_helpers.tool_error(requests_err)
    end

    local stdout, run_err = batch_update_sheet(spreadsheet_id, requests)
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Applied raw batchUpdate with %d request(s) to Google Sheet %s'):format(
            #requests,
            spreadsheet_id
        )
    )
end

local OPERATIONS = {
    set_range = set_range_operation,
    append_rows = append_rows_operation,
    clear_range = clear_range_operation,
    raw_batch_update = raw_batch_update_operation,
}

-- Prompt builders
local function range_prompt(prefix, args)
    return ('%s Google Sheet `%s` at `%s`?'):format(
        prefix,
        args.spreadsheet,
        gws_helpers.fallback_text(args.range, '(no range provided)')
    )
end

local function build_prompt(args)
    if args.operation == 'raw_batch_update' then
        return ('Apply raw batchUpdate to Google Sheet `%s`?'):format(args.spreadsheet)
    end
    if args.operation == 'append_rows' then
        return range_prompt('Append rows to', args)
    end
    if args.operation == 'set_range' then
        return range_prompt('Write to', args)
    end
    if args.operation == 'clear_range' then
        return range_prompt('Clear', args)
    end
    return ('Write to Google Sheet `%s` using `%s`?'):format(
        args.spreadsheet,
        args.operation
    )
end

local SCHEMA_PROPERTIES = {
    spreadsheet = { type = 'string', description = 'Google Sheet URL or spreadsheet ID' },
    operation = {
        type = 'string',
        enum = OPERATION_ENUM,
        description = 'Write op, prefer high-level ops before raw_batch_update.',
    },
    range = { type = 'string', description = 'Worksheet name or A1 range.' },
    values = {
        type = 'array',
        description = '2D values array for set_range or append_rows.',
        items = {
            type = 'array',
            items = {
                anyOf = {
                    { type = 'string' },
                    { type = 'number' },
                    { type = 'boolean' },
                    { type = 'null' },
                },
            },
        },
    },
    requests_json = {
        type = 'string',
        description = 'Raw batchUpdate JSON, accepts a JSON array or an object with a requests array.',
    },
}

-- Dispatch
local function write_sheet(args)
    local spreadsheet_id, id_err =
        gws_tool_helpers.extract_google_id_arg(args.spreadsheet, 'sheets', 'spreadsheet')
    if not spreadsheet_id then
        return gws_tool_helpers.tool_error(id_err)
    end

    local operation, operation_err =
        gws_tool_helpers.normalize_required_string_arg(args.operation, 'operation')
    if not operation then
        return gws_tool_helpers.tool_error(operation_err)
    end

    local operation_fn = OPERATIONS[operation]
    if not operation_fn then
        return gws_tool_helpers.tool_error('unsupported gsheet_write operation')
    end
    return operation_fn(spreadsheet_id, args)
end

local M = {
    name = 'gsheet_write',
    cmds = {
        function(_, args, _)
            return write_sheet(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gsheet_write',
            description = 'Write to a Google Sheet.',
            parameters = {
                type = 'object',
                properties = SCHEMA_PROPERTIES,
                required = { 'spreadsheet', 'operation' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            return build_prompt(self.args)
        end,
        success = function(self, stdout, meta)
            gws_tool_helpers.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Sheet write succeeded'
            )
        end,
        error = function(self, stderr, meta)
            gws_tool_helpers.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Sheet write failed'
            )
        end,
    },
}

return M
