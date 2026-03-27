-- luacheck:ignore 631
local gslides = require('plugin-config.codecompanion.slash_commands.gslides')
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Shared helpers
local function resolve_slide_object_id(presentation_id, args)
    local slide_object_id, slide_object_id_err =
        gws_tool_helpers.normalize_required_string_arg(
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
        return nil, 'slide_object_id or slide_index is required'
    end

    if args.slide_index < 1 or args.slide_index % 1 ~= 0 then
        return nil, 'slide_index must be a positive integer'
    end

    local slides, fetch_err = gslides.fetch_google_slides(presentation_id)
    if not slides then
        return nil, fetch_err
    end

    local slide = (slides.slides or {})[args.slide_index]
    local object_id = slide and gws_helpers.fallback_text(slide.objectId, nil)
    if not object_id then
        return nil, ('Slide index %d was not found'):format(args.slide_index)
    end

    return object_id
end

local function normalize_insertion_index(insertion_index)
    if insertion_index == nil then
        return nil
    end

    if type(insertion_index) ~= 'number' or insertion_index < 1 then
        return nil, 'insertion_index must be a positive integer when provided'
    end

    if insertion_index % 1 ~= 0 then
        return nil, 'insertion_index must be a positive integer when provided'
    end

    return insertion_index - 1
end

local function batch_update_presentation(presentation_id, requests)
    return gws_helpers.run({
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
end

-- BatchUpdate operation helpers
local function create_slide_operation(presentation_id, args)
    local insertion_index, insertion_index_err =
        normalize_insertion_index(args.insertion_index)
    if insertion_index_err then
        return gws_tool_helpers.tool_error(insertion_index_err)
    end

    local slide_object_id = nil
    if args.slide_object_id ~= nil and args.slide_object_id ~= vim.NIL then
        local slide_object_id_err
        slide_object_id, slide_object_id_err =
            gws_tool_helpers.normalize_required_string_arg(
                args.slide_object_id,
                'slide_object_id',
                { allow_empty = false }
            )
        if not slide_object_id then
            return gws_tool_helpers.tool_error(slide_object_id_err)
        end
    end

    local layout_reference = nil
    if args.layout_reference ~= nil and args.layout_reference ~= vim.NIL then
        local layout_reference_err
        layout_reference, layout_reference_err =
            gws_tool_helpers.normalize_required_string_arg(
                args.layout_reference,
                'layout_reference',
                { allow_empty = false }
            )
        if not layout_reference then
            return gws_tool_helpers.tool_error(layout_reference_err)
        end
    end

    local create_slide = {}
    if slide_object_id then
        create_slide.objectId = slide_object_id
    end
    if insertion_index ~= nil then
        create_slide.insertionIndex = insertion_index
    end
    if layout_reference then
        create_slide.slideLayoutReference = {
            predefinedLayout = layout_reference,
        }
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        {
            createSlide = create_slide,
        },
    })
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Created a slide in Google Slides %s'):format(presentation_id)
    )
end

local function duplicate_slide_operation(presentation_id, args)
    local source_slide_object_id, source_slide_object_id_err =
        resolve_slide_object_id(presentation_id, {
            slide_object_id = args.source_slide_object_id,
            slide_index = args.source_slide_index,
        })
    if not source_slide_object_id then
        return gws_tool_helpers.tool_error(source_slide_object_id_err)
    end

    local object_ids = nil
    if args.new_slide_object_id ~= nil and args.new_slide_object_id ~= vim.NIL then
        local new_slide_object_id, new_slide_object_id_err =
            gws_tool_helpers.normalize_required_string_arg(
                args.new_slide_object_id,
                'new_slide_object_id',
                { allow_empty = false }
            )
        if not new_slide_object_id then
            return gws_tool_helpers.tool_error(new_slide_object_id_err)
        end
        object_ids = {
            [source_slide_object_id] = new_slide_object_id,
        }
    end

    local insertion_index, insertion_index_err =
        normalize_insertion_index(args.insertion_index)
    if insertion_index_err then
        return gws_tool_helpers.tool_error(insertion_index_err)
    end

    local duplicate_object = {
        objectId = source_slide_object_id,
    }
    if object_ids then
        duplicate_object.objectIds = object_ids
    end
    if insertion_index ~= nil then
        duplicate_object.insertionIndex = insertion_index
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        {
            duplicateObject = duplicate_object,
        },
    })
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Duplicated slide %s in Google Slides %s'):format(
            source_slide_object_id,
            presentation_id
        )
    )
end

local function delete_slide_operation(presentation_id, args)
    local slide_object_id, slide_object_id_err =
        resolve_slide_object_id(presentation_id, args)
    if not slide_object_id then
        return gws_tool_helpers.tool_error(slide_object_id_err)
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        {
            deleteObject = {
                objectId = slide_object_id,
            },
        },
    })
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Deleted slide %s from Google Slides %s'):format(
            slide_object_id,
            presentation_id
        )
    )
