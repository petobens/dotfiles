local chat_helpers = require('plugin-config.codecompanion.helpers').chat
local prompt_library = require('plugin-config.codecompanion.prompt_library')

local M = {}

-- Helpers
local function collect_diagnostics_entries_and_context()
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

    local seen, entries, context = {}, {}, {}

    for _, item in ipairs(diagnostics) do
        local filename = vim.fs.basename(vim.api.nvim_buf_get_name(item.bufnr))
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
            if filename ~= '' and not vim.tbl_contains(context, filename) then
                table.insert(context, filename)
            end
        end
    end

    return table.concat(entries, '\n'), context
end

-- Slash commands
function M.qfix(chat)
    local entries, context = collect_diagnostics_entries_and_context()
    if entries == '' then
        vim.notify(
            'No diagnostics found in quickfix or location lists.',
            vim.log.levels.ERROR
        )
        return
    end

    chat_helpers.add_context(context)
    chat:add_buf_message({
        role = 'user',
        content = string.format(prompt_library.prompt('quickfix'), entries),
    })
    chat:submit()
end

function M.explain_code(chat, opts)
    local bufnr = opts and opts.bufnr
    local code = opts and opts.code
    local file = vim.api.nvim_buf_get_name(bufnr)
    local ft = vim.bo[bufnr].filetype ~= '' and vim.bo[bufnr].filetype or 'text'

    chat_helpers.add_context({ file })
    chat:add_buf_message({
        role = 'user',
        content = string.format(prompt_library.prompt('explain_code'), ft, code),
    })
    chat:submit()
end

return M
