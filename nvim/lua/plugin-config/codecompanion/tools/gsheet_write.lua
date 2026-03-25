-- luacheck:ignore 631
local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function operation_requires_range(operation)
    return operation == 'append_rows'
        or operation == 'set_range'
        or operation == 'clear_range'
end

local function validate_values(values)
    if type(values) ~= 'table' or vim.tbl_isempty(values) then
        return nil, 'values must be a non-empty 2D array'
    end

    return values
end

local function write_google_sheet(args)
    local spreadsheet_id, id_err =
        helper.extract_google_id_arg(args.spreadsheet, 'sheets', 'spreadsheet')
    if not spreadsheet_id then
        return helper.tool_error(id_err)
    end

    local operation, operation_err =
        helper.normalize_required_string_arg(args.operation, 'operation')
    if not operation then
        return helper.tool_error(operation_err)
    end

    local range, range_err = helper.normalize_required_string_arg(args.range, 'range', {
        allow_empty = true,
    })
    if range == nil then
        return helper.tool_error(range_err)
    end

    if operation_requires_range(operation) and range == '' then
        return helper.tool_error(
            'range is required for set_range, append_rows, and clear_range'
        )
    end

    if operation == 'append_rows' or operation == 'set_range' then
        local values, values_err = validate_values(args.values)
        if not values then
            return helper.tool_error(values_err)
        end

        args.values = values
    end

    if operation == 'append_rows' then
        local stdout, run_err = gw.run({
            'gws',
            'sheets',
            'spreadsheets',
            'values',
            'append',
            '--params',
            vim.json.encode({
                spreadsheetId = spreadsheet_id,
                range = range,
                valueInputOption = 'USER_ENTERED',
            }),
            '--json',
            vim.json.encode({
                values = args.values,
            }),
        })

        if not stdout then
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Appended %d row(s) to Google Sheet %s at %s'):format(
                #args.values,
                spreadsheet_id,
                range
            )
        )
    end

    if operation == 'set_range' then
        local stdout, run_err = gw.run({
            'gws',
            'sheets',
            'spreadsheets',
            'values',
            'update',
            '--params',
            vim.json.encode({
                spreadsheetId = spreadsheet_id,
                range = range,
                valueInputOption = 'USER_ENTERED',
            }),
            '--json',
            vim.json.encode({
                values = args.values,
            }),
        })

        if not stdout then
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Wrote %d row(s) to Google Sheet %s at %s'):format(
                #args.values,
                spreadsheet_id,
                range
            )
        )
    end

    if operation == 'clear_range' then
        local stdout, run_err = gw.run({
            'gws',
            'sheets',
            'spreadsheets',
            'values',
            'clear',
            '--params',
            vim.json.encode({
                spreadsheetId = spreadsheet_id,
                range = range,
            }),
        })

        if not stdout then
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Cleared Google Sheet %s at %s'):format(spreadsheet_id, range)
        )
    end

    if operation == 'raw_batch_update' then
        local requests, requests_err =
            helper.normalize_json_array_arg(args.requests_json, {
                invalid_json_error = 'requests_json must be valid JSON for raw_batch_update',
                empty_error = 'requests_json must be a non-empty JSON array for raw_batch_update',
            })
        if not requests then
            return helper.tool_error(requests_err)
        end

        local stdout, run_err = gw.run({
            'gws',
            'sheets',
            'spreadsheets',
            'batchUpdate',
            '--params',
            vim.json.encode({
                spreadsheetId = spreadsheet_id,
            }),
            '--json',
            vim.json.encode({
                requests = requests,
            }),
        })

        if not stdout then
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Applied raw batchUpdate with %d request(s) to Google Sheet %s'):format(
                #requests,
                spreadsheet_id
            )
        )
    end

    return helper.tool_error(
        'operation must be one of: set_range, append_rows, clear_range, raw_batch_update'
    )
end

-- Tool definition
local M = {
    name = 'gsheet_write',
    cmds = {
        function(_, args, _)
            return write_google_sheet(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gsheet_write',
            description = 'Write to a Google Sheet.',
            parameters = {
                type = 'object',
                properties = {
                    spreadsheet = {
                        type = 'string',
                        description = 'Google Sheet URL or spreadsheet ID',
                    },
                    operation = {
                        type = 'string',
                        enum = {
                            'set_range',
                            'append_rows',
                            'clear_range',
                            'raw_batch_update',
                        },
                        description = 'Write operation.',
                    },
                    range = {
                        type = 'string',
                        description = 'Worksheet name or A1 range.',
                    },
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
                        description = 'JSON string containing raw batchUpdate requests.',
                    },
                },
                required = { 'spreadsheet', 'operation' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            if self.args.operation == 'raw_batch_update' then
                return ('Apply raw batchUpdate to Google Sheet `%s`?'):format(
                    self.args.spreadsheet
                )
            end

            local range = gw.fallback_text(self.args.range, '(no range provided)')

            return ('Write to Google Sheet `%s` using `%s` on `%s`?'):format(
                self.args.spreadsheet,
                self.args.operation,
                range
            )
        end,
        success = function(self, stdout, meta)
            helper.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Sheet write succeeded'
            )
        end,
        error = function(self, stderr, meta)
            helper.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Sheet write failed'
            )
        end,
    },
}

return M
