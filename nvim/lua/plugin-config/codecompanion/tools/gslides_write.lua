-- luacheck:ignore 631
local gslides = require('plugin-config.codecompanion.slash_commands.gslides')
local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')
local helper = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Helpers
local function resolve_slide_object_id(presentation_id, args)
    local slide_object_id, slide_object_id_err = helper.normalize_required_string_arg(
        args.slide_object_id,
        'slide_object_id',
        { allow_empty = true }
    )
    if slide_object_id == nil then
        return nil, slide_object_id_err
    end

    if slide_object_id ~= '' then
        return slide_object_id
    end

    if type(args.slide_index) ~= 'number' then
        return nil, 'slide_object_id or slide_index is required for delete_slide'
    end

    if args.slide_index < 1 or args.slide_index % 1 ~= 0 then
        return nil, 'slide_index must be a positive integer'
    end

    local slides, fetch_err = gslides.fetch_google_slides(presentation_id)
    if not slides then
        return nil, fetch_err
    end

    local slide = (slides.slides or {})[args.slide_index]
    local object_id = slide and gw.fallback_text(slide.objectId, nil)
    if not object_id then
        return nil, ('Slide index %d was not found'):format(args.slide_index)
    end

    return object_id
end

local function write_google_slides(args)
    local presentation_id, id_err =
        helper.extract_google_id_arg(args.presentation, 'slides', 'presentation')
    if not presentation_id then
        return helper.tool_error(id_err)
    end

    local operation, operation_err =
        helper.normalize_required_string_arg(args.operation, 'operation')
    if not operation then
        return helper.tool_error(operation_err)
    end

    if operation == 'delete_slide' then
        local slide_object_id, slide_object_id_err =
            resolve_slide_object_id(presentation_id, args)
        if not slide_object_id then
            return helper.tool_error(slide_object_id_err)
        end

        local stdout, run_err = gw.run({
            'gws',
            'slides',
            'presentations',
            'batchUpdate',
            '--params',
            vim.json.encode({
                presentationId = presentation_id,
            }),
            '--json',
            vim.json.encode({
                requests = {
                    {
                        deleteObject = {
                            objectId = slide_object_id,
                        },
                    },
                },
            }),
        })

        if not stdout then
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Deleted slide %s from Google Slides %s'):format(
                slide_object_id,
                presentation_id
            )
        )
    end

    if operation == 'replace_all_text' then
        local match_text, match_text_err =
            helper.normalize_required_string_arg(args.match_text, 'match_text', {
                empty_error = 'match_text is required for replace_all_text',
            })
        if not match_text then
            return helper.tool_error(match_text_err)
        end

        local replace_text, replace_text_err = helper.normalize_required_string_arg(
            args.replace_text,
            'replace_text',
            { allow_empty = true }
        )
        if replace_text == nil then
            return helper.tool_error(replace_text_err)
        end

        local stdout, run_err = gw.run({
            'gws',
            'slides',
            'presentations',
            'batchUpdate',
            '--params',
            vim.json.encode({
                presentationId = presentation_id,
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
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Replaced all matches of "%s" in Google Slides %s'):format(
                match_text,
                presentation_id
            )
        )
    end

    if operation == 'raw_batch_update' then
        local requests, requests_err =
            helper.normalize_json_array_arg(args.requests_json, {
                invalid_json_error = 'requests_json must be valid JSON for raw_batch_update',
                empty_error = 'requests_json must be a non-empty JSON array for raw_batch_update',
            })
        if not requests then
            return helper.tool_error(requests_err)
        end

        local stdout, run_err = gw.run({
            'gws',
            'slides',
            'presentations',
            'batchUpdate',
            '--params',
            vim.json.encode({
                presentationId = presentation_id,
            }),
            '--json',
            vim.json.encode({
                requests = requests,
            }),
        })

        if not stdout then
            return helper.tool_error(run_err)
        end

        return helper.tool_success(
            ('Applied raw batchUpdate with %d request(s) to Google Slides %s'):format(
                #requests,
                presentation_id
            )
        )
    end

    return helper.tool_error(
        'operation must be one of: delete_slide, replace_all_text, raw_batch_update'
    )
end

-- Tool definition
local M = {
    name = 'gslides_write',
    cmds = {
        function(_, args, _)
            return write_google_slides(args)
        end,
    },
    schema = {
        type = 'function',
        ['function'] = {
            name = 'gslides_write',
            description = 'Write to Google Slides.',
            parameters = {
                type = 'object',
                properties = {
                    presentation = {
                        type = 'string',
                        description = 'Google Slides URL or presentation ID',
                    },
                    operation = {
                        type = 'string',
                        enum = {
                            'delete_slide',
                            'replace_all_text',
                            'raw_batch_update',
                        },
                        description = 'Write operation.',
                    },
                    match_text = {
                        type = 'string',
                        description = 'Text to match when using replace_all_text.',
                    },
                    replace_text = {
                        type = 'string',
                        description = 'Replacement text when using replace_all_text.',
                    },
                    slide_object_id = {
                        type = 'string',
                        description = 'Slide object ID to delete when using delete_slide.',
                    },
                    slide_index = {
                        type = 'integer',
                        description = '1-based slide index to delete when using delete_slide.',
                    },
                    requests_json = {
                        type = 'string',
                        description = 'JSON string containing raw batchUpdate requests.',
                    },
                },
                required = { 'presentation', 'operation' },
                additionalProperties = false,
            },
            strict = true,
        },
    },
    output = {
        prompt = function(self, _)
            if self.args.operation == 'raw_batch_update' then
                return ('Apply raw batchUpdate to Google Slides `%s`?'):format(
                    self.args.presentation
                )
            end

            if self.args.operation == 'delete_slide' then
                local target = self.args.slide_object_id
                if not target and type(self.args.slide_index) == 'number' then
                    target = ('slide #%d'):format(self.args.slide_index)
                end
                target = gw.fallback_text(target, '(no slide target provided)')

                return ('Delete `%s` from Google Slides `%s`?'):format(
                    target,
                    self.args.presentation
                )
            end

            local match_text =
                gw.fallback_text(self.args.match_text, '(no match_text provided)')

            return ('Write to Google Slides `%s` using `%s` with match `%s`?'):format(
                self.args.presentation,
                self.args.operation,
                match_text
            )
        end,
        success = function(self, stdout, meta)
            helper.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Slides write succeeded'
            )
        end,
        error = function(self, stderr, meta)
            helper.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Slides write failed'
            )
        end,
    },
}

return M
