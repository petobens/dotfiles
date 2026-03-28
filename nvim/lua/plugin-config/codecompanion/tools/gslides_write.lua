-- luacheck:ignore 631
local gslides = require('plugin-config.codecompanion.slash_commands.gslides')
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')
local gws_tool_helpers = require('plugin-config.codecompanion.tools.gworkspace_helpers')

-- Constants
local STYLE_BOOL_FIELDS = {
    bold = 'bold',
    italic = 'italic',
    underline = 'underline',
    strikethrough = 'strikethrough',
    small_caps = 'smallCaps',
    smallCaps = 'smallCaps',
}

local STYLE_PROMPT_FIELDS = {
    'bold',
    'italic',
    'underline',
    'strikethrough',
    'small_caps',
    'foreground_color',
    'font_family',
    'font_size_pt',
    'link_url',
}

local OPERATION_ENUM = {
    'create_slide',
    'delete_slide',
    'duplicate_slide',
    'replace_all_text',
    'raw_batch_update',
    'update_text_style',
}

-- Validate
local function normalize_int(value, name, opts)
    opts = opts or {}

    if value == nil or value == vim.NIL then
        return nil
    end
    if type(value) ~= 'number' or value % 1 ~= 0 then
        return nil, ('%s must be an integer'):format(name)
    end
    if opts.allow_zero then
        if value < 0 then
            return nil, ('%s must be zero or a positive integer'):format(name)
        end
    elseif value < 1 then
        return nil, ('%s must be a positive integer'):format(name)
    end

    return value
end

local function normalize_bool(value, name, default)
    if value == nil or value == vim.NIL then
        return default
    end
    if type(value) ~= 'boolean' then
        return nil, ('%s must be a boolean'):format(name)
    end
    return value
end

local function normalize_number(value, name)
    if value == nil or value == vim.NIL then
        return nil
    end
    if type(value) ~= 'number' then
        return nil, ('%s must be a number'):format(name)
    end
    return value
end

local function normalize_required_string(value, name, opts)
    return gws_tool_helpers.normalize_required_string_arg(value, name, opts)
end

local function has_value(value)
    return value ~= nil and value ~= vim.NIL
end

local function normalize_hex_color(value, name)
    local text, text_err = normalize_required_string(value, name, { allow_empty = false })
    if not text then
        return nil, text_err
    end

    local hex = text:match('^#?(%x%x%x%x%x%x)$')
    if not hex then
        return nil, ('%s must be a hex color like #RRGGBB'):format(name)
    end

    local function channel(start_idx)
        return tonumber(hex:sub(start_idx, start_idx + 1), 16) / 255
    end

    return {
        opaqueColor = {
            rgbColor = {
                red = channel(1),
                green = channel(3),
                blue = channel(5),
            },
        },
    }
end

local function normalize_requests_payload(value)
    local decoded, decode_err = gws_tool_helpers.normalize_json_arg(value, {
        invalid_json_error = 'requests_json must be valid JSON',
    })
    if decoded == nil then
        return nil, decode_err
    end

    if vim.islist(decoded) then
        if vim.tbl_isempty(decoded) then
            return nil, 'requests_json must be a non-empty JSON array'
        end
        return decoded
    end

    if type(decoded) == 'table' and vim.islist(decoded.requests) then
        if vim.tbl_isempty(decoded.requests) then
            return nil, 'requests_json.requests must be a non-empty JSON array'
        end
        return decoded.requests
    end

    return nil,
        'requests_json must be either a JSON array or an object with a non-empty requests array'
end

-- API
local function batch_update_presentation(presentation_id, requests)
    return gws_helpers.run({
        'gws',
        'slides',
        'presentations',
        'batchUpdate',
        '--params',
        vim.json.encode({ presentationId = presentation_id }),
        '--json',
        vim.json.encode({ requests = requests }),
    })
end

local function fetch_presentation(presentation_id)
    return gslides.fetch_google_slides(presentation_id)
end

