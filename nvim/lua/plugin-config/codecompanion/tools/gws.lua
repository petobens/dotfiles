-- luacheck:ignore 631
local M = {}

-- Generic string helpers
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

-- Generic gws process helpers
function M.decode_json(stdout, err_context)
    local ok, decoded = pcall(vim.json.decode, stdout or '')
    if not ok or type(decoded) ~= 'table' then
        return nil, ('gws returned invalid JSON for %s'):format(err_context)
    end

    return decoded
end

function M.run(args, opts)
    local result = vim.system(args, vim.tbl_extend('force', { text = true }, opts or {}))
        :wait()

    if result.code ~= 0 then
        return nil,
            trim(result.stderr) ~= '' and trim(result.stderr) or 'gws command failed'
    end

    return result.stdout or ''
end

-- URL/ID extraction helpers
function M.extract_id(input, kind)
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

-- Raw gws fetchers
function M.fetch_google_doc(doc_id)
    local stdout, run_err = M.run({
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

    return M.decode_json(stdout, 'the Google Doc')
end

function M.fetch_google_sheet(sheet_id, range)
    local stdout, run_err = M.run({
        'gws',
        'sheets',
        'spreadsheets',
        'values',
        'get',
        '--params',
        vim.json.encode({
            spreadsheetId = sheet_id,
            range = range or 'A1:Z200',
        }),
    })
    if not stdout then
        return nil, run_err
    end

    return M.decode_json(stdout, 'the Google Sheet')
end

function M.fetch_google_slides(presentation_id)
    local stdout, run_err = M.run({
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

    return M.decode_json(stdout, 'the Google Slides presentation')
end

-- Docs text extraction
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

function M.google_doc_to_text(doc)
    local parts = {}
    collect_doc_elements(parts, vim.tbl_get(doc, 'body', 'content'))

    local text = normalize_text(table.concat(parts, ''))
    if text == '' then
        return nil, 'The Google Doc appears to be empty or contains no extractable text'
    end

    return text
end

-- Sheets text extraction
function M.google_sheet_to_text(sheet)
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

-- Slides text extraction
local function collect_slide_page_elements(parts, page_elements)
    if type(page_elements) ~= 'table' then
        return
    end

    for _, element in ipairs(page_elements) do
        local text_elements = vim.tbl_get(element, 'shape', 'text', 'textElements') or {}
        for _, text_element in ipairs(text_elements) do
            local run = vim.tbl_get(text_element, 'textRun', 'content')
            if run then
                append_text(parts, run)
            end
        end
    end
end

function M.google_slides_to_text(presentation)
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

-- High-level read helpers
function M.read_google_doc(input)
    local doc_id, id_err = M.extract_id(input, 'docs')
    if not doc_id then
        return nil, id_err
    end

    local doc, fetch_err = M.fetch_google_doc(doc_id)
    if not doc then
        return nil, fetch_err
    end

    local text, text_err = M.google_doc_to_text(doc)
    if not text then
        return nil, text_err
    end

    return {
        id = doc_id,
        title = trim(doc.title) ~= '' and trim(doc.title) or 'Untitled document',
        text = text,
    }
end

function M.read_google_sheet(input, range)
    local sheet_id, id_err = M.extract_id(input, 'sheets')
    if not sheet_id then
        return nil, id_err
    end

    local sheet, fetch_err = M.fetch_google_sheet(sheet_id, range)
    if not sheet then
        return nil, fetch_err
    end

    local text, text_err = M.google_sheet_to_text(sheet)
    if not text then
        return nil, text_err
    end

    return {
        id = sheet_id,
        title = trim(sheet.range) ~= '' and trim(sheet.range) or (range or 'A1:Z200'),
        text = text,
    }
end

function M.read_google_slides(input)
    local presentation_id, id_err = M.extract_id(input, 'slides')
    if not presentation_id then
        return nil, id_err
    end

    local presentation, fetch_err = M.fetch_google_slides(presentation_id)
    if not presentation then
        return nil, fetch_err
    end

    local text, text_err = M.google_slides_to_text(presentation)
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

return M
