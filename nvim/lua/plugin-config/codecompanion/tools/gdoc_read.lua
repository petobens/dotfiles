local gdocs = require('plugin-config.codecompanion.slash_commands.gdocs')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

return gws_tool_helpers.build_read_tool({
    name = 'gdoc_read',
    description = 'Read Google Doc contents.',
    input_key = 'document',
    input_description = 'Google Doc URL or document ID',
    reader = gdocs.read_doc,
    template = 'Here is the content of the Google Doc "%s" (ID: %s):\n\n%s',
    prompt_template = 'Read Google Doc `%s`?',
    success_user_output = 'Read Google Doc contents',
    error_user_output = 'Google Doc read failed',
})
