local gdocs = require('plugin-config.codecompanion.slash_commands.gdocs')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function read_google_doc(args)
    local doc, err = gdocs.read_google_doc(args.document)
    if not doc then
        return {
            status = 'error',
            data = err,
        }
    end

    return {
        status = 'success',
        data = string.format(
            'Here is the content of the Google Doc "%s" (ID: %s):\n\n%s',
            doc.title,
            doc.id,
            doc.text
        ),
    }
end

-- Tool definition
local M = {
    name = 'gdoc_read',
    cmds = {
        function(_, args, _)
            return read_google_doc(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gdoc_read',
            description = 'Read Google Doc contents.',
            parameters = {
                type = 'object',
                properties = {
                    document = {
                        type = 'string',
                        description = 'Google Doc URL or document ID',
                    },
                },
                required = { 'document' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            return ('Read Google Doc `%s`?'):format(self.args.document)
        end,
        success = function(self, stdout, meta)
            helper.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Read Google Doc contents'
            )
        end,
        error = function(self, stderr, meta)
            helper.add_tool_error(meta.tools.chat, self, stderr, 'Google Doc read failed')
        end,
    },
}

return M
