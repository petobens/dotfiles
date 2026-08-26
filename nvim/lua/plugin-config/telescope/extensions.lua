local telescope = require('telescope')

local M = {}

function M.setup()
    telescope.load_extension('aerial')
    telescope.load_extension('frecency')
    telescope.load_extension('fzf')
    telescope.load_extension('luasnip')
    telescope.load_extension('neoclip')
    telescope.load_extension('thesaurus')
    telescope.load_extension('ui-select')
    telescope.load_extension('undo')
    telescope.load_extension('z')
end

return M
