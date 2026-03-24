local gsheets = require('plugin-config.codecompanion.slash_commands.gsheets')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function inspect_google_sheet(args)
    local sheet, err = gsheets.read_google_sheet_metadata(args.spreadsheet)
    if not sheet then
        return {
            status = 'error',
            data = err,
        }
    end

    return {
        status = 'success',
        data = string.format(
            'Here is the structure of the Google Sheet "%s" (ID: %s):\n\n%s',
            sheet.title,
            sheet.id,
            sheet.text
        ),
    }
end

-- Tool definition
local M = {
    name = 'gsheet_inspect',
    cmds = {
        function(_, args, _)
            return inspect_google_sheet(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gsheet_inspect',
            description = 'Read Google Sheet structure.',
            parameters = {
                type = 'object',
                properties = {
                    spreadsheet = {
                        type = 'string',
                        description = 'Google Sheet URL or spreadsheet ID',
                    },
                },
                required = { 'spreadsheet' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            return ('Inspect Google Sheet `%s` structure?'):format(self.args.spreadsheet)
        end,
        success = function(self, stdout, meta)
            helper.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Read Google Sheet structure'
            )
        end,
        error = function(self, stderr, meta)
            helper.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Sheet structure read failed'
            )
        end,
    },
}

return M
