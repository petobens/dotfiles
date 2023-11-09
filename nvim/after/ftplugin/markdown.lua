vim.opt_local.foldlevel = 2
vim.opt_local.foldlevelstart = 1
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.formatoptions = 'trjw'
vim.opt_local.comments = {}

_G.MarkdownFolding = {}
function _G.MarkdownFolding.custom_foldtext()
    local fold_text = vim.treesitter.foldtext()
    local conceal_map = {
        ['#'] = '󰪥',
        ['##'] = '󰺕',
        ['###'] = '',
        ['####'] = '',
        ['#####'] = '○',
    }
    for _, v in pairs(fold_text) do
        if vim.startswith(v[1], '#') then
            v[1] = conceal_map[v[1]]
        end
        for i, h in pairs(v[2]) do
            if vim.startswith(h, '@text.title') then
                v[2][i] = v[2][i] .. '.markdown'
            end
        end
    end
    return fold_text
end
vim.opt_local.foldtext = 'v:lua.MarkdownFolding.custom_foldtext()'
