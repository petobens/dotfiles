-- luacheck:ignore 631
local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function operation_requires_range(operation)
    return operation == 'append_rows'
        or operation == 'set_range'
        or operation == 'clear_range'
end

local function normalize_requests(args)
    local requests = args.requests_json

    if requests == vim.NIL then
        requests = nil
    end

    if type(requests) == 'string' then
        local ok, decoded = pcall(vim.json.decode, requests)
        if not ok then
            return nil, 'requests_json must be valid JSON for raw_batch_update'
        end
        requests = decoded
    end

    if type(requests) ~= 'table' or vim.tbl_isempty(requests) then
        return nil, 'requests_json must be a non-empty JSON array for raw_batch_update'
    end

    return requests
end

local function validate_values(values)
    if type(values) ~= 'table' or vim.tbl_isempty(values) then
        return nil, 'values must be a non-empty 2D array'
    end

    return values
end

local function write_google_sheet(args)
    local spreadsheet_id, id_err = gw.extract_google_id(args.spreadsheet, 'sheets')
    if not spreadsheet_id then
        return {
            status = 'error',
            data = id_err,
        }
    end

    local operation = gw.normalize_optional_string(args.operation)
    local range = gw.normalize_optional_string(args.range)

    if operation == nil then
        return {
            status = 'error',
            data = 'operation must be a string',
        }
    end

    if operation == '' then
        return {
            status = 'error',
            data = 'Missing operation',
        }
    end

    if range == nil then
        return {
            status = 'error',
            data = 'range must be a string',
        }
    end

    if operation_requires_range(operation) and range == '' then
        return {
            status = 'error',
            data = 'range is required for set_range, append_rows, and clear_range',
        }
    end

    if operation == 'append_rows' or operation == 'set_range' then
        local values, values_err = validate_values(args.values)
        if not values then
            return {
                status = 'error',
                data = values_err,
            }
        end

        args.values = values
    end

    if operation == 'append_rows' then
        local stdout, run_err = gw.run({
            'gws',
            'sheets',
            '+append',
            '--spreadsheet',
            spreadsheet_id,
            '--range',
            range,
            '--json-values',
            vim.json.encode(args.values),
        })

        if not stdout then
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Appended %d row(s) to Google Sheet %s at %s'):format(
                #args.values,
                spreadsheet_id,
                range
            ),
        }
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
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Wrote %d row(s) to Google Sheet %s at %s'):format(
                #args.values,
                spreadsheet_id,
                range
            ),
        }
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
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Cleared Google Sheet %s at %s'):format(spreadsheet_id, range),
        }
    end

    if operation == 'raw_batch_update' then
        local requests, requests_err = normalize_requests(args)
        if not requests then
            return {
                status = 'error',
                data = requests_err,
            }
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
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Applied raw batchUpdate with %d request(s) to Google Sheet %s'):format(
                #requests,
                spreadsheet_id
            ),
        }
    end

    return {
        status = 'error',
        data = 'operation must be one of: set_range, append_rows, clear_range, raw_batch_update',
    }
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