local function resolve_slide_object_id(presentation_id, args)
    local slide_object_id, slide_object_id_err = normalize_required_string(
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

    local slide_index, slide_index_err = normalize_int(args.slide_index, 'slide_index')
    if slide_index_err then
        return nil, slide_index_err
    end
    if not slide_index then
        return nil, 'slide_object_id or slide_index is required'
    end

    local presentation, fetch_err = fetch_presentation(presentation_id)
    if not presentation then
        return nil, fetch_err
    end

    local slide = (presentation.slides or {})[slide_index]
    local object_id = slide and gws_helpers.fallback_text(slide.objectId, nil)
    if not object_id then
        return nil, ('Slide index %d was not found'):format(slide_index)
    end

    return object_id
end

local function find_slide(presentation, slide_object_id)
    return vim.iter(presentation.slides or {}):find(function(slide)
        return slide.objectId == slide_object_id
    end)
end

-- Text matching
local function normalize_for_fuzzy_search(text)
    local normalized_parts = {}
    local normalized_to_original = {}
    local last_was_space = false

    for i = 1, #text do
        local char = text:sub(i, i)
        if char:match('%s') then
            if not last_was_space then
                normalized_parts[#normalized_parts + 1] = ' '
                normalized_to_original[#normalized_to_original + 1] = i
                last_was_space = true
            end
        else
            normalized_parts[#normalized_parts + 1] = char:lower()
            normalized_to_original[#normalized_to_original + 1] = i
            last_was_space = false
        end
    end

    return table.concat(normalized_parts, ''), normalized_to_original
end

local function find_occurrence_range(haystack, needle, occurrence_index)
    local seen, init = 0, 1
    while true do
        local start_pos, end_pos = haystack:find(needle, init, true)
        if not start_pos then
            return nil
        end

        seen = seen + 1
        if seen == occurrence_index then
            return start_pos, end_pos
        end

        init = start_pos + 1
    end
end

-- Shapes
local function has_text_shape(element)
    return vim.tbl_get(element, 'shape', 'text', 'textElements') ~= nil
end

local function slide_scope_from_args(presentation_id, presentation, args)
    local slides = presentation.slides or {}

    if has_value(args.slide_object_id) or has_value(args.slide_index) then
        local slide_object_id, slide_object_id_err =
            resolve_slide_object_id(presentation_id, args)
        if not slide_object_id then
            return nil, slide_object_id_err
        end

        local slide = find_slide(presentation, slide_object_id)
        if not slide then
            return nil, ('Slide %s was not found'):format(slide_object_id)
        end

        return { slide }
    end

    return slides
end

local function build_shape_text_segments(element)
    local parts = {}
    local segments = {}

    for _, text_element in
        ipairs(vim.tbl_get(element, 'shape', 'text', 'textElements') or {})
    do
        local content = vim.tbl_get(text_element, 'textRun', 'content')
        local start_index = text_element.startIndex
        local end_index = text_element.endIndex

        if
            type(content) == 'string'
            and type(start_index) == 'number'
            and type(end_index) == 'number'
            and end_index >= start_index
        then
            parts[#parts + 1] = content
            segments[#segments + 1] = {
                text = content,
                start_index = start_index,
            }
        end
    end

    return table.concat(parts, ''), segments
end

local function shape_text_contains_match(element, match_text)
    if type(match_text) ~= 'string' or match_text == '' then
        return false
    end

    local full_text = build_shape_text_segments(element)
    if full_text:find(match_text, 1, true) ~= nil then
        return true
    end

    local normalized_full_text = normalize_for_fuzzy_search(full_text)
    local normalized_match_text = normalize_for_fuzzy_search(match_text)
    return normalized_full_text:find(normalized_match_text, 1, true) ~= nil
end

local function collect_matching_text_shapes(slides, match_text)
    local matches = {}

    for _, slide in ipairs(slides) do
        for _, element in ipairs(slide.pageElements or {}) do
            if
                has_text_shape(element) and shape_text_contains_match(element, match_text)
            then
                matches[#matches + 1] = element
            end
        end
    end

    return matches
end

local function find_text_shape(presentation_id, presentation, args)
    local slides, slides_err = slide_scope_from_args(presentation_id, presentation, args)
    if not slides then
        return nil, slides_err
    end

    local page_element_object_id = gws_tool_helpers.normalize_required_string_arg(
        args.page_element_object_id,
        'page_element_object_id',
        { allow_empty = true }
    )
    if page_element_object_id == nil then
        return nil, 'page_element_object_id must be a string'
    end

    if page_element_object_id ~= '' then
        for _, slide in ipairs(slides) do
            for _, element in ipairs(slide.pageElements or {}) do
                if element.objectId == page_element_object_id then
                    if not has_text_shape(element) then
                        return nil,
                            ('Page element %s is not a text shape'):format(
                                page_element_object_id
                            )
                    end
                    return element
                end
            end
        end

        return nil, ('Page element %s was not found'):format(page_element_object_id)
    end

    local match_text =
        gws_tool_helpers.normalize_required_string_arg(args.match_text, 'match_text', {
            empty_error = 'page_element_object_id or match_text is required for update_text_style',
        })
    if not match_text then
        return nil,
            'page_element_object_id or match_text is required for update_text_style'
    end

    local matches = collect_matching_text_shapes(slides, match_text)
    if #matches == 1 then
        return matches[1]
    end
    if #matches > 1 then
        local ids = vim.iter(matches)
            :map(function(element)
                return element.objectId or 'unknown'
            end)
            :join(', ')
        return nil,
            ('match_text matched multiple text shapes, provide page_element_object_id explicitly: %s'):format(
                ids
            )
    end

    return nil,
        ('Could not find a text shape containing "%s" in the requested slide scope'):format(
            match_text
        )
end

-- Text ranges
local function range_from_match(element, args)
    local match_text, match_text_err =
        normalize_required_string(args.match_text, 'match_text', {
            empty_error = 'match_text is required when text_range_start/text_range_end are not provided',
        })
    if not match_text then
        return nil, match_text_err
    end

    local occurrence_index, occurrence_index_err =
        normalize_int(args.occurrence_index, 'occurrence_index')
    if occurrence_index_err then
        return nil, occurrence_index_err
    end
    occurrence_index = occurrence_index or 1

    local full_text, segments = build_shape_text_segments(element)
    if full_text == '' then
        return nil, ('Page element %s contains no text runs'):format(element.objectId)
    end

    local function map_range(start_pos, end_pos)
        local start_index, end_index

        for _, segment in ipairs(segments) do
            local text_start = segment.start_index + 1
            local text_end = text_start + #segment.text - 1

            if not start_index and start_pos >= text_start and start_pos <= text_end then
                start_index = segment.start_index + (start_pos - text_start)
            end
            if end_pos >= text_start and end_pos <= text_end then
                end_index = segment.start_index + (end_pos - text_start + 1)
                break
            end
        end

        if start_index and end_index then
            return {
                type = 'FIXED_RANGE',
                startIndex = start_index,
                endIndex = end_index,
            }
        end

        return nil
    end

    local exact_start, exact_end =
        find_occurrence_range(full_text, match_text, occurrence_index)
    if exact_start and exact_end then
        local exact_range = map_range(exact_start, exact_end)
        if exact_range then
            return exact_range
        end

        return nil,
            ('Could not map match_text to a Slides text range in page element %s'):format(
                element.objectId
            )
    end

    local normalized_full_text, normalized_to_original =
        normalize_for_fuzzy_search(full_text)
    local normalized_match_text = normalize_for_fuzzy_search(match_text)
    local fuzzy_start, fuzzy_end = find_occurrence_range(
        normalized_full_text,
        normalized_match_text,
        occurrence_index
    )

    if fuzzy_start and fuzzy_end then
        local original_start = normalized_to_original[fuzzy_start]
        local original_end = normalized_to_original[fuzzy_end]
        if original_start and original_end then
            local fuzzy_range = map_range(original_start, original_end)
            if fuzzy_range then
                return fuzzy_range
            end
        end

        return nil,
            ('Could not map fuzzy match_text to a Slides text range in page element %s'):format(
                element.objectId
            )
    end

    return nil,
        ('Could not find occurrence %d of "%s" in page element %s'):format(
            occurrence_index,
            match_text,
            element.objectId
        )
end

local function resolve_text_range(element, args)
    local start_index, start_index_err =
        normalize_int(args.text_range_start, 'text_range_start', { allow_zero = true })
    if start_index_err then
        return nil, start_index_err
    end

    local end_index, end_index_err =
        normalize_int(args.text_range_end, 'text_range_end', { allow_zero = true })
    if end_index_err then
        return nil, end_index_err
    end

    if start_index ~= nil or end_index ~= nil then
        if start_index == nil or end_index == nil then
            return nil, 'text_range_start and text_range_end must be provided together'
        end
        if end_index <= start_index then
            return nil, 'text_range_end must be greater than text_range_start'
        end

        return {
            type = 'FIXED_RANGE',
            startIndex = start_index,
            endIndex = end_index,
        }
    end

    if not has_value(args.match_text) or args.match_text == '' then
        return { type = 'ALL' }
    end

    return range_from_match(element, args)
end

-- Text styles
local function build_text_style(args)
    local style = {}
    local fields = {}

    local function add(field, value)
        style[field] = value
        fields[#fields + 1] = field
    end

    for key, field in vim.spairs(STYLE_BOOL_FIELDS) do
        if has_value(args[key]) and style[field] == nil then
            local value, value_err = normalize_bool(args[key], key)
            if value == nil then
                return nil, nil, value_err
            end
            add(field, value)
        end
    end

    if has_value(args.foreground_color) then
        local color, color_err =
            normalize_hex_color(args.foreground_color, 'foreground_color')
        if not color then
            return nil, nil, color_err
        end
        add('foregroundColor', color)
    end

    if has_value(args.font_family) then
        local font_family, font_family_err = normalize_required_string(
            args.font_family,
            'font_family',
            { allow_empty = false }
        )
        if not font_family then
            return nil, nil, font_family_err
        end
        add('fontFamily', font_family)
    end

    if has_value(args.font_size_pt) then
        local font_size_pt, font_size_pt_err =
            normalize_number(args.font_size_pt, 'font_size_pt')
        if font_size_pt == nil then
            return nil, nil, font_size_pt_err
        end
        if font_size_pt <= 0 then
            return nil, nil, 'font_size_pt must be greater than 0'
        end
        add('fontSize', { magnitude = font_size_pt, unit = 'PT' })
    end

    if has_value(args.link_url) then
        local link_url, link_url_err =
            normalize_required_string(args.link_url, 'link_url', {
                allow_empty = false,
            })
        if not link_url then
            return nil, nil, link_url_err
        end
        add('link', { url = link_url })
    end

    if vim.tbl_isempty(style) then
        return nil,
            nil,
            'At least one text style field is required: bold, italic, underline, strikethrough, small_caps, foreground_color, font_family, font_size_pt, or link_url'
    end

    return style, fields
end

-- Ops
local function create_slide_operation(presentation_id, args)
    local insertion_index, insertion_index_err =
        normalize_int(args.insertion_index, 'insertion_index')
    if insertion_index_err then
        return gws_tool_helpers.tool_error(
            'insertion_index must be a positive integer when provided'
        )
    end

    local slide_object_id = nil
    if args.slide_object_id ~= nil and args.slide_object_id ~= vim.NIL then
        local slide_object_id_err
        slide_object_id, slide_object_id_err = normalize_required_string(
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
        layout_reference, layout_reference_err = normalize_required_string(
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
    if insertion_index then
        create_slide.insertionIndex = insertion_index - 1
    end
    if layout_reference then
        create_slide.slideLayoutReference = { predefinedLayout = layout_reference }
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        { createSlide = create_slide },
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

    if args.insertion_index ~= nil and args.insertion_index ~= vim.NIL then
        return gws_tool_helpers.tool_error(
            'duplicate_slide does not support insertion_index; duplicate the slide first, then reorder it with raw_batch_update if needed'
        )
    end

    local object_ids = nil
    if args.new_slide_object_id ~= nil and args.new_slide_object_id ~= vim.NIL then
        local new_slide_object_id, new_slide_object_id_err = normalize_required_string(
            args.new_slide_object_id,
            'new_slide_object_id',
            { allow_empty = false }
        )
        if not new_slide_object_id then
            return gws_tool_helpers.tool_error(new_slide_object_id_err)
        end
        object_ids = { [source_slide_object_id] = new_slide_object_id }
    end

    local duplicate_object = { objectId = source_slide_object_id }
    if object_ids then
        duplicate_object.objectIds = object_ids
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        { duplicateObject = duplicate_object },
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
        { deleteObject = { objectId = slide_object_id } },
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
        normalize_required_string(args.match_text, 'match_text', {
            empty_error = 'match_text is required for replace_all_text',
        })
    if not match_text then
        return gws_tool_helpers.tool_error(match_text_err)
    end

    local replace_text, replace_text_err = normalize_required_string(
        args.replace_text,
        'replace_text',
        { allow_empty = true }
    )
    if replace_text == nil then
        return gws_tool_helpers.tool_error(replace_text_err)
    end

    local replace_all_text = {
        containsText = { text = match_text, matchCase = true },
        replaceText = replace_text,
    }

    if args.slide_object_id ~= nil or args.slide_index ~= nil then
        local slide_object_id, slide_object_id_err =
            resolve_slide_object_id(presentation_id, args)
        if not slide_object_id then
            return gws_tool_helpers.tool_error(slide_object_id_err)
        end
        replace_all_text.pageObjectIds = { slide_object_id }
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        {
            replaceAllText = replace_all_text,
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

local function update_text_style_operation(presentation_id, args)
    local presentation, fetch_err = fetch_presentation(presentation_id)
    if not presentation then
        return gws_tool_helpers.tool_error(fetch_err)
    end

    local element, element_err = find_text_shape(presentation_id, presentation, args)
    if not element then
        return gws_tool_helpers.tool_error(element_err)
    end

    local text_range, text_range_err = resolve_text_range(element, args)
    if not text_range then
        return gws_tool_helpers.tool_error(text_range_err)
    end

    local style, fields, style_err = build_text_style(args)
    if not style then
        return gws_tool_helpers.tool_error(style_err)
    end

    local stdout, run_err = batch_update_presentation(presentation_id, {
        {
            updateTextStyle = {
                objectId = element.objectId,
                textRange = text_range,
                style = style,
                fields = table.concat(fields, ','),
            },
        },
    })
    if not stdout then
        return gws_tool_helpers.tool_error(run_err)
    end

    return gws_tool_helpers.tool_success(
        ('Updated text style (%s) in page element %s in Google Slides %s'):format(
            table.concat(fields, ', '),
            element.objectId,
            presentation_id
        )
    )
end

local function raw_batch_update_operation(presentation_id, args)
    local requests, requests_err = normalize_requests_payload(args.requests_json)
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
    update_text_style = update_text_style_operation,
}

-- Prompt builders
local function prompt_text_style(args)
    local style_parts = vim.iter(STYLE_PROMPT_FIELDS)
        :filter(function(key)
            return has_value(args[key])
        end)
        :map(function(key)
            return ('%s=%s'):format(key, tostring(args[key]))
        end)
        :totable()

    return ('Update text style (%s) in `%s` on Google Slides `%s` for `%s`?'):format(
        table.concat(style_parts, ', '),
        gws_helpers.fallback_text(
            args.page_element_object_id,
            '(no page element provided)'
        ),
        args.presentation,
        gws_helpers.fallback_text(args.match_text, '(full text range)')
    )
end

local function build_prompt(args)
    if args.operation == 'raw_batch_update' then
        return ('Apply raw batchUpdate to Google Slides `%s`?'):format(args.presentation)
    end
    if args.operation == 'create_slide' then
        return ('Create a slide in Google Slides `%s`?'):format(args.presentation)
    end
    if args.operation == 'duplicate_slide' then
        return ('Duplicate a slide in Google Slides `%s`?'):format(args.presentation)
    end
    if args.operation == 'delete_slide' then
        local target = args.slide_object_id
        if not target and type(args.slide_index) == 'number' then
            target = ('slide #%d'):format(args.slide_index)
        end
        return ('Delete `%s` from Google Slides `%s`?'):format(
            gws_helpers.fallback_text(target, '(no slide target provided)'),
            args.presentation
        )
    end
    if args.operation == 'update_text_style' then
        return prompt_text_style(args)
    end

    return ('Write to Google Slides `%s` using `%s` with match `%s`?'):format(
        args.presentation,
        args.operation,
        gws_helpers.fallback_text(args.match_text, '(no match_text provided)')
    )
end

local SCHEMA_PROPERTIES = {
    presentation = {
        type = 'string',
        description = 'Google Slides URL or presentation ID',
    },
    operation = {
        type = 'string',
        enum = OPERATION_ENUM,
        description = 'Write op, prefer high-level ops before raw_batch_update.',
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
    page_element_object_id = {
        type = 'string',
        description = 'Text shape object ID for update_text_style.',
    },
    match_text = {
        type = 'string',
        description = 'Text to match. For update_text_style, matching is scoped to page_element_object_id. If omitted, update_text_style styles the full text range.',
    },
    occurrence_index = {
        type = 'integer',
        description = '1-based match occurrence for update_text_style, defaults to 1.',
    },
    replace_text = {
        type = 'string',
        description = 'Replacement text. For replace_all_text, can be scoped with slide_object_id or slide_index.',
    },
    text_range_start = {
        type = 'integer',
        description = 'Zero-based Slides start index for update_text_style.',
    },
    text_range_end = {
        type = 'integer',
        description = 'Zero-based Slides end index for update_text_style, exclusive.',
    },
    bold = {
        type = 'boolean',
        description = 'Set bold for update_text_style.',
    },
    italic = {
        type = 'boolean',
        description = 'Set italic for update_text_style.',
    },
    underline = {
        type = 'boolean',
        description = 'Set underline for update_text_style.',
    },
    strikethrough = {
        type = 'boolean',
        description = 'Set strikethrough for update_text_style.',
    },
    small_caps = {
        type = 'boolean',
        description = 'Set smallCaps for update_text_style.',
    },
    foreground_color = {
        type = 'string',
        description = 'Hex text color like #RRGGBB for update_text_style.',
    },
    font_family = {
        type = 'string',
        description = 'Font family for update_text_style.',
    },
    font_size_pt = {
        type = 'number',
        description = 'Font size in points for update_text_style.',
    },
    link_url = {
        type = 'string',
        description = 'Link URL for update_text_style.',
    },
    slide_object_id = {
        type = 'string',
        description = 'Slide object ID to delete or scope update_text_style.',
    },
    slide_index = {
        type = 'integer',
        description = '1-based slide index to delete or scope update_text_style.',
    },
    requests_json = {
        type = 'string',
        description = 'Fallback raw batchUpdate JSON, accepts either a JSON array of requests or an object with a requests array.',
    },
}

-- Dispatch
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
        normalize_required_string(args.operation, 'operation')
    if not operation then
        return gws_tool_helpers.tool_error(operation_err)
    end

    local operation_fn = OPERATIONS[operation]
    if not operation_fn then
        return gws_tool_helpers.tool_error('unsupported gslides_write operation')
    end

    return operation_fn(presentation_id, args)
end

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
                properties = SCHEMA_PROPERTIES,
                required = { 'presentation', 'operation' },
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
