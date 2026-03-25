-- luacheck:ignore 631
local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function normalize_requests(args)
    local requests = args.requests_json

    if requests == vim.NIL then
        requests = nil
    end

    if type(requests) == 'string' then
        local ok, decoded = pcall(vim.json.decode, requests)
        if not ok then
            return nil, 'requests_json must be valid JSON'
        end
        requests = decoded
    end

    if type(requests) ~= 'table' or vim.tbl_isempty(requests) then
        return nil, 'requests_json must be a non-empty JSON array'
    end

    return requests
end

local function write_google_doc(args)
    local document_id, id_err = gw.extract_google_id(args.document, 'docs')
    if not document_id then
        return {
            status = 'error',
            data = id_err,
        }
    end

    local operation = gw.normalize_optional_string(args.operation)
    if operation == nil then
        return {
            status = 'error',
            data = 'operation must be a string',
        }
    end

    if operation == '' then
        return {
            status = 'error',
            data = 'Missing operation',
        }
    end

    if operation == 'append_text' then
        local text = gw.normalize_optional_string(args.text)
        if text == nil then
            return {
                status = 'error',
                data = 'text must be a string',
            }
        end

        if text == '' then
            return {
                status = 'error',
                data = 'text is required for append_text',
            }
        end

        local stdout, run_err = gw.run({
            'gws',
            'docs',
            '+write',
            '--document',
            document_id,
            '--text',
            text,
        })

        if not stdout then
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Appended text to Google Doc %s'):format(document_id),
        }
    end

    if operation == 'replace_all_text' then
        local match_text = gw.normalize_optional_string(args.match_text)
        local replace_text = gw.normalize_optional_string(args.replace_text)

        if match_text == nil then
            return {
                status = 'error',
                data = 'match_text must be a string',
            }
        end

        if replace_text == nil then
            return {
                status = 'error',
                data = 'replace_text must be a string',
            }
        end

        if match_text == '' then
            return {
                status = 'error',
                data = 'match_text is required for replace_all_text',
            }
        end

        local stdout, run_err = gw.run({
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
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Replaced all matches of "%s" in Google Doc %s'):format(
                match_text,
                document_id
            ),
        }
    end

    if operation == 'raw_batch_update' then
        local requests, requests_err = normalize_requests(args)
        if not requests then
            return {
                status = 'error',
                data = requests_err,
            }
        end

        local stdout, run_err = gw.run({
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
            return {
                status = 'error',
                data = run_err,
            }
        end

        return {
            status = 'success',
            data = ('Applied raw batchUpdate with %d request(s) to Google Doc %s'):format(
                #requests,
                document_id
            ),
        }
    end

    return {
        status = 'error',
        data = 'operation must be one of: append_text, replace_all_text, raw_batch_update',
    }
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

            local match_text =
                gw.fallback_text(self.args.match_text, '(no match_text provided)')

            return ('Write to Google Doc `%s` using `%s` with match `%s`?'):format(
                self.args.document,
                self.args.operation,
                match_text
            )
        end,
        success = function(self, stdout, meta)
            helper.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Doc write succeeded'
            )
        end,
        error = function(self, stderr, meta)
            helper.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Doc write failed'
            )
        end,
    },
}

return M
