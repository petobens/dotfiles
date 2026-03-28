local gslides = require('plugin-config.codecompanion.slash_commands.gslides')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

return gws_tool_helpers.build_read_tool({
    name = 'gslides_read',
    description = 'Read Google Slides contents.',
    input_key = 'presentation',
    input_description = 'Google Slides URL or presentation ID',
    reader = gslides.read_slides,
    template = 'Here is the content of the Google Slides "%s" (ID: %s):\n\n%s',
    prompt_template = 'Read Google Slides `%s`?',
    success_user_output = 'Read Google Slides contents',
    error_user_output = 'Google Slides read failed',
})
