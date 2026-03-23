local gw = require('plugin-config.codecompanion.slash_commands.gworkspace')

local M = {}

-- API fetch
local function fetch_google_doc(doc_id)
    local stdout, run_err = gw.run({
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

    return gw.decode_json(stdout, 'the Google Doc')
end

local function collect_doc_elements(parts, elements)
    if type(elements) ~= 'table' then
        return
    end

    for _, element in ipairs(elements) do
        if element.paragraph and element.paragraph.elements then
            for _, paragraph_element in ipairs(element.paragraph.elements) do
                local text_run = paragraph_element.textRun
                if text_run and text_run.content then
                    gw.append_text(parts, text_run.content)
                end
            end
        elseif element.table and element.table.tableRows then
            for _, row in ipairs(element.table.tableRows) do
                for _, cell in ipairs(row.tableCells or {}) do
                    collect_doc_elements(parts, cell.content)
                end
                gw.append_text(parts, '\n')
            end
        elseif element.tableOfContents and element.tableOfContents.content then
            collect_doc_elements(parts, element.tableOfContents.content)
        end
    end
end

-- Content extraction
local function google_doc_to_text(doc)
    local parts = {}
    collect_doc_elements(parts, vim.tbl_get(doc, 'body', 'content'))

    local text = gw.normalize_text(table.concat(parts, ''))
    if text == '' then
        return nil, 'The Google Doc appears to be empty or contains no extractable text'
    end

    return text
end

-- Read helpers
local function read_google_doc(input)
    local doc_id, id_err = gw.extract_google_id(input, 'docs')
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
        title = gw.trim(doc.title) ~= '' and gw.trim(doc.title) or 'Untitled document',
        text = text,
    }
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

        gw.add_context(chat, 'Doc', doc, 'gdoc')
    end)
end

return M
