local luasnip = require('luasnip')
local types = require('luasnip.util.types')

_G.LuaSnipConfig = {}

-- Helpers
function _G.LuaSnipConfig.visual_selection(_, parent)
    return parent.snippet.env.LS_SELECT_DEDENT or {}
end

function _G.LuaSnipConfig.snake_case_labels(node_idx)
    local str = node_idx[1][1]
    local unicode_map = {
        ['á'] = 'a',
        ['Á'] = 'A',
        ['é'] = 'e',
        ['É'] = 'E',
        ['í'] = 'i',
        ['Í'] = 'I',
        ['ó'] = 'o',
        ['Ó'] = 'O',
        ['ú'] = 'u',
        ['Ú'] = 'U',
        ['ñ'] = 'ni',
    }
    for k, v in pairs(unicode_map) do
        str = str:gsub(k, v)
    end
    -- Remove punctuation marks, lowercase and replace spaces with underscores
    str = str:gsub('[%p]', ''):lower():gsub('%s+', '_')
    return str:sub(1, 35)
end

-- Setup
luasnip.setup({
    ft_func = require('luasnip.extras.filetype_functions').from_pos_or_filetype,
    history = true, -- allow to jump back into exited (last) snippet
    enable_autosnippets = true,
    update_events = 'TextChanged,TextChangedI',
    delete_check_events = 'TextChanged', -- remove snippet when text is deleted
    store_selection_keys = '<C-s>',
    ext_opts = {
        [types.choiceNode] = {
            -- Show indication of choice node
            active = { virt_text = { { ' (Choice-Node)', 'DiagnosticInfo' } } },
        },
    },
})
-- Note: we use load instead of lazy_load to allow loading of injected languages
local snippets_dir = vim.fs.joinpath(vim.fn.stdpath('config'), 'snippets')
require('luasnip.loaders.from_lua').load({
    paths = { snippets_dir },
})
-- Fix for autosnippets expansion (map treesitter parser to ft)
-- https://github.com/L3MON4D3/LuaSnip/issues/823
luasnip.filetype_extend('bash', { 'sh' })
luasnip.filetype_extend('latex', { 'tex' })
luasnip.filetype_extend('markdown_inline', { 'markdown' })

-- Mappings
vim.keymap.set({ 'i', 's' }, '<C-s>', function()
    if luasnip.expandable() then
        luasnip.expand({})
    end
end, { desc = 'Expand snippet' })

vim.keymap.set({ 'i', 's' }, '<C-j>', function()
    if luasnip.jumpable(1) then
        luasnip.jump(1)
    end
end, { desc = 'Jump to next snippet field' })

vim.keymap.set({ 'i', 's' }, '<C-k>', function()
    if luasnip.jumpable(-1) then
        luasnip.jump(-1)
    end
end, { desc = 'Jump to previous snippet field' })

vim.keymap.set({ 'i', 's' }, '<C-x>', function()
    if luasnip.choice_active() then
        luasnip.change_choice(1)
    end
end, { desc = 'Cycle through snippet choices' })

vim.keymap.set('n', '<Leader>es', function()
    local ft = vim.bo.filetype
    local special_fts = { tex = true, lua = true, markdown = true }
    if special_fts[ft] then
        require('telescope.builtin').find_files({
            cwd = vim.fs.joinpath(snippets_dir, ft),
        })
        return
    end

    local snippet_file = vim.fs.joinpath(snippets_dir, ft .. '.lua')
    require('utils').split_open(snippet_file)
end, { desc = 'Edit snippet file for current filetype' })
