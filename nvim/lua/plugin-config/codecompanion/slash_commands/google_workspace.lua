-- luacheck:ignore 631
local M = {}

-- Constants
local DEFAULT_SHEET_RANGE = 'A1:AZ1000'

-- String helpers
local function trim(s)
    return vim.trim(s or '')
end

local function append_text(parts, text)
    text = text or ''
    if text ~= '' then
        table.insert(parts, text)
    end
end

local function normalize_text(text)
    text = (text or ''):gsub('\r', '')
    text = text:gsub('\n%s*\n%s*\n+', '\n\n')
    return vim.trim(text)
end

-- Process helpers
local function decode_json(stdout, err_context)
    local ok, decoded = pcall(vim.json.decode, stdout or '')
    if not ok or type(decoded) ~= 'table' then
        return nil, ('gws returned invalid JSON for %s'):format(err_context)
    end

    return decoded
end

local function run(args, opts)
    local result = vim.system(args, vim.tbl_extend('force', { text = true }, opts or {}))
        :wait()

    if result.code ~= 0 then
        return nil,
            trim(result.stderr) ~= '' and trim(result.stderr) or 'gws command failed'
    end

    return result.stdout or ''
end

-- Input parsing helpers
local function extract_id(input, kind)
    input = trim(input)
    if input == '' then
        return nil, ('Missing Google %s URL or ID'):format(kind)
    end

    local patterns = {
        docs = '/document/d/([%w%-_]+)',
        sheets = '/spreadsheets/d/([%w%-_]+)',
        slides = '/presentation/d/([%w%-_]+)',
    }

    local pattern = patterns[kind]
    if pattern then
        local id = input:match(pattern)
        if id then
            return id
        end
    end

    if input:match('^[%w%-_]+$') then
        return input
    end

    return nil, ('Could not extract a Google %s ID from the provided value'):format(kind)
end

-- API fetch helpers
local function fetch_google_doc(doc_id)
    local stdout, run_err = run({
        'gws',
        'docs',
        'documents',
        'get',
        '--params',
        vim.json.encode({ documentId = doc_id }),
    })
    if not stdout then
        return nil, run_err
    end

    return decode_json(stdout, 'the Google Doc')
end

local function fetch_google_sheet(sheet_id, range)
    local stdout, run_err = run({
        'gws',
        'sheets',
        'spreadsheets',
        'values',
        'get',
        '--params',
        vim.json.encode({
            spreadsheetId = sheet_id,
            range = range or DEFAULT_SHEET_RANGE,
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return decode_json(stdout, 'the Google Sheet')
end

local function fetch_google_slides(presentation_id)
    local stdout, run_err = run({
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

    return decode_json(stdout, 'the Google Slides presentation')
end

-- Content extraction helpers
local function collect_doc_elements(parts, elements)
    if type(elements) ~= 'table' then
        return
    end

    for _, element in ipairs(elements) do
        if element.paragraph and element.paragraph.elements then
            for _, paragraph_element in ipairs(element.paragraph.elements) do
                local text_run = paragraph_element.textRun
                if text_run and text_run.content then
                    append_text(parts, text_run.content)
                end
            end
        elseif element.table and element.table.tableRows then
            for _, row in ipairs(element.table.tableRows) do
                for _, cell in ipairs(row.tableCells or {}) do
                    collect_doc_elements(parts, cell.content)
                end
                append_text(parts, '\n')
            end
        elseif element.tableOfContents and element.tableOfContents.content then
            collect_doc_elements(parts, element.tableOfContents.content)
        end
    end
end

local function google_doc_to_text(doc)
    local parts = {}
    collect_doc_elements(parts, vim.tbl_get(doc, 'body', 'content'))

    local text = normalize_text(table.concat(parts, ''))
    if text == '' then
        return nil, 'The Google Doc appears to be empty or contains no extractable text'
    end

    return text
end

local function google_sheet_to_text(sheet)
    local values = sheet.values or {}
    if vim.tbl_isempty(values) then
        return nil, 'The Google Sheet range appears to be empty'
    end

    local lines = vim.iter(values)
        :map(function(row)
            return table.concat(
                vim.tbl_map(function(cell)
                    return tostring(cell)
                end, row),
                ' | '
            )
        end)
        :totable()

    return normalize_text(table.concat(lines, '\n'))
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
                append_text(parts, text_run)
            end
        end
    end
end

local function google_slides_to_text(presentation)
    local lines = {}

    for i, slide in ipairs(presentation.slides or {}) do
        table.insert(lines, ('Slide %d'):format(i))
        local parts = {}
        collect_slide_page_elements(parts, slide.pageElements)
        local text = normalize_text(table.concat(parts, ''))
        if text ~= '' then
            table.insert(lines, text)
        end
        table.insert(lines, '')
    end

    local text = normalize_text(table.concat(lines, '\n'))
    if text == '' then
        return nil,
            'The Google Slides presentation appears to be empty or contains no extractable text'
    end

    return text
end

-- Read helpers
local function read_google_doc(input)
    local doc_id, id_err = extract_id(input, 'docs')
    if not doc_id then
        return nil, id_err
    end

    local doc, fetch_err = fetch_google_doc(doc_id)
    if not doc then
        return nil, fetch_err
    end

    local text, text_err = google_doc_to_text(doc)
    if not text then
        return nil, text_err
    end

    return {
        id = doc_id,
        title = trim(doc.title) ~= '' and trim(doc.title) or 'Untitled document',
        text = text,
    }
end

local function read_google_sheet(input, range)
    local sheet_id, id_err = extract_id(input, 'sheets')
    if not sheet_id then
        return nil, id_err
    end

    local sheet, fetch_err = fetch_google_sheet(sheet_id, range)
    if not sheet then
        return nil, fetch_err
    end

    local text, text_err = google_sheet_to_text(sheet)
    if not text then
        return nil, text_err
    end

    return {
        id = sheet_id,
        title = trim(sheet.range) ~= '' and trim(sheet.range)
            or (range or DEFAULT_SHEET_RANGE),
        text = text,
    }
end

local function read_google_slides(input)
    local presentation_id, id_err = extract_id(input, 'slides')
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
        title = trim(presentation.title) ~= '' and trim(presentation.title)
            or 'Untitled presentation',
        text = text,
    }
end

-- Chat context helpers
local function add_context(chat, kind, item, tag)
    chat:add_context({
        role = 'user',
        content = string.format(
            'Here is the content of the Google %s "%s" (ID: %s):\n\n%s',
            kind,
            item.title,
            item.id,
            item.text
        ),
    }, 'url', string.format('<%s>%s</%s>', tag, item.title, tag))
end

-- Slash commands
function M.gdoc(chat)
    vim.ui.input({ prompt = 'Google Doc URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        local doc, err = read_google_doc(input)
        if not doc then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        add_context(chat, 'Doc', doc, 'gdoc')
    end)
end

function M.gsheet(chat)
    vim.ui.input({ prompt = 'Google Sheet URL or ID: ' }, function(input)
        if not input or vim.trim(input) == '' then
            return
        end

        vim.ui.input(
            { prompt = 'Sheet range: ', default = DEFAULT_SHEET_RANGE },
            function(range)
                if range == nil then
                    return
                end

                local sheet, err = read_google_sheet(
                    input,
                    vim.trim(range) ~= '' and vim.trim(range) or nil
                )
                if not sheet then
                    vim.notify(err, vim.log.levels.ERROR)
                    return
                end

                add_context(chat, 'Sheet', sheet, 'gsheet')
            end
        )
    end)
end

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

        add_context(chat, 'Slides presentation', slides, 'gslide')
    end)
end

return M
