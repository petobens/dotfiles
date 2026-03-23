-- luacheck:ignore 631
local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')

local M = {}

-- API fetch
local function fetch_google_slides(presentation_id)
    local stdout, run_err = gw.run({
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

    return gw.decode_json(stdout, 'the Google Slides presentation')
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
                gw.append_text(parts, text_run)
            end
        end

        if element.image then
            gw.append_text(parts, summarize_element(element, 'image') .. '\n')
        elseif element.table then
            local rows = vim.tbl_get(element, 'table', 'rows') or '?'
            local cols = vim.tbl_get(element, 'table', 'columns') or '?'
            gw.append_text(
                parts,
                summarize_element(
                    element,
                    'table',
                    ('rows=%s cols=%s'):format(rows, cols)
                ) .. '\n'
            )
        elseif element.video then
            gw.append_text(parts, summarize_element(element, 'video') .. '\n')
        elseif element.sheetsChart then
            gw.append_text(parts, summarize_element(element, 'chart') .. '\n')
        elseif element.shape and not has_text then
            local shape_type = vim.tbl_get(element, 'shape', 'shapeType')
            gw.append_text(parts, summarize_element(element, 'shape', shape_type) .. '\n')
        end
    end
end

-- Content extraction
local function google_slides_to_text(presentation)
    local lines = {}

    for i, slide in ipairs(presentation.slides or {}) do
        table.insert(lines, ('Slide %d'):format(i))
        local parts = {}
        collect_slide_page_elements(parts, slide.pageElements)
        local text = gw.normalize_text(table.concat(parts, ''))
        if text ~= '' then
            table.insert(lines, text)
        end
        table.insert(lines, '')
    end

    local text = gw.normalize_text(table.concat(lines, '\n'))
    if text == '' then
        return nil,
            'The Google Slides presentation appears to be empty or contains no extractable text'
    end

    return text
end

-- Read helpers
local function read_google_slides(input)
    local presentation_id, id_err = gw.extract_google_id(input, 'slides')
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

    local title = gw.trim(presentation.title)

    return {
        id = presentation_id,
        title = title ~= '' and title or 'Untitled presentation',
        text = text,
    }
end

-- Slash commands
function M.gslide(chat)
    vim.ui.input({ prompt = 'Google Slides URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        local slides, err = read_google_slides(input)
        if not slides then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        gw.add_context(chat, 'Slides presentation', slides, 'gslide')
    end)
end

return M
