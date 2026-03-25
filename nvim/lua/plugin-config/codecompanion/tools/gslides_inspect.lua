local gslides = require('plugin-config.codecompanion.slash_commands.gslides')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

return gws_tool_helpers.build_read_tool({
    name = 'gslides_inspect',
    description = 'Read Google Slides structure.',
    input_key = 'presentation',
    input_description = 'Google Slides URL or presentation ID',
    reader = gslides.read_google_slides_metadata,
    template = 'Here is the structure of the Google Slides "%s" (ID: %s):\n\n%s',
    prompt_template = 'Inspect Google Slides `%s` structure?',
    success_user_output = 'Read Google Slides structure',
    error_user_output = 'Google Slides structure read failed',
})
