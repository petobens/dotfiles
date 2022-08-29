local u = require('utils')

_G.NvimTreeConfig = {}

function NvimTreeConfig.home()
    local lib = require('nvim-tree.lib')
    lib.change_dir(vim.env.HOME)
end

function NvimTreeConfig.find_file()
    local nvim_tree = require('nvim-tree')
    nvim_tree.find_file(true)
    local lib = require('nvim-tree.lib')
    local node = lib.get_node_at_cursor()
    local curr_file = node.name
    local parent_dir = vim.fn.fnamemodify(node.absolute_path, ':h:t')
    nvim_tree.on_keypress('close_node')
    nvim_tree.on_keypress('cd')
    if vim.fn.line('.') > 1 then
        local linenr = vim.fn.searchpos(curr_file)[1]
        vim.cmd('normal! gg' .. (linenr - 1) .. 'j')
    else
        local linenr = vim.fn.searchpos(parent_dir)[1]
        vim.cmd('normal! gg' .. (linenr - 1) .. 'j')
        nvim_tree.on_keypress('cd')
        linenr = vim.fn.searchpos(curr_file)[1]
        vim.cmd('normal! gg' .. (linenr - 1) .. 'j')
    end
end

function NvimTreeConfig.cd_or_open()
    local nvim_tree = require('nvim-tree')
    local lib = require('nvim-tree.lib')
    local node = lib.get_node_at_cursor()
    if node then
        if node.entries then
            nvim_tree.on_keypress('cd')
        else
            nvim_tree.on_keypress('edit')
        end
    end
end

function NvimTreeConfig.up_dir()
    local nvim_tree = require('nvim-tree')
    local lib = require('nvim-tree.lib')
    local node = lib.get_node_at_cursor()
    local parent_dir = vim.fn.fnamemodify(node.absolute_path, ':h:t')
    nvim_tree.on_keypress('close_node')
    nvim_tree.on_keypress('cd')
    local linenr = vim.fn.searchpos(parent_dir)[1]
    vim.cmd('normal! gg' .. (linenr - 1) .. 'j')
end

local tree_cb = require('nvim-tree.config').nvim_tree_callback
local map_list = {
    { key = '<CR>', cb = ':lua NvimTreeConfig.cd_or_open()<CR>' },
    { key = 'v', cb = tree_cb('vsplit') },
    { key = 's', cb = tree_cb('split') },
    { key = 'F', cb = tree_cb('create') },
    { key = 'D', cb = tree_cb('create') },
    { key = 'd', cb = tree_cb('remove') },
    { key = 'r', cb = tree_cb('rename') },
    { key = 'y', cb = tree_cb('copy') },
    { key = 'u', cb = ':lua NvimTreeConfig.up_dir()<CR>' },
    { key = 'h', cb = ':lua NvimTreeConfig.home()<CR>' },
    { key = 'zc', cb = tree_cb('close_node') },
    { key = 'zo', cb = tree_cb('edit') },
    { key = 'zm', cb = ':lua require("nvim-tree.lib").collapse_all()<CR>' },
    { key = 'o', cb = tree_cb('system_open') },
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
                    arrow_closed = '',
                    arrow_open = '',
                },
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

u.keymap('n', '<Leader>ff', NvimTreeConfig.find_file)
