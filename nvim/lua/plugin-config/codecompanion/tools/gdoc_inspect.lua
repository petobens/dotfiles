local gdocs = require('plugin-config.codecompanion.slash_commands.gdocs')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

return gws_tool_helpers.build_read_tool({
    name = 'gdoc_inspect',
    description = 'Read Google Doc structure.',
    input_key = 'document',
    input_description = 'Google Doc URL or document ID',
    reader = gdocs.read_google_doc_metadata,
    template = 'Here is the structure of the Google Doc "%s" (ID: %s):\n\n%s',
    prompt_template = 'Inspect Google Doc `%s` structure?',
    success_user_output = 'Read Google Doc structure',
    error_user_output = 'Google Doc structure read failed',
})
