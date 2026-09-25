require('nvim-surround').setup({
    aliases = {
        -- Never add leading/trailing whitespace
        ['('] = ')',
        ['['] = ']',
        ['{'] = '}',
        ['<'] = '>',
    },
})

-- After plugin startup, let ys/yS wait for the final key of yss/ySS
vim.schedule(function()
    for _, key in ipairs({ 'ys', 'yS' }) do
        local mapping = vim.fn.maparg(key, 'n', false, true)
        mapping.nowait = 0
        vim.fn.mapset('n', false, mapping)
    end
end)
