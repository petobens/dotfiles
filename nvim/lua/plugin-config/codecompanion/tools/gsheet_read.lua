local gsheets = require('plugin-config.codecompanion.slash_commands.gsheets')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

return gws_tool_helpers.build_read_tool({
    name = 'gsheet_read',
    description = 'Read Google Sheet contents.',
    input_key = 'spreadsheet',
    input_description = 'Google Sheet URL or spreadsheet ID',
    reader = gsheets.read_sheet,
    template = 'Here is the content of the Google Sheet "%s" (ID: %s):\n\n%s',
    prompt_template = 'Read Google Sheet `%s`?',
    success_user_output = 'Read Google Sheet contents',
    error_user_output = 'Google Sheet read failed',
})
