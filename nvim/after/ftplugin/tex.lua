_G.TexFolding = {}
function _G.TexFolding.custom_foldtext()
    local fold_text = tostring(vim.fn.getline(vim.v.foldstart))
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
            local frame_title =
                string.match(tostring(vim.fn.getline(vim.v.foldstart + 1)), '{(.*.)}')
            fold_text = 'Frame - ' .. frame_title
        end
    end
    return fold_text
end

vim.opt_local.foldtext = 'v:lua.TexFolding.custom_foldtext()'
