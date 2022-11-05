local node_api = require('nvim-tree.api').node
local tree_api = require('nvim-tree.api').tree
local u = require('utils')

local Path = require('plenary.path')
local builtin = require('telescope.builtin')

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
    local node = tree_api.get_node_under_cursor()
    local p = Path:new(node.absolute_path):parent()
    local dir = vim.fn.fnamemodify(tostring(p), ':t')

    node_api.navigate.parent()
    tree_api.change_root_to_node()
    vim.cmd('sleep 3m')
    tree_api.find_file(dir)
end

function NvimTreeConfig.telescope_find_files()
    local node = tree_api.get_node_under_cursor()
    local p = Path:new(node.absolute_path)
    if p:is_file() then
        p = p:parent()
    end
    local dir = tostring(p)
    builtin.find_files({
        cwd = dir,
        results_title = dir,
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
    })
end

function NvimTreeConfig.telescope_find_dirs()
    _G.TelescopeConfig.find_dirs({
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
    })
end

function NvimTreeConfig.telescope_parent_dirs()
    _G.TelescopeConfig.parent_dirs({
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
    })
end

function NvimTreeConfig.telescope_z()
    -- FIXME: Not working
    _G.TelescopeConfig.z_with_tree_preview({
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
    })
end

function NvimTreeConfig.telescope_bookmarks()
    _G.TelescopeConfig.bookmark_dirs({
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
    })
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
    -- Telescope integration
    { key = '<C-t>', cb = ':lua NvimTreeConfig.telescope_find_files()<CR>' },
    { key = '<A-c>', cb = ':lua NvimTreeConfig.telescope_find_dirs()<CR>' },
    { key = '<A-p>', cb = ':lua NvimTreeConfig.telescope_parent_dirs()<CR>' },
    { key = '<A-z>', cb = ':lua NvimTreeConfig.telescope_z()<CR>' },
    { key = 'b', cb = ':lua NvimTreeConfig.telescope_bookmarks()<CR>' },
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
