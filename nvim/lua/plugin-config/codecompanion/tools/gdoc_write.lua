-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Constants
local OPERATION_ENUM = {
    'append_text',
    'replace_all_text',
    'raw_batch_update',
}

-- API
local function batch_update_doc(document_id, requests)
    return gws_helpers.run({
        'gws',
        'docs',
        'documents',
        'batchUpdate',
        '--params',
        vim.json.encode({ documentId = document_id }),
        '--json',
        vim.json.encode({ requests = requests }),
    })
end

-- Ops
local function append_text_operation(document_id, args)
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

local function replace_all_text_operation(document_id, args)
    local match_text, match_text_err = gws_tool_helpers.normalize_required_string_arg(
        args.match_text,
        'match_text',
        { empty_error = 'match_text is required for replace_all_text' }
    )
    if not match_text then
        return gws_tool_helpers.tool_error(match_text_err)
    end

    local replace_text, replace_text_err = gws_tool_helpers.normalize_required_string_arg(
        args.replace_text,
        'replace_text',
        { allow_empty = true }
    )
    if replace_text == nil then
        return gws_tool_helpers.tool_error(replace_text_err)
    end

    local stdout, run_err = batch_update_doc(document_id, {
        {
            replaceAllText = {
                containsText = { text = match_text, matchCase = true },
                replaceText = replace_text,
            },
        },
    })
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Replaced all matches of "%s" in Google Doc %s'):format(match_text, document_id)
    )
end

local function raw_batch_update_operation(document_id, args)
    local requests, requests_err =
        gws_tool_helpers.normalize_json_array_arg(args.requests_json, {
            invalid_json_error = 'requests_json must be valid JSON',
            empty_error = 'requests_json must be a non-empty JSON array',
        })
    if not requests then
        return gws_tool_helpers.tool_error(requests_err)
    end

    local stdout, run_err = batch_update_doc(document_id, requests)
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

local OPERATIONS = {
    append_text = append_text_operation,
    replace_all_text = replace_all_text_operation,
    raw_batch_update = raw_batch_update_operation,
}

-- Prompt builders
local function build_prompt(args)
    if args.operation == 'raw_batch_update' then
        return ('Apply raw batchUpdate to Google Doc `%s`?'):format(args.document)
    end
    if args.operation == 'append_text' then
        return ('Append text to Google Doc `%s`?'):format(args.document)
    end
    if args.operation == 'replace_all_text' then
        return ('Replace all matches of `%s` in Google Doc `%s`?'):format(
            gws_helpers.fallback_text(args.match_text, '(no match_text provided)'),
            args.document
        )
    end
    return ('Write to Google Doc `%s` using `%s`?'):format(args.document, args.operation)
end

local SCHEMA_PROPERTIES = {
    document = { type = 'string', description = 'Google Doc URL or document ID' },
    operation = {
        type = 'string',
        enum = OPERATION_ENUM,
        description = 'Write op, prefer high-level ops before raw_batch_update.',
    },
    text = { type = 'string', description = 'Text for append_text.' },
    match_text = { type = 'string', description = 'Text to match.' },
    replace_text = { type = 'string', description = 'Replacement text.' },
    requests_json = { type = 'string', description = 'Raw batchUpdate JSON.' },
}

-- Dispatch
local function write_doc(args)
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

    local operation_fn = OPERATIONS[operation]
    if not operation_fn then
        return gws_tool_helpers.tool_error('unsupported gdoc_write operation')
    end
    return operation_fn(document_id, args)
end

local M = {
    name = 'gdoc_write',
    cmds = {
        function(_, args, _)
            return write_doc(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gdoc_write',
            description = 'Write to a Google Doc.',
            parameters = {
                type = 'object',
                properties = SCHEMA_PROPERTIES,
                required = { 'document', 'operation' },
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