end

local function replace_all_text_operation(presentation_id, args)
    local match_text, match_text_err =
        gws_tool_helpers.normalize_required_string_arg(args.match_text, 'match_text', {
            empty_error = 'match_text is required for replace_all_text',
        })
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

    local stdout, run_err = batch_update_presentation(presentation_id, {
        {
            replaceAllText = {
                containsText = {
                    text = match_text,
                    matchCase = true,
                },
                replaceText = replace_text,
            },
        },
    })
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Replaced all matches of "%s" in Google Slides %s'):format(
            match_text,
            presentation_id
        )
    )
end

local function raw_batch_update_operation(presentation_id, args)
    local requests, requests_err =
        gws_tool_helpers.normalize_json_array_arg(args.requests_json, {
            invalid_json_error = 'requests_json must be valid JSON',
            empty_error = 'requests_json must be a non-empty JSON array',
        })
    if not requests then
        return gws_tool_helpers.tool_error(requests_err)
    end

    local stdout, run_err = batch_update_presentation(presentation_id, requests)
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Applied raw batchUpdate with %d request(s) to Google Slides %s'):format(
            #requests,
            presentation_id
        )
    )
end

local OPERATIONS = {
    create_slide = create_slide_operation,
    delete_slide = delete_slide_operation,
    duplicate_slide = duplicate_slide_operation,
    replace_all_text = replace_all_text_operation,
    raw_batch_update = raw_batch_update_operation,
}

-- Operation dispatcher
local function write_google_slides(args)
    local presentation_id, id_err = gws_tool_helpers.extract_google_id_arg(
        args.presentation,
        'slides',
        'presentation'
    )
    if not presentation_id then
        return gws_tool_helpers.tool_error(id_err)
    end

    local operation, operation_err =
        gws_tool_helpers.normalize_required_string_arg(args.operation, 'operation')
    if not operation then
        return gws_tool_helpers.tool_error(operation_err)
    end

    local operation_fn = OPERATIONS[operation]
    if not operation_fn then
        return gws_tool_helpers.tool_error('unsupported gslides_write operation')
    end

    return operation_fn(presentation_id, args)
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
                            'create_slide',
                            'delete_slide',
                            'duplicate_slide',
                            'replace_all_text',
                            'raw_batch_update',
                        },
                        description = 'Write op, prefer high-level ops '
                            .. 'before raw_batch_update.',
                    },
                    insertion_index = {
                        type = 'integer',
                        description = '1-based insert position.',
                    },
                    layout_reference = {
                        type = 'string',
                        description = 'Layout for create_slide.',
                    },
                    source_slide_object_id = {
                        type = 'string',
                        description = 'Slide ID for duplicate_slide.',
                    },
                    source_slide_index = {
                        type = 'integer',
                        description = '1-based slide index to duplicate.',
                    },
                    new_slide_object_id = {
                        type = 'string',
                        description = 'Optional new slide object ID.',
                    },
                    match_text = {
                        type = 'string',
                        description = 'Text to match.',
                    },
                    replace_text = {
                        type = 'string',
                        description = 'Replacement text.',
                    },
                    slide_object_id = {
                        type = 'string',
                        description = 'Slide object ID to delete.',
                    },
                    slide_index = {
                        type = 'integer',
                        description = '1-based slide index to delete.',
                    },
                    requests_json = {
                        type = 'string',
                        description = 'Fallback raw batchUpdate JSON.',
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
            if self.args.operation == 'create_slide' then
                return ('Create a slide in Google Slides `%s`?'):format(
                    self.args.presentation
                )
            end
            if self.args.operation == 'duplicate_slide' then
                return ('Duplicate a slide in Google Slides `%s`?'):format(
                    self.args.presentation
                )
            end

            if self.args.operation == 'delete_slide' then
                local target = self.args.slide_object_id
                if not target and type(self.args.slide_index) == 'number' then
                    target = ('slide #%d'):format(self.args.slide_index)
                end
                target = gws_helpers.fallback_text(target, '(no slide target provided)')

                return ('Delete `%s` from Google Slides `%s`?'):format(
                    target,
                    self.args.presentation
                )
            end

            local match_text = gws_helpers.fallback_text(
                self.args.match_text,
                '(no match_text provided)'
            )

            return ('Write to Google Slides `%s` using `%s` with match `%s`?'):format(
                self.args.presentation,
                self.args.operation,
                match_text
            )
        end,
        success = function(self, stdout, meta)
            gws_tool_helpers.add_tool_success(
                meta.tools.chat,
                self,
                stdout,
                'Google Slides write succeeded'
            )
        end,
        error = function(self, stderr, meta)
            gws_tool_helpers.add_tool_error(
                meta.tools.chat,
                self,
                stderr,
                'Google Slides write failed'
            )
        end,
    },
}

return M
