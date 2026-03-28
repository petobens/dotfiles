-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')

local M = {}

-- Constants
local TEXT_STYLE_FLAGS = {
    'bold',
    'italic',
    'underline',
    'strikethrough',
    'smallCaps',
}

-- API
local function fetch_slides(presentation_id)
    local stdout, run_err = gws_helpers.run({
        'gws',
        'slides',
        'presentations',
        'get',
        '--params',
        vim.json.encode({ presentationId = presentation_id }),
    })
    if not stdout then
        return nil, run_err
    end

    return gws_helpers.decode_json(stdout, 'the Google Slides presentation')
end

-- Format
local function safe_tbl_get(tbl, ...)
    if type(tbl) ~= 'table' then
        return nil
    end

    local value = tbl
    for i = 1, select('#', ...) do
        if type(value) ~= 'table' then
            return nil
        end

        value = value[select(i, ...)]
        if value == nil then
            return nil
        end
    end

    return value
end

local function format_dimension(dimension)
    local magnitude = safe_tbl_get(dimension, 'magnitude')
    if type(magnitude) ~= 'number' then
        return nil
    end

    local unit = safe_tbl_get(dimension, 'unit')
    return unit and ('%s %s'):format(magnitude, unit) or tostring(magnitude)
end

local function summarize_element(element, kind, extra)
    local suffixes = {}
    if extra and extra ~= '' then
        suffixes[#suffixes + 1] = extra
    end

    local width = format_dimension(safe_tbl_get(element, 'size', 'width'))
    local height = format_dimension(safe_tbl_get(element, 'size', 'height'))
    if width and height then
        suffixes[#suffixes + 1] = ('size=%s x %s'):format(width, height)
    end

    local transform = element.transform
    if type(transform) == 'table' then
        local unit = transform.unit or ''
        suffixes[#suffixes + 1] = ('pos=(%s, %s)%s'):format(
            transform.translateX or 0,
            transform.translateY or 0,
            unit ~= '' and (' ' .. unit) or ''
        )
    end

    local summary = ('[%s]'):format(kind)
    if not vim.tbl_isempty(suffixes) then
        summary = summary .. ' ' .. table.concat(suffixes, ', ')
    end
    return summary
end

local function summarize_style_flags(style)
    return vim.iter(TEXT_STYLE_FLAGS)
        :filter(function(key)
            return style[key]
        end)
        :totable()
end

-- Text
local function text_elements(element)
    return safe_tbl_get(element, 'shape', 'text', 'textElements') or {}
end

local function extract_shape_text(element)
    local parts = {}

    for _, text_element in ipairs(text_elements(element)) do
        local content = safe_tbl_get(text_element, 'textRun', 'content')
        if type(content) == 'string' then
            parts[#parts + 1] = content
        end
    end

    return gws_helpers.normalize_text(table.concat(parts, ''))
end

local function shape_summary_line(element)
    local text = extract_shape_text(element)
    local object_id = gws_helpers.fallback_text(element.objectId, 'unknown')

    if text ~= '' then
        return ('[text objectId=%s] %s'):format(object_id, text)
    end

    return nil
end

local function collect_slide_page_elements(parts, page_elements, opts)
    opts = opts or {}

    if type(page_elements) ~= 'table' then
        return
    end

    for _, element in ipairs(page_elements) do
        local text = extract_shape_text(element)
        if text ~= '' then
            if opts.include_text_object_ids then
                gws_helpers.append_text(parts, shape_summary_line(element) .. '\n')
            else
                gws_helpers.append_text(parts, text)
            end
        elseif element.image then
            gws_helpers.append_text(parts, summarize_element(element, 'image') .. '\n')
        elseif element.table then
            gws_helpers.append_text(
                parts,
                summarize_element(
                    element,
                    'table',
                    ('rows=%s cols=%s'):format(
                        safe_tbl_get(element, 'table', 'rows') or '?',
                        safe_tbl_get(element, 'table', 'columns') or '?'
                    )
                ) .. '\n'
            )
        elseif element.video then
            gws_helpers.append_text(parts, summarize_element(element, 'video') .. '\n')
        elseif element.sheetsChart then
            gws_helpers.append_text(parts, summarize_element(element, 'chart') .. '\n')
        elseif element.shape then
            gws_helpers.append_text(
                parts,
                summarize_element(
                    element,
                    'shape',
                    safe_tbl_get(element, 'shape', 'shapeType')
                ) .. '\n'
            )
        end
    end
end

local function extract_slide_text(slide, opts)
    local parts = {}
    collect_slide_page_elements(parts, slide.pageElements, opts)
    return gws_helpers.normalize_text(table.concat(parts, ''))
end

local function slide_appears_blank(slide)
    return extract_slide_text(slide) == ''
end

-- Meta
local function summarize_text_runs(element)
    local lines = {}

    for _, text_element in ipairs(text_elements(element)) do
        local text_run = text_element.textRun
        if text_run and type(text_run.content) == 'string' then
            local style_parts = summarize_style_flags(text_run.style or {})
            local suffix = #style_parts > 0
                    and (' style=%s'):format(table.concat(style_parts, ','))
                or ''

            lines[#lines + 1] = ('    - [%s,%s): %s%s'):format(
                tostring(text_element.startIndex),
                tostring(text_element.endIndex),
                text_run.content:gsub('\n', '\\n'),
                suffix
            )
        end
    end

    return lines
end

local function summarize_page_element(element, element_index)
    local kind, extra = 'unknown', nil

    if element.image then
        kind = 'image'
    elseif element.table then
        kind = 'table'
        extra = ('rows=%s cols=%s'):format(
            safe_tbl_get(element, 'table', 'rows') or '?',
            safe_tbl_get(element, 'table', 'columns') or '?'
        )
    elseif element.video then
        kind = 'video'
    elseif element.sheetsChart then
        kind = 'chart'
    elseif element.shape then
        kind = 'shape'
        extra = safe_tbl_get(element, 'shape', 'shapeType')
    end

    local lines = {
        ('  - Element %d (objectId: %s) %s'):format(
            element_index,
            gws_helpers.fallback_text(element.objectId, 'unknown'),
            summarize_element(element, kind, extra)
        ),
    }

    if element.shape then
        local shape_text = extract_shape_text(element)
        if shape_text ~= '' then
            lines[#lines + 1] = ('    text: %s'):format(shape_text:gsub('\n', '\\n'))
        end

        local text_run_lines = summarize_text_runs(element)
        if #text_run_lines > 0 then
            lines[#lines + 1] = '    text runs:'
            vim.list_extend(lines, text_run_lines)
        end
    end

    return lines
end

local function summarize_slide_page_elements(page_elements)
    local lines = {}
    if type(page_elements) ~= 'table' then
        return lines
    end

    for index, element in ipairs(page_elements) do
        vim.list_extend(lines, summarize_page_element(element, index))
    end

    return lines
end

-- Read
local function slides_to_text(presentation)
    local lines = {}

    for i, slide in ipairs(presentation.slides or {}) do
        lines[#lines + 1] = ('Slide %d (objectId: %s%s)'):format(
            i,
            gws_helpers.fallback_text(slide.objectId, 'unknown'),
            slide_appears_blank(slide) and ', appears blank' or ''
        )

        local text = extract_slide_text(slide, { include_text_object_ids = true })
        if text ~= '' then
            lines[#lines + 1] = text
        end
        lines[#lines + 1] = ''
    end

    local text = gws_helpers.normalize_text(table.concat(lines, '\n'))
    if text == '' then
        return nil,
            'The Google Slides presentation appears to be empty or contains no extractable text'
    end

    return text
end

local function summarize_slides(presentation, presentation_id)
    local slides = presentation.slides or {}
    local lines = {
        ('Title: %s'):format(
            gws_helpers.fallback_text(presentation.title, 'Untitled presentation')
        ),
        ('Slides: %d'):format(#slides),
    }

    for i, slide in ipairs(slides) do
        local page_elements = type(slide.pageElements) == 'table' and slide.pageElements
            or {}
        local slide_properties = type(slide.slideProperties) == 'table'
                and slide.slideProperties
            or nil
        local has_notes = slide_properties and slide_properties.notesPage ~= nil

        lines[#lines + 1] = ('- Slide %d (objectId: %s): objects=%d, notes=%s, blank=%s'):format(
            i,
            gws_helpers.fallback_text(slide.objectId, 'unknown'),
            #page_elements,
            has_notes and 'yes' or 'no',
            slide_appears_blank(slide) and 'yes' or 'no'
        )
        vim.list_extend(lines, summarize_slide_page_elements(page_elements))
    end

    return {
        id = presentation_id,
        title = gws_helpers.fallback_text(presentation.title, 'Untitled presentation'),
        text = gws_helpers.normalize_text(table.concat(lines, '\n')),
    }
end

local function read_slides(input)
    local presentation_id, id_err = gws_helpers.extract_google_id(input, 'slides')
    if not presentation_id then
        return nil, id_err
    end

    local presentation, fetch_err = fetch_slides(presentation_id)
    if not presentation then
        return nil, fetch_err
    end

    local text, text_err = slides_to_text(presentation)
    if not text then
        return nil, text_err
    end

    return {
        id = presentation_id,
        title = gws_helpers.fallback_text(presentation.title, 'Untitled presentation'),
        text = text,
    }
end

local function read_slides_metadata(input)
    local presentation_id, id_err = gws_helpers.extract_google_id(input, 'slides')
    if not presentation_id then
        return nil, id_err
    end

    local presentation, fetch_err = fetch_slides(presentation_id)
    if not presentation then
        return nil, fetch_err
    end

    local ok, result = pcall(summarize_slides, presentation, presentation_id)
    if not ok then
        return nil, ('Failed to inspect Google Slides metadata: %s'):format(result)
    end

    return result
end

-- Exports
M.fetch_slides = fetch_slides
M.read_slides = read_slides
M.read_slides_metadata = read_slides_metadata

-- Command
function M.gslides_read(chat)
    vim.ui.input({ prompt = 'Google Slides URL or ID: ' }, function(input)
        if not input or gws_helpers.is_blank(input) then
            return
        end

        local slides, err = read_slides(input)
        if not slides then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        gws_helpers.add_context(chat, 'Slides presentation', slides, 'gslides')
    end)
end

return M
