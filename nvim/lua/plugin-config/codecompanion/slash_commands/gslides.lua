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

local function collect_slide_page_elements(parts, page_elements)
    if type(page_elements) ~= 'table' then
        return
    end

    for _, element in ipairs(page_elements) do
        local text_elements = vim.tbl_get(element, 'shape', 'text', 'textElements') or {}
        for _, text_element in ipairs(text_elements) do
            local text_run = vim.tbl_get(text_element, 'textRun', 'content')
            if text_run then
                gw.append_text(parts, text_run)
            end
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

    return {
        id = presentation_id,
        title = gw.trim(presentation.title) ~= '' and gw.trim(presentation.title)
            or 'Untitled presentation',
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
