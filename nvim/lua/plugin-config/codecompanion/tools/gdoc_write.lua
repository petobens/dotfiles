-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function write_google_doc(args)
    local document_id, id_err =
        gws_tool_helpers.extract_google_id_arg(args.document, 'docs', 'document')
    if not document_id then
        return gws_tool_helpers.tool_error(id_err)
    end

    local operation, operation_err =
        gws_tool_helpers.normalize_required_string_arg(args.operation, 'operation')
    if not operation then
        return gws_tool_helpers.tool_error(operation_err)
    end

    if operation == 'append_text' then
        local text, text_err =
            gws_tool_helpers.normalize_required_string_arg(args.text, 'text', {
                empty_error = 'text is required for append_text',
            })
        if not text then
            return gws_tool_helpers.tool_error(text_err)
        end

        local stdout, run_err = gws_helpers.run({
            'gws',
            'docs',
            '+write',
            '--document',
            document_id,
            '--text',
            text,
        })

        if not stdout then
            return gws_tool_helpers.tool_error(run_err)
        end

        return gws_tool_helpers.tool_success(
            ('Appended text to Google Doc %s'):format(document_id)
        )
    end

    if operation == 'replace_all_text' then
        local match_text, match_text_err = gws_tool_helpers.normalize_required_string_arg(
            args.match_text,
            'match_text',
            {
                empty_error = 'match_text is required for replace_all_text',
            }
        )
        if not match_text then
            return gws_tool_helpers.tool_error(match_text_err)
        end

        local replace_text, replace_text_err =
            gws_tool_helpers.normalize_required_string_arg(
                args.replace_text,
                'replace_text',
                { allow_empty = true }
            )
        if replace_text == nil then
            return gws_tool_helpers.tool_error(replace_text_err)
        end

        local stdout, run_err = gws_helpers.run({
            'gws',
            'docs',
            'documents',
            'batchUpdate',
            '--params',
            vim.json.encode({
                documentId = document_id,
            }),
            '--json',
            vim.json.encode({
                requests = {
                    {
                        replaceAllText = {
                            containsText = {
                                text = match_text,
                                matchCase = true,
                            },
                            replaceText = replace_text,
                        },
                    },
                },
            }),
        })

        if not stdout then
            return gws_tool_helpers.tool_error(run_err)
        end

        return gws_tool_helpers.tool_success(
            ('Replaced all matches of "%s" in Google Doc %s'):format(
                match_text,
                document_id
            )
        )
    end

    if operation == 'raw_batch_update' then
        local requests, requests_err =
            gws_tool_helpers.normalize_json_array_arg(args.requests_json, {
                invalid_json_error = 'requests_json must be valid JSON',
                empty_error = 'requests_json must be a non-empty JSON array',
            })
        if not requests then
            return gws_tool_helpers.tool_error(requests_err)
        end

        local stdout, run_err = gws_helpers.run({
            'gws',
            'docs',
            'documents',
            'batchUpdate',
            '--params',
            vim.json.encode({
                documentId = document_id,
            }),
            '--json',
            vim.json.encode({
                requests = requests,
            }),
        })

        if not stdout then
            return gws_tool_helpers.tool_error(run_err)
        end

        return gws_tool_helpers.tool_success(
            ('Applied raw batchUpdate with %d request(s) to Google Doc %s'):format(
                #requests,
                document_id
            )
        )
    end

    return gws_tool_helpers.tool_error(
        'operation must be one of: append_text, replace_all_text, raw_batch_update'
    )
end

-- Tool definition
local M = {
    name = 'gdoc_write',
    cmds = {
        function(_, args, _)
            return write_google_doc(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gdoc_write',
            description = 'Write to a Google Doc.',
            parameters = {
                type = 'object',
                properties = {
                    document = {
                        type = 'string',
                        description = 'Google Doc URL or document ID',
                    },
                    operation = {
                        type = 'string',
                        enum = {
                            'append_text',
                            'replace_all_text',
                            'raw_batch_update',
                        },
                        description = 'Write operation.',
                    },
                    text = {
                        type = 'string',
                        description = 'Text to append when using append_text.',
                    },
                    match_text = {
                        type = 'string',
                        description = 'Text to match when using replace_all_text.',
                    },
                    replace_text = {
                        type = 'string',
                        description = 'Replacement text when using replace_all_text.',
                    },
                    requests_json = {
                        type = 'string',
                        description = 'JSON string containing raw batchUpdate requests.',
                    },
                },
                required = { 'document', 'operation' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            if self.args.operation == 'raw_batch_update' then
                return ('Apply raw batchUpdate to Google Doc `%s`?'):format(
                    self.args.document
                )
            end

            if self.args.operation == 'append_text' then
                return ('Append text to Google Doc `%s`?'):format(self.args.document)
            end

            local match_text = gws_helpers.fallback_text(
                self.args.match_text,
                '(no match_text provided)'
            )

            return ('Write to Google Doc `%s` using `%s` with match `%s`?'):format(
                self.args.document,
                self.args.operation,
                match_text
            )
        end,
        success = function(self, stdout, meta)
            gws_tool_helpers.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Doc write succeeded'
            )
        end,
        error = function(self, stderr, meta)
            gws_tool_helpers.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Doc write failed'
            )
        end,
    },
}

return M
