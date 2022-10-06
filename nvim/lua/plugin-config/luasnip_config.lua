local u = require('utils')

require('luasnip.loaders.from_lua').lazy_load({
    paths = vim.fn.stdpath('config') .. '/snippets/',
})

u.keymap('n', '<Leader>es', function()
    require('luasnip.loaders.from_lua').edit_snippet_files()
end)
