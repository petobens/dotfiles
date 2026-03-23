local M = {}

-- Strings
function M.trim(s)
    return vim.trim(s or '')
end

function M.append_text(parts, text)
    text = text or ''
    if text ~= '' then
        table.insert(parts, text)
    end
end

function M.normalize_text(text)
    text = (text or ''):gsub('\r', '')
    text = text:gsub('\n%s*\n%s*\n+', '\n\n')
    return vim.trim(text)
end

-- Process
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
            M.trim(result.stderr) ~= '' and M.trim(result.stderr) or 'gws command failed'
    end

    return result.stdout or ''
end

-- Input parsing
function M.extract_google_id(input, kind)
    input = M.trim(input)
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

-- Chat context
function M.add_context(chat, kind, item, tag)
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

return M
