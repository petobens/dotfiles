-- luacheck:ignore 631
local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')

local M = {}

-- API fetch
local function fetch_google_slides(presentation_id)
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

-- Visual metadata
local function format_dimension(dimension)
    local magnitude = vim.tbl_get(dimension, 'magnitude')
    local unit = vim.tbl_get(dimension, 'unit')

    if type(magnitude) ~= 'number' then
        return nil
    end

    return unit and ('%s %s'):format(magnitude, unit) or tostring(magnitude)
end

local function summarize_element(element, kind, extra)
    local suffixes = {}

    if extra and extra ~= '' then
        table.insert(suffixes, extra)
    end

    local width = format_dimension(vim.tbl_get(element, 'size', 'width'))
    local height = format_dimension(vim.tbl_get(element, 'size', 'height'))
    if width and height then
        table.insert(suffixes, ('size=%s x %s'):format(width, height))
    end

    local transform = element.transform
    if type(transform) == 'table' then
        local x = transform.translateX or 0
        local y = transform.translateY or 0
        local unit = transform.unit or ''
        table.insert(
            suffixes,
            ('pos=(%s, %s)%s'):format(x, y, unit ~= '' and (' ' .. unit) or '')
        )
    end

    local summary = ('[%s]'):format(kind)
    if not vim.tbl_isempty(suffixes) then
        summary = summary .. ' ' .. table.concat(suffixes, ', ')
    end

    return summary
end

local function collect_slide_page_elements(parts, page_elements)
    if type(page_elements) ~= 'table' then
        return
    end

    for _, element in ipairs(page_elements) do
        local text_elements = vim.tbl_get(element, 'shape', 'text', 'textElements') or {}
        local has_text = false

        for _, text_element in ipairs(text_elements) do
            local text_run = vim.tbl_get(text_element, 'textRun', 'content')
            if text_run then
                has_text = true
                gws_helpers.append_text(parts, text_run)
            end
        end

        if element.image then
            gws_helpers.append_text(parts, summarize_element(element, 'image') .. '\n')
        elseif element.table then
            local rows = vim.tbl_get(element, 'table', 'rows') or '?'
            local cols = vim.tbl_get(element, 'table', 'columns') or '?'
            gws_helpers.append_text(
                parts,
                summarize_element(
                    element,
                    'table',
                    ('rows=%s cols=%s'):format(rows, cols)
                ) .. '\n'
            )
        elseif element.video then
            gws_helpers.append_text(parts, summarize_element(element, 'video') .. '\n')
        elseif element.sheetsChart then
            gws_helpers.append_text(parts, summarize_element(element, 'chart') .. '\n')
        elseif element.shape and not has_text then
            local shape_type = vim.tbl_get(element, 'shape', 'shapeType')
            gws_helpers.append_text(
                parts,
                summarize_element(element, 'shape', shape_type) .. '\n'
            )
        end
    end
end

local function extract_slide_text(slide)
    local parts = {}
    collect_slide_page_elements(parts, slide.pageElements)
    return gws_helpers.normalize_text(table.concat(parts, ''))
end

local function slide_appears_blank(slide)
    return extract_slide_text(slide) == ''
end

-- Content extraction
local function google_slides_to_text(presentation)
    local lines = {}

    for i, slide in ipairs(presentation.slides or {}) do
        local slide_object_id = gws_helpers.fallback_text(slide.objectId, 'unknown')
        local text = extract_slide_text(slide)
        local blank_suffix = slide_appears_blank(slide) and ', appears blank' or ''
        table.insert(
            lines,
            ('Slide %d (objectId: %s%s)'):format(i, slide_object_id, blank_suffix)
        )
        if text ~= '' then
            table.insert(lines, text)
        end
        table.insert(lines, '')
    end

    local text = gws_helpers.normalize_text(table.concat(lines, '\n'))
    if text == '' then
        return nil,
            'The Google Slides presentation appears to be empty or contains no extractable text'
    end

    return text
end

local function summarize_google_slides(presentation, presentation_id)
    local title = gws_helpers.fallback_text(presentation.title, 'Untitled presentation')
    local slides = presentation.slides or {}
    local lines = {
        ('Title: %s'):format(title),
        ('Slides: %d'):format(#slides),
    }

    for i, slide in ipairs(slides) do
        local page_elements = slide.pageElements or {}
        local notes = vim.tbl_get(slide, 'slideProperties', 'notesPage') and 'yes' or 'no'
        local blank = slide_appears_blank(slide) and 'yes' or 'no'
        local slide_object_id = gws_helpers.fallback_text(slide.objectId, 'unknown')
        table.insert(
            lines,
            ('- Slide %d (objectId: %s): objects=%d, notes=%s, blank=%s'):format(
                i,
                slide_object_id,
                #page_elements,
                notes,
                blank
            )
        )
    end

    return {
        id = presentation_id,
        title = title,
        text = table.concat(lines, '\n'),
    }
end

-- Read helpers
local function read_google_slides(input)
    local presentation_id, id_err = gws_helpers.extract_google_id(input, 'slides')
    if not presentation_id then
        return nil, id_err
    end

    local presentation, fetch_err = fetch_google_slides(presentation_id)
    if not presentation then
        return nil, fetch_err
    end

    local text, text_err = google_slides_to_text(presentation)
    if not text then
        return nil, text_err
    end

    local title = gws_helpers.fallback_text(presentation.title, 'Untitled presentation')

    return {
        id = presentation_id,
        title = title,
        text = text,
    }
end

local function read_google_slides_metadata(input)
    local presentation_id, id_err = gws_helpers.extract_google_id(input, 'slides')
    if not presentation_id then
        return nil, id_err
    end

    local presentation, fetch_err = fetch_google_slides(presentation_id)
    if not presentation then
        return nil, fetch_err
    end

    return summarize_google_slides(presentation, presentation_id)
end

-- Exports for reuse by tools
M.fetch_google_slides = fetch_google_slides
M.read_google_slides = read_google_slides
M.read_google_slides_metadata = read_google_slides_metadata

-- Slash command
function M.gslide(chat)
    vim.ui.input({ prompt = 'Google Slides URL or ID: ' }, function(input)
        if not input or gws_helpers.is_blank(input) then
            return
        end

        local slides, err = read_google_slides(input)
        if not slides then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        gws_helpers.add_context(chat, 'Slides presentation', slides, 'gslide')
    end)
end

return M
