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

local function round_number(value, digits)
    if type(value) ~= 'number' then
        return nil
    end

    local factor = 10 ^ (digits or 2)
    return math.floor(value * factor + 0.5) / factor
end

local function format_percent(value)
    local rounded = round_number(value, 1)
    return rounded and ('%s%%'):format(rounded) or nil
end

-- Shapes
local function summarize_transform(transform)
    if type(transform) ~= 'table' then
        return nil
    end

    local parts = {}
    local unit = transform.unit or ''
    parts[#parts + 1] = ('pos=(%s, %s)%s'):format(
        transform.translateX or 0,
        transform.translateY or 0,
        unit ~= '' and (' ' .. unit) or ''
    )

    local scale_x = transform.scaleX
    local scale_y = transform.scaleY
    if type(scale_x) == 'number' or type(scale_y) == 'number' then
        parts[#parts + 1] = ('scale=(%s, %s)'):format(
            round_number(scale_x or 1, 3),
            round_number(scale_y or 1, 3)
        )
    end

    local shear_x = transform.shearX
    local shear_y = transform.shearY
    if type(shear_x) == 'number' or type(shear_y) == 'number' then
        parts[#parts + 1] = ('shear=(%s, %s)'):format(
            round_number(shear_x or 0, 3),
            round_number(shear_y or 0, 3)
        )
    end

    return table.concat(parts, ', ')
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

    local transform_summary = summarize_transform(element.transform)
    if transform_summary then
        suffixes[#suffixes + 1] = transform_summary
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

local function extract_raw_shape_text(element)
    local parts = {}

    for _, text_element in ipairs(text_elements(element)) do
        local content = safe_tbl_get(text_element, 'textRun', 'content')
        if type(content) == 'string' then
            parts[#parts + 1] = content
        end
    end

    return table.concat(parts, '')
end

local function extract_shape_text(element)
    return gws_helpers.normalize_text(extract_raw_shape_text(element))
end

local function shape_summary_line(element)
    local text = extract_shape_text(element)
    local object_id = gws_helpers.fallback_text(element.objectId, 'unknown')

    if text ~= '' then
        return ('[text objectId=%s] %s'):format(object_id, text)
    end

    return nil
end

-- Meta
local function summarize_text_style(style)
    if type(style) ~= 'table' then
        return {}
    end

    local parts = summarize_style_flags(style)

    local font_family = safe_tbl_get(style, 'weightedFontFamily', 'fontFamily')
        or style.fontFamily
    if type(font_family) == 'string' and font_family ~= '' then
        parts[#parts + 1] = ('font=%s'):format(font_family)
    end

    local font_size = format_dimension(style.fontSize)
    if font_size then
        parts[#parts + 1] = ('size=%s'):format(font_size)
    end

    local foreground = safe_tbl_get(style, 'foregroundColor', 'opaqueColor', 'rgbColor')
    if type(foreground) == 'table' then
        parts[#parts + 1] = ('color=(%.3f,%.3f,%.3f)'):format(
            foreground.red or 0,
            foreground.green or 0,
            foreground.blue or 0
        )
    end

    return parts
end

local function summarize_paragraph_style(paragraph_style, bullet)
    local parts = {}

    local alignment = paragraph_style and paragraph_style.alignment or nil
    if type(alignment) == 'string' and alignment ~= '' then
        parts[#parts + 1] = ('align=%s'):format(alignment)
    end

    local spacing_mode = paragraph_style and paragraph_style.spacingMode or nil
    if type(spacing_mode) == 'string' and spacing_mode ~= '' then
        parts[#parts + 1] = ('spacing=%s'):format(spacing_mode)
    end

    local indent_start = format_dimension(paragraph_style and paragraph_style.indentStart)
    if indent_start then
        parts[#parts + 1] = ('indentStart=%s'):format(indent_start)
    end

    local indent_first =
        format_dimension(paragraph_style and paragraph_style.indentFirstLine)
    if indent_first then
        parts[#parts + 1] = ('indentFirst=%s'):format(indent_first)
    end

    if type(bullet) == 'table' then
        local bullet_preset = bullet.listId or bullet.nestingLevel
        if bullet_preset ~= nil then
            parts[#parts + 1] = ('bullet=%s'):format(tostring(bullet_preset))
        else
            parts[#parts + 1] = 'bullet=yes'
        end
    end

    return parts
end

local function summarize_text_runs(element)
    local lines = {}

    for _, text_element in ipairs(text_elements(element)) do
        local text_run = text_element.textRun
        if text_run and type(text_run.content) == 'string' then
            local style_parts = summarize_text_style(text_run.style)
            local suffix = #style_parts > 0
                    and (' style=%s'):format(table.concat(style_parts, ','))
                or ''

            lines[#lines + 1] = ('    - [%s,%s): %s%s'):format(
                tostring(text_element.startIndex),
                tostring(text_element.endIndex),
                text_run.content:gsub('\n', '\\n'),
                suffix
            )
        elseif text_element.paragraphMarker then
            local paragraph_parts = summarize_paragraph_style(
                text_element.paragraphMarker.style,
                text_element.paragraphMarker.bullet
            )
            if #paragraph_parts > 0 then
                lines[#lines + 1] = ('    - [%s,%s): <paragraph> %s'):format(
                    tostring(text_element.startIndex),
                    tostring(text_element.endIndex),
                    table.concat(paragraph_parts, ',')
                )
            end
        end
    end

    return lines
end

local function summarize_placeholder(element)
    local placeholder = safe_tbl_get(element, 'shape', 'placeholder')
        or safe_tbl_get(element, 'placeholder')
    if type(placeholder) ~= 'table' then
        return nil
    end

    local parts = {}
    if placeholder.type then
        parts[#parts + 1] = tostring(placeholder.type)
    end
    if placeholder.index ~= nil then
        parts[#parts + 1] = ('index=%s'):format(tostring(placeholder.index))
    end

    if vim.tbl_isempty(parts) then
        return 'placeholder=yes'
    end

    return ('placeholder=%s'):format(table.concat(parts, ','))
end

local function summarize_geometry(element, page_size)
    local transform = type(element.transform) == 'table' and element.transform or nil
    local size = type(element.size) == 'table' and element.size or nil
    local page_width = safe_tbl_get(page_size, 'width', 'magnitude')
    local page_height = safe_tbl_get(page_size, 'height', 'magnitude')
    local translate_x = transform and transform.translateX or nil
    local translate_y = transform and transform.translateY or nil
    local width = safe_tbl_get(size, 'width', 'magnitude')
    local height = safe_tbl_get(size, 'height', 'magnitude')

    local left = type(translate_x) == 'number'
            and type(page_width) == 'number'
            and page_width ~= 0
            and format_percent((translate_x / page_width) * 100)
        or nil
    local top = type(translate_y) == 'number'
            and type(page_height) == 'number'
            and page_height ~= 0
            and format_percent((translate_y / page_height) * 100)
        or nil
    local norm_width = type(width) == 'number'
            and type(page_width) == 'number'
            and page_width ~= 0
            and format_percent((width / page_width) * 100)
        or nil
    local norm_height = type(height) == 'number'
            and type(page_height) == 'number'
            and page_height ~= 0
            and format_percent((height / page_height) * 100)
        or nil

    if not left and not top and not norm_width and not norm_height then
        return nil
    end

    return ('normalized=(left=%s, top=%s, width=%s, height=%s)'):format(
        left or '?',
        top or '?',
        norm_width or '?',
        norm_height or '?'
    )
end

local function summarize_text_metrics(element)
    local raw_text = extract_raw_shape_text(element)
    if raw_text == '' then
        return nil
    end

    local line_count = select(2, raw_text:gsub('\n', '\n')) + 1
    local text_run_count = vim.iter(text_elements(element))
        :filter(function(text_element)
            return type(safe_tbl_get(text_element, 'textRun', 'content')) == 'string'
        end)
        :fold(0, function(acc)
            return acc + 1
        end)

    return ('text_metrics=(chars=%d, lines=%d, runs=%d)'):format(
        #raw_text,
        line_count,
        text_run_count
    )
end

local function summarize_page_element(element, element_index, element_count, page_size)
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
        ('  - Element %d/%d (objectId: %s) %s'):format(
            element_index,
            element_count,
            gws_helpers.fallback_text(element.objectId, 'unknown'),
            summarize_element(element, kind, extra)
        ),
        ('    z_index=%d/%d'):format(element_index, element_count),
    }

    local placeholder_summary = summarize_placeholder(element)
    if placeholder_summary then
        lines[#lines + 1] = ('    %s'):format(placeholder_summary)
    end

    local geometry_summary = summarize_geometry(element, page_size)
    if geometry_summary then
        lines[#lines + 1] = ('    %s'):format(geometry_summary)
    end

    if element.shape then
        local raw_shape_text = extract_raw_shape_text(element)
        local shape_text = extract_shape_text(element)
        if shape_text ~= '' then
            lines[#lines + 1] = ('    text: %s'):format(shape_text:gsub('\n', '\\n'))
        end
        if raw_shape_text ~= '' then
            lines[#lines + 1] = ('    raw_text: %s'):format(
                raw_shape_text:gsub('\n', '\\n')
            )
        end

        local text_metrics = summarize_text_metrics(element)
        if text_metrics then
            lines[#lines + 1] = ('    %s'):format(text_metrics)
        end

        local text_run_lines = summarize_text_runs(element)
        if #text_run_lines > 0 then
            lines[#lines + 1] = '    text runs:'
            vim.list_extend(lines, text_run_lines)
        end
    end

    return lines
end

local function summarize_slide_page_elements(page_elements, page_size)
    local lines = {}
    if type(page_elements) ~= 'table' then
        return lines
    end

    local element_count = #page_elements
    for index, element in ipairs(page_elements) do
        vim.list_extend(
            lines,
            summarize_page_element(element, index, element_count, page_size)
        )
    end

    return lines
end

-- Slides
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
    local page_size = type(presentation.pageSize) == 'table' and presentation.pageSize
        or nil
    local lines = {
        ('Title: %s'):format(
            gws_helpers.fallback_text(presentation.title, 'Untitled presentation')
        ),
        ('Slides: %d'):format(#slides),
    }

    local page_width = format_dimension(page_size and page_size.width)
    local page_height = format_dimension(page_size and page_size.height)
    if page_width and page_height then
        lines[#lines + 1] = ('Page size: %s x %s'):format(page_width, page_height)
    end

    for i, slide in ipairs(slides) do
        local page_elements = type(slide.pageElements) == 'table' and slide.pageElements
            or {}
        local slide_properties = type(slide.slideProperties) == 'table'
                and slide.slideProperties
            or nil
        local has_notes = slide_properties and slide_properties.notesPage ~= nil
        local layout_object_id = safe_tbl_get(slide_properties, 'layoutObjectId')

        lines[#lines + 1] = ('- Slide %d (objectId: %s): objects=%d, notes=%s, blank=%s%s'):format(
            i,
            gws_helpers.fallback_text(slide.objectId, 'unknown'),
            #page_elements,
            has_notes and 'yes' or 'no',
            slide_appears_blank(slide) and 'yes' or 'no',
            layout_object_id and (', layout=' .. layout_object_id) or ''
        )
        vim.list_extend(lines, summarize_slide_page_elements(page_elements, page_size))
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
