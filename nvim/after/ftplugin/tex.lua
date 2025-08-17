-- luacheck:ignore 631
_G.TexFolding = {}

function _G.TexFolding.custom_foldtext()
    local bufnr = vim.api.nvim_get_current_buf()
    local fold_start = vim.v.foldstart
    local fold_text = vim.api.nvim_buf_get_lines(bufnr, fold_start - 1, fold_start, false)[1]
        or ''
    if vim.startswith(fold_text, '\\documentclass') then
        fold_text = 'Preamble'
    elseif vim.startswith(fold_text, '\\appendix') then
        fold_text = 'Appendix'
    elseif vim.startswith(fold_text, '\\begin') then
        -- Note: we only fold abstract and frame environments
        if string.match(fold_text, 'abstract') then
            fold_text = 'Abstract'
        else
            -- Assumes that we have something like `\frametitle{Foo}`
            -- in next line to the \begin{frame} line
            local next_line = vim.api.nvim_buf_get_lines(
                bufnr,
                fold_start,
                fold_start + 1,
                false
            )[1] or ''
            local frame_title = string.match(next_line, '{(.*.)}')
            fold_text = 'Frame - ' .. (frame_title or '')
        end
    end
    return fold_text
end

vim.opt_local.foldtext = 'v:lua.TexFolding.custom_foldtext()'
