require('mini.align').setup({
    mappings = {
        start = '<Leader>al', -- used with visual or motion
        start_with_preview = '<Leader>ma', -- interactive
    },
})

for lhs, desc in pairs({
    ['<Leader>al'] = '[A]lign [l]ines',
    ['<Leader>ma'] = '[M]ini [a]lign with preview',
}) do
    for _, mode in ipairs({ 'n', 'x' }) do
        local mapping = vim.iter(vim.api.nvim_get_keymap(mode)):find(function(item)
            return item.lhs == lhs:gsub('<Leader>', vim.g.mapleader, 1)
        end)
        vim.keymap.set(mode, lhs, mapping.callback, {
            desc = desc,
            expr = mapping.expr == 1,
        })
    end
end
