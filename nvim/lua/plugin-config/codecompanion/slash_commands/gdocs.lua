local gws_helpers =
    require('plugin-config.codecompanion.slash_commands.gworkspace_helpers')

local M = {}

-- API
local function fetch_google_doc(doc_id)
    local stdout, run_err = gws_helpers.run({
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

    return gws_helpers.decode_json(stdout, 'the Google Doc')
end

-- Text
local function document_title(doc)
    return gws_helpers.fallback_text(doc.title, 'Untitled document')
end

local function collect_doc_elements(parts, elements)
    if type(elements) ~= 'table' then
        return
    end

    for _, element in ipairs(elements) do
        if element.paragraph then
            for _, paragraph_element in ipairs(element.paragraph.elements or {}) do
                gws_helpers.append_text(
                    parts,
                    vim.tbl_get(paragraph_element, 'textRun', 'content')
                )
            end
        elseif element.table then
            for _, row in ipairs(element.table.tableRows or {}) do
                for _, cell in ipairs(row.tableCells or {}) do
                    collect_doc_elements(parts, cell.content)
                end
                gws_helpers.append_text(parts, '\n')
            end
        elseif element.tableOfContents then
            collect_doc_elements(parts, element.tableOfContents.content)
        end
    end
end

local function google_doc_to_text(doc)
    local parts = {}
    collect_doc_elements(parts, vim.tbl_get(doc, 'body', 'content'))

    local text = gws_helpers.normalize_text(table.concat(parts, ''))
    if text == '' then
        return nil, 'The Google Doc appears to be empty or contains no extractable text'
    end
    return text
end

local function summarize_google_doc(doc, doc_id)
    local counts = {
        paragraph = 0,
        table = 0,
        toc = 0,
    }

    local function walk(elements)
        if type(elements) ~= 'table' then
            return
        end

        for _, element in ipairs(elements) do
            if element.paragraph then
                counts.paragraph = counts.paragraph + 1
            elseif element.table then
                counts.table = counts.table + 1
                for _, row in ipairs(element.table.tableRows or {}) do
                    for _, cell in ipairs(row.tableCells or {}) do
                        walk(cell.content)
                    end
                end
            elseif element.tableOfContents then
                counts.toc = counts.toc + 1
                walk(element.tableOfContents.content)
            end
        end
    end

    walk(vim.tbl_get(doc, 'body', 'content'))

    return {
        id = doc_id,
        title = document_title(doc),
        text = table.concat({
            ('Title: %s'):format(document_title(doc)),
            ('Paragraphs: %d'):format(counts.paragraph),
            ('Tables: %d'):format(counts.table),
            ('Tables of contents: %d'):format(counts.toc),
        }, '\n'),
    }
end

-- Read
local function read_google_doc(input)
    local doc_id, id_err = gws_helpers.extract_google_id(input, 'docs')
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
        title = document_title(doc),
        text = text,
    }
end

local function read_google_doc_metadata(input)
    local doc_id, id_err = gws_helpers.extract_google_id(input, 'docs')
    if not doc_id then
        return nil, id_err
    end

    local doc, fetch_err = fetch_google_doc(doc_id)
    if not doc then
        return nil, fetch_err
    end

    return summarize_google_doc(doc, doc_id)
end

-- Exports
M.read_google_doc = read_google_doc
M.read_google_doc_metadata = read_google_doc_metadata

-- Command
function M.gdoc_read(chat)
    vim.ui.input({ prompt = 'Google Doc URL or ID: ' }, function(input)
        if not input or gws_helpers.is_blank(input) then
            return
        end

        local doc, err = read_google_doc(input)
        if not doc then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        gws_helpers.add_context(chat, 'Doc', doc, 'gdoc')
    end)
end

return M
