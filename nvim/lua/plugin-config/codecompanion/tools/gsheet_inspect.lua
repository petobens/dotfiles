local gsheets = require('plugin-config.codecompanion.slash_commands.gsheets')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

return gws_tool_helpers.build_read_tool({
    name = 'gsheet_inspect',
    description = 'Read Google Sheet structure.',
    input_key = 'spreadsheet',
    input_description = 'Google Sheet URL or spreadsheet ID',
    reader = gsheets.read_google_sheet_metadata,
    template = 'Here is the structure of the Google Sheet "%s" (ID: %s):\n\n%s',
    prompt_template = 'Inspect Google Sheet `%s` structure?',
    success_user_output = 'Read Google Sheet structure',
    error_user_output = 'Google Sheet structure read failed',
})
