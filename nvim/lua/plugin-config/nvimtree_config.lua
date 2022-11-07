local node_api = require('nvim-tree.api').node
local tree_api = require('nvim-tree.api').tree
local marks_api = require('nvim-tree.api').marks
local u = require('utils')

local Path = require('plenary.path')

_G.NvimTreeConfig = {}

function NvimTreeConfig.cd_find_file()
    vim.cmd('NvimTreeFindFile')
    vim.cmd('sleep 3m') -- we seem to need this to allow focus
    local node = tree_api.get_node_under_cursor()
    if not node then
        -- If there is not file open the cwd and exit
        vim.cmd('NvimTreeOpen')
        return
    end
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

function NvimTreeConfig.mark_down()
    marks_api.toggle()
    vim.cmd('normal! j')
end

function NvimTreeConfig.telescope(picker)
    _G.TelescopeConfig[picker]({
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
    })
end

function NvimTreeConfig.execute(cmd)
    local node = tree_api.get_node_under_cursor()
    local tmux_cmd =
        string.format('silent! !tmux new-window -d %s %s', cmd, node.absolute_path)
    vim.cmd(tmux_cmd)
end

local tree_cb = require('nvim-tree.config').nvim_tree_callback
local map_list = {
    -- Tree
    { key = 'q', cb = tree_cb('close') },
    { key = '<Esc>', cb = tree_cb('close') },
    { key = '<C-r>', cb = tree_cb('refresh') },
    -- Editing
    { key = '<CR>', cb = ':lua NvimTreeConfig.cd_or_open()<CR>' },
    { key = 'v', cb = tree_cb('vsplit') },
    { key = 's', cb = tree_cb('split') },
    { key = 'o', cb = tree_cb('system_open') },
    { key = '<A-v>', cb = tree_cb('preview') },
    -- Filesystem
    { key = 'F', cb = tree_cb('create') },
    { key = 'D', cb = tree_cb('create') },
    { key = 'd', cb = tree_cb('trash') },
    { key = 'c', cb = tree_cb('copy') },
    { key = 'p', cb = tree_cb('paste') },
    { key = 'r', cb = tree_cb('rename') },
    { key = 'y', cb = tree_cb('copy_name') },
    { key = 'Y', cb = tree_cb('copy_absolute_path') },
    { key = '<C-o>', cb = tree_cb('cd') },
    { key = 'u', cb = ':lua NvimTreeConfig.up_dir()<CR>' },
    {
        key = 'h',
        cb = ':lua require("nvim-tree.api").tree.change_root(vim.env.HOME)<CR>',
    },
    { key = '<A-i>', cb = tree_cb('toggle_file_info') },
    { key = ',th', cb = tree_cb('toggle_dotfiles') },
    -- Folds/marks
    { key = 'zc', cb = tree_cb('close_node') },
    { key = 'zo', cb = tree_cb('edit') },
    { key = 'zm', cb = ':lua require("nvim-tree.api").tree.collapse_all()<CR>' },
    { key = 'zr', cb = ':lua require("nvim-tree.api").tree.expand_all()<CR>' },
    { key = '<Space>', cb = ':lua NvimTreeConfig.mark_down()<CR>' },
    -- Telescope integration
    { key = '<C-t>', cb = ':lua NvimTreeConfig.telescope("find_files_cwd")<CR>' },
    { key = '<A-c>', cb = ':lua NvimTreeConfig.telescope("find_dirs")<CR>' },
    { key = '<A-p>', cb = ':lua NvimTreeConfig.telescope("parent_dirs")<CR>' },
    { key = '<A-z>', cb = ':lua NvimTreeConfig.telescope("z_with_tree_preview")<CR>' },
    { key = 'b', cb = ':lua NvimTreeConfig.telescope("bookmark_dirs")<CR>' },
    -- System
    {
        key = ',od',
        cb = ':lua NvimTreeConfig.execute("dragon-drop -a -x")<CR>',
    },
}

require('nvim-tree').setup({
    disable_netrw = false, -- conflicts with Fugitive's Gbrowse
    view = {
        width = 43,
        number = true,
        relativenumber = true,
        mappings = {
            custom_only = true,
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
        file_popup = {
            open_win_config = {
                border = 'rounded',
            },
        },
    },
    trash = {
        cmd = 'trash-put',
        require_confirm = true,
    },
    git = { ignore = false },
})

u.keymap('n', '<Leader>ff', NvimTreeConfig.cd_find_file)
