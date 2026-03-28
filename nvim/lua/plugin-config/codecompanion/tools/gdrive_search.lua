local gdrive = require('plugin-config.codecompanion.slash_commands.gdrive')
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Constants
local FILE_TYPE_ENUM = {
    '',
    'all',
    'doc',
    'docs',
    'sheet',
    'sheets',
    'slide',
    'slides',
}

-- Search
local function search_drive(args)
    local query, query_err =
        gws_tool_helpers.normalize_required_string_arg(args.query, 'query')
    if not query then
        return gws_tool_helpers.tool_error(query_err)
    end

    local file_type_input, file_type_err = gws_tool_helpers.normalize_required_string_arg(
        args.file_type,
        'file_type',
        { allow_empty = true }
    )
    if file_type_input == nil then
        return gws_tool_helpers.tool_error(file_type_err)
    end

    local file_type, parsed_file_type_err = gdrive.parse_file_type(file_type_input)
    if not file_type then
        return gws_tool_helpers.tool_error(parsed_file_type_err)
    end

    local result, err = gdrive.search_drive(query, file_type)
    if not result then
        return gws_tool_helpers.tool_error(err)
    end

    return gws_tool_helpers.tool_success(
        ('Here are the Google Drive %s results for "%s":\n\n%s'):format(
            file_type.label,
            gws_helpers.trim(query),
            result.text
        )
    )
end

-- Prompt builders
local function build_prompt(args)
    return ('Search Google Drive for `%s` in `%s`?'):format(
        args.query,
        gws_helpers.fallback_text(args.file_type, 'all')
    )
end

local SCHEMA_PROPERTIES = {
    query = { type = 'string', description = 'Search query.' },
    file_type = {
        type = 'string',
        enum = FILE_TYPE_ENUM,
        description = 'Optional type filter.',
    },
}

local M = {
    name = 'gdrive_search',
    cmds = {
        function(_, args, _)
            return search_drive(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gdrive_search',
            description = 'Search Google Drive files.',
            parameters = {
                type = 'object',
                properties = SCHEMA_PROPERTIES,
                required = { 'query' },
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
                'Google Drive search succeeded'
            )
        end,
        error = function(self, stderr, meta)
            gws_tool_helpers.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Drive search failed'
            )
        end,
    },
}

return M
