local nvimtree_api = require('nvim-tree.api')
local node_api = nvimtree_api.node
local tree_api = nvimtree_api.tree
local marks_api = nvimtree_api.marks
local fs_api = nvimtree_api.fs
local Path = require('plenary.path')
local u = require('utils')

-- Helpers
local function cd_find_file()
    local find_file_opts = {
        buf = vim.api.nvim_get_current_buf(),
        open = true,
        focus = true,
        update_root = true, -- this ensures lcd changes
    }
    tree_api.find_file(find_file_opts)
    vim.cmd.sleep('3m')

    local node = tree_api.get_node_under_cursor()
    if not node then
        tree_api.open()
        return
    end

    -- Get inside the directory instead of unfolding the tree
    node_api.navigate.parent()
    local parent_node = tree_api.get_node_under_cursor()
    if parent_node.name == '..' then
        tree_api.collapse_all()
    else
        tree_api.change_root_to_node()
        node_api.navigate.sibling.first()
    end
    tree_api.find_file({ buf = find_file_opts.buf })
end

local function cd_or_open()
    local node = tree_api.get_node_under_cursor()
    if node then
        if node.nodes then
            tree_api.change_root_to_node()
            node_api.navigate.sibling.first() -- to center
            vim.cmd.normal({ args = { 'h' }, bang = true }) -- to avoid moving cursor
        else
            node_api.open.edit()
        end
    end
end

local function up_dir()
    local node = tree_api.get_node_under_cursor()
    local p = Path:new(node.absolute_path):parent()
    local dir = vim.fs.basename(tostring(p))

    node_api.navigate.parent()
    tree_api.change_root_to_node()
    vim.cmd.sleep('3m')
    tree_api.find_file({ buf = dir })
end

local function mark_down()
    marks_api.toggle()
    vim.cmd.normal({ args = { 'j' }, bang = true })
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
    table.insert(cmd, node.absolute_path)
    vim.system(cmd)
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
            vim.cmd.redraw()
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

local function add_codecompanion_context()
    local files = {}
    local nodes = marks_api.list()
    if next(nodes) == nil then
        local node = tree_api.get_node_under_cursor()
        table.insert(files, node.absolute_path)
    else
        for _, node in ipairs(nodes) do
            table.insert(files, node.absolute_path)
        end
    end
    _G.CodeCompanionConfig.add_context(files)
    vim.cmd.NvimTreeClose()
end

-- Cycle sorting
-- See https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#cycle-sort-methods
local SORT_METHODS = {
    'name',
    'modification_time',
}
local sort_current = 1

local cycle_sort = function()
    if sort_current >= #SORT_METHODS then
        sort_current = 1
    else
        sort_current = sort_current + 1
    end
    tree_api.reload()
end

local sort_by = function()
    return SORT_METHODS[sort_current]
end

