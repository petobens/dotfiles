local u = require('utils')

-- Dadbod-UI options
vim.g.db_ui_winwidth = 40
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_show_help = 0
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_use_nvim_notify = 1
vim.g.db_ui_icons = {
    add_connection = '󰆺',
    connection_error = '✕',
    connection_ok = '✓',
    collapsed = {
        db = u.icons.fold_close .. ' ',
        saved_queries = u.icons.fold_close .. ' ',
        buffers = u.icons.fold_close .. ' ',
        schemas = u.icons.fold_close .. ' ',
        schema = u.icons.fold_close .. ' ',
        tables = u.icons.fold_close .. ' 󰓫',
        table = u.icons.fold_close .. ' 󰓫',
    },
    expanded = {
        db = u.icons.fold_open .. ' ',
        saved_queries = u.icons.fold_open .. ' ',
        buffers = u.icons.fold_open .. ' ',
        schemas = u.icons.fold_open .. ' ',
        schema = u.icons.fold_open .. ' ',
        tables = u.icons.fold_open .. ' 󰓫',
        table = u.icons.fold_open .. ' 󰓫',
    },
    new_query = '',
    saved_query = '',
    tables = '~',
    buffers = '',
}
vim.g.db_ui_table_helpers = {
    postgresql = {
        Count = 'SELECT count(*) FROM {optional_schema}{table}',
        Describe = [[\d {optional_schema}{table}]],
        List = 'SELECT * FROM {optional_schema}{table} LIMIT 10',
        ['Show Tables'] = [[\dt]],
    },
}
vim.g.db_ui_hide_schemas = {
    -- Postgres
    'information_schema',
    'pg_catalog',
    'pg_toast',
}

-- Read db connections from a YAML file with entries like `<db_name>: <uri>`
local function read_dadbod_conns(f)
    local conn_file = vim.fn.expand(f)
    if vim.fn.filereadable(conn_file) == 0 then
        return {}
    end

    local dbs = {}
    for _, i in pairs(vim.fn.readfile(conn_file)) do
        if not string.match(i, '^#') then -- ignore commented lines
            if string.match(i, ':%s') then
                local conn = vim.fn.split(i, ':\\s')
                dbs = vim.tbl_extend('keep', dbs, { [conn[1]] = conn[2] })
            end
        end
    end
    return dbs
end
vim.g.dbs = read_dadbod_conns('~/.config/.dadbod_conns.yaml')

-- Mappings and ft settings
vim.keymap.set('n', '<Leader>db', '<Cmd>DBUIToggle<CR>')
vim.api.nvim_create_autocmd({ 'User' }, {
    group = vim.api.nvim_create_augroup('dbui', { clear = true }),
    pattern = { 'DBUIOpened' },
    callback = function(e)
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
        vim.opt_local.shiftwidth = 2

        local dbui_maps = { buffer = e.buf, remap = true }
        vim.keymap.set('n', '<CR>', '<plug>(DBUI_SelectLine)', dbui_maps)
        vim.keymap.set('n', 'v', '<plug>(DBUI_SelectLineVsplit)', dbui_maps)
        vim.keymap.set('n', 'zo', '<plug>(DBUI_SelectLine)', dbui_maps)
        vim.keymap.set('n', 'zc', '<plug>(DBUI_SelectLine)', dbui_maps)
        vim.keymap.set('n', '<C-r>', '<plug>(DBUI_Redraw)', dbui_maps)
        vim.keymap.set('n', '<C-j>', '<C-W>j', dbui_maps)
    end,
})
vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = vim.api.nvim_create_augroup('dbui_sql', { clear = true }),
    pattern = { 'sql' },
    callback = function(e)
        require('cmp').setup.buffer({
            sources = {
                { name = 'vim-dadbod-completion' },
                { name = 'tmux' },
                { name = 'buffer' },
                { name = 'luasnip' },
            },
        })

        local dbui_maps = { buffer = e.buf, remap = true }
        vim.keymap.set('n', '<Leader>rf', '<plug>(DBUI_ExecuteQuery)', dbui_maps)
        vim.keymap.set('n', '<F7>', '<plug>(DBUI_ExecuteQuery)', dbui_maps)
        vim.keymap.set('n', '<Leader>qs', '<plug>(DBUI_SaveQuery)', dbui_maps)
        vim.keymap.set('n', '<Leader>qr', '<Cmd>DBUIRenameBuffer<CR>', dbui_maps)
        vim.keymap.set('n', '<Leader>qf', '<Cmd>DBUIFindBuffer<CR>', dbui_maps)
        vim.keymap.set('n', '<Leader>qc', function()
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':e') == 'dbout' then
                    vim.cmd('bwipeout ' .. b)
                end
            end
        end)
    end,
})
