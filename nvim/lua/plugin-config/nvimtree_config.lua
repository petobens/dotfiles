local node_api = require('nvim-tree.api').node
local tree_api = require('nvim-tree.api').tree
local u = require('utils')

_G.NvimTreeConfig = {}

function NvimTreeConfig.home()
    tree_api.change_root(vim.env.HOME)
end

function NvimTreeConfig.cd_find_file()
    vim.cmd('NvimTreeFindFile')
    vim.cmd('sleep 3m') -- we seem to need this to allow focus
    local node = tree_api.get_node_under_cursor()
    node_api.navigate.parent()
    local parent_node = tree_api.get_node_under_cursor()
    if parent_node.name == '..' then
        tree_api.collapse_all()
    else
        tree_api.change_root_to_node()
        node_api.navigate.sibling.first() -- to center
    end
    tree_api.find_file(node.name)
end

function NvimTreeConfig.cd_or_open()
    local node = tree_api.get_node_under_cursor()
    if node then
        if node.nodes then
            tree_api.change_root_to_node()
            node_api.navigate.sibling.first() -- to center
            vim.cmd('normal! h') -- to avoid moving cursor
        else
            node_api.open.edit()
        end
    end
end

function NvimTreeConfig.up_dir()
    node_api.navigate.parent()
    tree_api.change_root_to_node()
    vim.cmd('normal! j') -- don't start on root
end

local tree_cb = require('nvim-tree.config').nvim_tree_callback
local map_list = {
    { key = '<CR>', cb = ':lua NvimTreeConfig.cd_or_open()<CR>' },
    { key = 'v', cb = tree_cb('vsplit') },
    { key = 's', cb = tree_cb('split') },
    { key = 'F', cb = tree_cb('create') },
    { key = 'D', cb = tree_cb('create') },
    { key = 'd', cb = tree_cb('remove') },
    { key = '<C-o>', cb = tree_cb('cd') },
    { key = 'r', cb = tree_cb('rename') },
    { key = 'y', cb = tree_cb('copy') },
    { key = 'u', cb = ':lua NvimTreeConfig.up_dir()<CR>' },
    { key = 'h', cb = ':lua NvimTreeConfig.home()<CR>' },
    { key = 'zc', cb = tree_cb('close_node') },
    { key = 'zo', cb = tree_cb('edit') },
    { key = 'zm', cb = ':lua require("nvim-tree.lib").collapse_all()<CR>' },
    { key = 'o', cb = tree_cb('system_open') },
    { key = '<Space>', cb = tree_cb('toggle_mark') },
}

require('nvim-tree').setup({
    disable_netrw = false, -- conflicts with Fugitive's Gbrowse
    view = {
        width = 43,
        number = true,
        relativenumber = true,
        mappings = {
            custom_only = false,
            list = map_list,
        },
    },
    renderer = {
        root_folder_modifier = ':t',
        icons = {
            git_placement = 'after',
            glyphs = {
                folder = {
                    arrow_open = '',
                    arrow_closed = '',
                },
                bookmark = '',
                git = {
                    unstaged = '✚',
                    staged = '●',
                    untracked = '?',
                    deleted = '✖',
                },
            },
        },
    },
    update_focused_file = {
        enable = true,
        update_cwd = true,
    },
    actions = {
        open_file = {
            quit_on_open = true,
            window_picker = {
                enable = false,
            },
        },
    },
})

u.keymap('n', '<Leader>ff', NvimTreeConfig.cd_find_file)
