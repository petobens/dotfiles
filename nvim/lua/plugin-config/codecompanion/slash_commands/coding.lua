local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local prompt_library = require('plugin-config.codecompanion.prompt_library')

local M = {}

-- Helpers
local function collect_diagnostics()
    local diagnostics = {}

    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        local loclist = vim.fn.getloclist(winid)
        if #loclist > 0 then
            vim.list_extend(diagnostics, loclist)
        end
    end

    if #diagnostics == 0 then
        diagnostics = vim.fn.getqflist()
    end

    local seen, entries = {}, {}

    for _, item in ipairs(diagnostics) do
        local filename = vim.api.nvim_buf_get_name(item.bufnr)
        local lnum = item.lnum or 0
        local col = item.col or 0
        local text = item.text or ''
        local key = table.concat({ filename, lnum, col, text }, '\0')

        if not seen[key] then
            seen[key] = true
            table.insert(
                entries,
                string.format('%s:%d:%d: %s', filename, lnum, col, text)
            )
        end
    end

    return table.concat(entries, '\n')
end

-- Slash commands
function M.qfix(chat)
    local entries = collect_diagnostics()
    if entries == '' then
        vim.notify(
            'No diagnostics found in quickfix or location lists.',
            vim.log.levels.ERROR
        )
        return
    end

    chat_helpers.submit_user_message(
        chat,
        string.format(prompt_library.prompt('quickfix'), entries)
    )
end

function M.explain_code(chat, opts)
    local bufnr = opts and opts.bufnr
    local code = opts and opts.code
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) or not code or code == '' then
        vim.notify('Select code in visual mode and use <Leader>ec', vim.log.levels.WARN)
        return
    end

    local file = vim.api.nvim_buf_get_name(bufnr)
    local filename = file ~= '' and file or '[unnamed buffer]'
    local filetype = vim.bo[bufnr].filetype
    local language = filetype ~= '' and filetype or 'text'
    chat_helpers.submit_user_message(
        chat,
        string.format(
            'Code from `%s`.\n\n%s',
            filename,
            string.format(prompt_library.prompt('explain_code'), language, code)
        )
    )
end

return M
