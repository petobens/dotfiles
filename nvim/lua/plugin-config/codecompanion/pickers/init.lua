-- Shared display helpers for the CodeCompanion picker UIs
local M = {}

M.TITLE_WIDTH = 80

-- Collapse whitespace and truncate `text` to `width` display columns, appending
-- an ellipsis when it overflows
function M.trim_chars(text, width)
    text = vim.trim((text or ''):gsub('%s+', ' '))
    if vim.fn.strdisplaywidth(text) <= width then
        return text
    end

    local suffix = '...'
    local limit = width - vim.fn.strdisplaywidth(suffix)
    local out = {}
    local current_width = 0

    for i = 0, vim.fn.strchars(text) - 1 do
        local char = vim.fn.strcharpart(text, i, 1)
        local char_width = vim.fn.strdisplaywidth(char)
        if current_width + char_width > limit then
            break
        end
        out[#out + 1] = char
        current_width = current_width + char_width
    end

    return table.concat(out) .. suffix
end

-- Right-pad `text` with spaces to `width` display columns
function M.pad_right(text, width)
    return text .. string.rep(' ', math.max(width - vim.fn.strdisplaywidth(text), 0))
end

return M
