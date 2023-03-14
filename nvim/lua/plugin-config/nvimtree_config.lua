local node_api = require('nvim-tree.api').node
local tree_api = require('nvim-tree.api').tree
local marks_api = require('nvim-tree.api').marks
local fs_api = require('nvim-tree.api').fs
local u = require('utils')

local Path = require('plenary.path')

local function cd_find_file()
    local find_file_opts = {
        buf = vim.api.nvim_get_current_buf(),
        open = true,
        focus = true,
        update_root = true, -- this ensures lcd changes
    }
    tree_api.find_file(find_file_opts)
    vim.cmd('sleep 3m')

    local node = tree_api.get_node_under_cursor()
    if not node then
        tree_api.open()
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
    find_file_opts.buf = node.name
    tree_api.find_file(find_file_opts)
end

local function cd_or_open()
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

local function up_dir()
    local node = tree_api.get_node_under_cursor()
    local p = Path:new(node.absolute_path):parent()
    local dir = vim.fn.fnamemodify(tostring(p), ':t')

    node_api.navigate.parent()
    tree_api.change_root_to_node()
    vim.cmd('sleep 3m')
    tree_api.find_file({ buf = dir })
end

local function mark_down()
    marks_api.toggle()
    vim.cmd('normal! j')
end

local function telescope(picker, opts)
    opts = opts or {}
    opts.attach_mappings = function(_, map)
        map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
        return true
    end
    _G.TelescopeConfig[picker](opts)
end

local function telescope_preview()
    local node = tree_api.get_node_under_cursor()
    local picker = 'find_files_cwd'
    if node.nodes then
        picker = 'find_dirs'
    end
    _G.TelescopeConfig[picker]({
        layout_strategy = 'cursor',
        layout_config = {
            width = 0.5,
            preview_width = 0.96,
        },
        attach_mappings = function(_, map)
            map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_nvimtree)
            return true
        end,
        default_text = node.name,
    })
end

local function execute(cmd)
    local node = tree_api.get_node_under_cursor()
    vim.fn.jobstart(cmd .. ' ' .. node.absolute_path)
end

local function trash()
    local nodes = marks_api.list()
    local conf_msg = string.format('Trash %s files? [y/n] ', #nodes)
    if next(nodes) == nil then
        local node = tree_api.get_node_under_cursor()
        conf_msg = string.format('Trash %s? [y/n] ', node.name)
        table.insert(nodes, node)
    end
    vim.ui.input({ prompt = conf_msg }, function(input)
        if input == 'y' then
            vim.cmd('redraw!')
            for _, node in ipairs(nodes) do
                fs_api.trash(node)
            end
        end
    end)
    marks_api.clear()
end

local function copy_move(action)
    local fn = fs_api[action]
    if action == 'copy' then
        fn = fn.node
    end

    local nodes = marks_api.list()
    if next(nodes) == nil then
        table.insert(nodes, tree_api.get_node_under_cursor())
    end
    for _, node in ipairs(nodes) do
        fn(node)
    end
end

local function paste()
    fs_api.paste()
    marks_api.clear()
end

local function on_attach(bufnr)
    local map_opts = { buffer = bufnr }
    -- Tree
    u.keymap('n', 'q', tree_api.close, map_opts)
    u.keymap('n', '<ESC>', tree_api.close, map_opts)
    u.keymap('n', '<C-r>', tree_api.reload, map_opts)
    -- Editing
    u.keymap('n', '<CR>', cd_or_open, map_opts)
    u.keymap('n', 'v', node_api.open.vertical, map_opts)
    u.keymap('n', 's', node_api.open.horizontal, map_opts)
    u.keymap('n', 'o', node_api.run.system, map_opts)
    -- Filesystem
    u.keymap('n', 'F', fs_api.create, map_opts)
    u.keymap('n', 'D', fs_api.create, map_opts)
    u.keymap('n', 'd', trash, map_opts)
    u.keymap('n', 'c', function()
        copy_move('copy')
    end, map_opts)
    u.keymap('n', 'm', function()
        copy_move('cut')
    end, map_opts)
    u.keymap('n', 'p', paste, map_opts)
    u.keymap('n', 'r', fs_api.rename, map_opts)
    u.keymap('n', 'y', fs_api.copy.filename, map_opts)
    u.keymap('n', 'Y', fs_api.copy.absolute_path, map_opts)
    u.keymap('n', '<C-o>', tree_api.change_root_to_node, map_opts)
    u.keymap('n', 'u', up_dir, map_opts)
    u.keymap('n', 'h', function()
        tree_api.change_root(vim.env.HOME)
    end, map_opts)
    u.keymap('n', '<A-i>', node_api.show_info_popup, map_opts)
    u.keymap('n', ',th', tree_api.toggle_hidden_filter, map_opts)
    u.keymap('n', ',ti', tree_api.toggle_gitignore_filter, map_opts)
    -- Folds/marks
    u.keymap('n', 'zc', node_api.navigate.parent_close, map_opts)
    u.keymap('n', 'zo', node_api.open.edit, map_opts)
    u.keymap('n', 'zm', tree_api.collapse_all, map_opts)
    u.keymap('n', 'zr', tree_api.expand_all, map_opts)
    u.keymap('n', '<Space>', mark_down, map_opts)
    -- Telescope integration
    u.keymap('n', '<C-t>', function()
        telescope('find_files_cwd')
    end, map_opts)
    u.keymap('n', '<A-t>', function()
        telescope('find_files_cwd', { no_ignore = true })
    end, map_opts)
    u.keymap('n', '<A-c>', function()
        telescope('find_dirs')
    end, map_opts)
    u.keymap('n', '<A-p>', function()
        telescope('parent_dirs')
    end, map_opts)
    u.keymap('n', '<A-z>', function()
        telescope('z_with_tree_preview')
    end, map_opts)
    u.keymap('n', 'b', function()
        telescope('bookmark_dirs')
    end, map_opts)
    u.keymap('n', '<A-v>', telescope_preview, map_opts)
    -- System
    u.keymap('n', ',od', function()
        execute('dragon-drop -a -x')
    end, map_opts)
end

require('nvim-tree').setup({
    disable_netrw = false, -- conflicts with Fugitive's Gbrowse
    on_attach = on_attach,
    view = {
        width = { min = 43, max = 55 },
        number = true,
        relativenumber = true,
    },
    renderer = {
        root_folder_label = function(path)
            return (
                string.format(
                    ' %s/%s',
                    vim.fn.fnamemodify(path, ':h:t'),
                    vim.fn.fnamemodify(path, ':t')
                )
            )
        end,
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
                    ignored = ' ',
                },
            },
        },
    },
    update_focused_file = {
        enable = true,
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
    ui = {
        confirm = {
            remove = true,
            trash = false,
        },
    },
    trash = {
        cmd = 'trash-put',
    },
    git = { ignore = false },
    diagnostics = { enable = false },
})

u.keymap('n', '<Leader>ff', cd_find_file)
