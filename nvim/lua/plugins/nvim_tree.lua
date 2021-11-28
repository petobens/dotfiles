local u = require('utils')

local tree_cb = require('nvim-tree.config').nvim_tree_callback
local map_list = {
    {key = '<CR>', cb = tree_cb('cd')},
    {key = 'v', cb = tree_cb('vsplit')},
    {key = 's', cb = tree_cb('split')},
    {key = 'c', cb = tree_cb('create')},
    {key = 'd', cb = tree_cb('remove')},
    {key = 'r', cb = tree_cb('rename')},
    {key = 'y', cb = tree_cb('copy')},
    {key = 'u', cb = tree_cb('dir_up')},
    {key = 'zc', cb = tree_cb("close_node") },
    {key = 'o', cb = tree_cb('system_open')},
}

require('nvim-tree').setup({
    view = {
        mappings = {
            custom_only = false,
            list = map_list
        }
    }
})


u.keymap('n', '<Leader>ff', ':NvimTreeFindFile<CR>')
