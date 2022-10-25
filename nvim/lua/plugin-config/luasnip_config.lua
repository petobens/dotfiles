local u = require('utils')
local luasnip = require('luasnip')
local types = require('luasnip.util.types')

local snippets_dir = vim.fn.stdpath('config') .. '/snippets/'

luasnip.setup({
    history = true, -- allow to jump back into exited (last) snippet
    enable_autosnippets = true,
    update_events = 'TextChanged,TextChangedI',
    store_selection_keys = '<C-s>',
    ext_opts = {
        [types.choiceNode] = {
            -- Show indication of choice node
            active = { virt_text = { { ' (Choice-Node)', 'DiagnosticInfo' } } },
        },
    },
})
require('luasnip.loaders.from_lua').lazy_load({
    paths = { snippets_dir },
})

-- Mappings
u.keymap({ 'i', 's' }, '<C-s>', function()
    if luasnip.expandable() then
        luasnip.expand({})
    end
end)
u.keymap({ 'i', 's' }, '<C-j>', function()
    if luasnip.jumpable(1) then
        luasnip.jump(1)
    end
end)
u.keymap({ 'i', 's' }, '<C-k>', function()
    if luasnip.jumpable(-1) then
        luasnip.jump(-1)
    end
end)
u.keymap({ 'i', 's' }, '<C-x>', function()
    if luasnip.choice_active() then
        luasnip.change_choice(1)
    end
end)
u.keymap('n', '<Leader>es', function()
    local snippet_file = vim.bo.filetype .. '.lua'
    if vim.bo.filetype == 'tex' or vim.bo.filetype == 'lua' then
        snippet_file = vim.bo.filetype .. '/' .. snippet_file
    end
    local split = 'split '
    if vim.fn.winwidth(0) > 2 * (vim.go.textwidth or 80) then
        split = 'vsplit '
    end
    vim.cmd(split .. snippets_dir .. snippet_file)
end)