-- Buffer mappings
local function on_attach(bufnr)
    -- Tree
    vim.keymap.set('n', 'q', tree_api.close, { buffer = bufnr, desc = 'Close NvimTree' })
    vim.keymap.set(
        'n',
        '<ESC>',
        tree_api.close,
        { buffer = bufnr, desc = 'Close NvimTree' }
    )
    vim.keymap.set(
        'n',
        '<C-r>',
        tree_api.reload,
        { buffer = bufnr, desc = 'Reload tree' }
    )
    vim.keymap.set('n', 'T', cycle_sort, { buffer = bufnr, desc = 'Cycle sort method' })

    -- Editing
    vim.keymap.set(
        'n',
        '<CR>',
        cd_or_open,
        { buffer = bufnr, desc = 'Open or cd into node' }
    )
    vim.keymap.set(
        'n',
        'v',
        node_api.open.vertical,
        { buffer = bufnr, desc = 'Open in vertical split' }
    )
    vim.keymap.set(
        'n',
        's',
        node_api.open.horizontal,
        { buffer = bufnr, desc = 'Open in horizontal split' }
    )
    vim.keymap.set(
        'n',
        'o',
        node_api.run.system,
        { buffer = bufnr, desc = 'Open with system handler' }
    )

    -- Filesystem
    vim.keymap.set('n', 'F', fs_api.create, { buffer = bufnr, desc = 'Create file' })
    vim.keymap.set('n', 'D', fs_api.create, { buffer = bufnr, desc = 'Create directory' })
    vim.keymap.set('n', 'd', trash, { buffer = bufnr, desc = 'Trash/delete node(s)' })
    vim.keymap.set('n', 'c', function()
        copy_move('copy')
    end, { buffer = bufnr, desc = 'Copy node(s)' })
    vim.keymap.set('n', 'm', function()
        copy_move('cut')
    end, { buffer = bufnr, desc = 'Move (cut) node(s)' })
    vim.keymap.set('n', 'p', paste, { buffer = bufnr, desc = 'Paste node(s)' })
    vim.keymap.set('n', 'r', fs_api.rename, { buffer = bufnr, desc = 'Rename node' })
    vim.keymap.set(
        'n',
        'y',
        fs_api.copy.filename,
        { buffer = bufnr, desc = 'Copy filename' }
    )
    vim.keymap.set(
        'n',
        'Y',
        fs_api.copy.absolute_path,
        { buffer = bufnr, desc = 'Copy absolute path' }
    )
    vim.keymap.set(
        'n',
        '<C-o>',
        tree_api.change_root_to_node,
        { buffer = bufnr, desc = 'Change root to node' }
    )
    vim.keymap.set('n', 'u', up_dir, { buffer = bufnr, desc = 'Go up one directory' })
    vim.keymap.set('n', 'h', function()
        tree_api.change_root(vim.env.HOME)
    end, { buffer = bufnr, desc = 'Change root to $HOME' })
    vim.keymap.set(
        'n',
        '<A-i>',
        node_api.show_info_popup,
        { buffer = bufnr, desc = 'Show info popup' }
    )
    vim.keymap.set(
        'n',
        ',th',
        tree_api.toggle_hidden_filter,
        { buffer = bufnr, desc = 'Toggle hidden files' }
    )
    vim.keymap.set(
        'n',
        ',ti',
        tree_api.toggle_gitignore_filter,
        { buffer = bufnr, desc = 'Toggle gitignore filter' }
    )

    -- Folds/marks
    vim.keymap.set(
        'n',
        'zc',
        node_api.navigate.parent_close,
        { buffer = bufnr, desc = 'Close parent fold' }
    )
    vim.keymap.set(
        'n',
        'zo',
        node_api.open.edit,
        { buffer = bufnr, desc = 'Open node (edit)' }
    )
    vim.keymap.set(
        'n',
        'zm',
        tree_api.collapse_all,
        { buffer = bufnr, desc = 'Collapse all' }
    )
    vim.keymap.set(
        'n',
        'zr',
        tree_api.expand_all,
        { buffer = bufnr, desc = 'Expand all' }
    )
    vim.keymap.set(
        'n',
        '<Space>',
        mark_down,
        { buffer = bufnr, desc = 'Mark/unmark node' }
    )

    -- Telescope integration
    vim.keymap.set('n', '<C-t>', function()
        telescope('find_files_cwd')
    end, { buffer = bufnr, desc = 'Telescope: find files in cwd' })
    vim.keymap.set('n', '<A-t>', function()
        telescope('find_files_cwd', { no_ignore = true })
    end, { buffer = bufnr, desc = 'Telescope: find all files in cwd' })
    vim.keymap.set('n', '<A-c>', function()
        telescope('find_dirs')
    end, { buffer = bufnr, desc = 'Telescope: find directories' })
    vim.keymap.set('n', '<A-p>', function()
        telescope('parent_dirs')
    end, { buffer = bufnr, desc = 'Telescope: find parent directories' })
    vim.keymap.set('n', '<A-z>', function()
        telescope('z_with_tree_preview')
    end, { buffer = bufnr, desc = 'Telescope: zoxide with tree preview' })
    vim.keymap.set('n', 'b', function()
        telescope('bookmark_dirs')
    end, { buffer = bufnr, desc = 'Telescope: bookmark directories' })
    vim.keymap.set(
        'n',
        '<A-v>',
        telescope_preview,
        { buffer = bufnr, desc = 'Telescope: preview node' }
    )

    -- System
    vim.keymap.set('n', ',od', function()
        execute({ 'dragon-drop', '-a', '-x' })
    end, { buffer = bufnr, desc = 'Drag and drop node(s) externally' })

    --- CodeCompanion
    vim.keymap.set(
        'n',
        '<A-a>',
        add_codecompanion_context,
        { buffer = bufnr, desc = 'Add marked files as CodeCompanion context' }
    )
end

require('nvim-tree').setup({
    disable_netrw = false, -- conflicts with Fugitive's Gbrowse
    on_attach = on_attach,
    sort = { sorter = sort_by },
    view = {
        width = { min = 43, max = 55 },
        number = true,
        relativenumber = true,
    },
    renderer = {
        root_folder_label = function(path)
            return ' '
                .. vim.fs.joinpath(
                    vim.fs.basename(vim.fs.dirname(path)),
                    vim.fs.basename(path)
                )
        end,
        icons = {
            git_placement = 'after',
            glyphs = {
                folder = {
                    arrow_open = u.icons.fold_open,
                    arrow_closed = u.icons.fold_close,
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

-- Autocmds
vim.api.nvim_create_autocmd('BufEnter', {
    desc = 'Winfix NvimTree buffer window',
    callback = function()
        if vim.list_contains({ 'NvimTree' }, vim.bo.filetype) then
            vim.wo.winfixbuf = true
        end
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>ff', cd_find_file, { desc = 'Find file in NvimTree' })
vim.keymap.set('n', '<Leader>fq', vim.cmd.NvimTreeClose, { desc = 'Close/quit NvimTree' })
