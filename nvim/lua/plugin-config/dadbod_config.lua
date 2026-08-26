-- Helpers
local select_line =
    vim.api.nvim_replace_termcodes('<Plug>(DBUI_SelectLine)', true, false, true)

local function toggle_drawer_node(marker)
    if vim.startswith(vim.trim(vim.api.nvim_get_current_line()), marker) then
        vim.api.nvim_feedkeys(select_line, 'm', false)
    end
end

local query_directories = {
    vim.fs.dirname(vim.fn.tempname()),
    vim.fs.normalize(vim.fs.abspath('~/.local/share/db_ui')),
}

local function is_database_workspace_buffer(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if filetype == 'dbui' or filetype == 'dbout' then
        return true
    end

    local path = vim.api.nvim_buf_get_name(bufnr)
    return path ~= ''
        and vim.b[bufnr].dbui_db_key_name ~= nil
        and vim.iter(query_directories):any(function(directory)
            return vim.fs.relpath(directory, path) ~= nil
        end)
end

local function close_database_workspace()
    local buffers = vim.tbl_filter(is_database_workspace_buffer, vim.api.nvim_list_bufs())
    for _, bufnr in ipairs(buffers) do
        if vim.bo[bufnr].modified then
            vim.notify(
                'Save or discard modified queries before closing',
                vim.log.levels.WARN
            )
            return
        end
    end

    for _, bufnr in ipairs(buffers) do
        vim.api.nvim_buf_delete(bufnr, {})
    end
end

-- Connections
local connections_path = vim.fs.joinpath(vim.env.HOME, '.config', '.db_connections.json')
local connections_file = io.open(connections_path, 'r')

if connections_file then
    local connections = {}
    for _, connection in pairs(vim.json.decode(connections_file:read('*a'))) do
        connections[#connections + 1] = {
            name = connection.name,
            url = connection.url,
        }
    end
    connections_file:close()
    table.sort(connections, function(a, b)
        return a.name < b.name
    end)
    vim.g.dbs = connections
end

-- Setup
vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_force_echo_notifications = 1
vim.g.db_ui_save_location = query_directories[2]
vim.g.db_ui_hide_schemas = {
    '^information_schema$',
    '^pg_catalog$',
    '^pg_toast.*$',
}
vim.g.db_ui_show_help = 0
vim.g.db_ui_table_helpers = {
    postgresql = {
        Count = 'SELECT count(*) FROM {optional_schema}"{table}" -- noqa: RF06',
        Head = 'SELECT * FROM {optional_schema}"{table}" LIMIT 10 -- noqa: RF06, AM09',
    },
}
vim.g.db_ui_use_nerd_fonts = 1

-- Buffer mappings
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'dbui',
    desc = 'Configure Dadbod drawer mappings',
    callback = function(event)
        vim.keymap.set('n', 'zo', function()
            toggle_drawer_node('▸')
        end, { buffer = event.buf, desc = 'Open database node' })
        vim.keymap.set('n', 'zc', function()
            toggle_drawer_node('▾')
        end, { buffer = event.buf, desc = 'Close database node' })
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'sql',
    desc = 'Configure Dadbod query mappings',
    callback = function(event)
        vim.keymap.set('n', '<Leader>da', vim.cmd.DBUIFindBuffer, {
            buffer = event.buf,
            desc = '[D]atabase [a]ttach: query buffer',
        })
        vim.keymap.set(
            { 'n', 'x' },
            '<F7>',
            '<Plug>(DBUI_ExecuteQuery)',
            { buffer = event.buf, desc = 'Execute database query' }
        )
        vim.keymap.set(
            'i',
            '<F7>',
            '<Esc><Cmd>write<CR><Plug>(DBUI_ExecuteQuery)',
            { buffer = event.buf, desc = 'Save and execute database query' }
        )
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'dbout',
    desc = 'Configure Dadbod result mappings',
    callback = function(event)
        vim.keymap.set('n', 'q', function()
            vim.api.nvim_buf_delete(event.buf, {})
        end, { buffer = event.buf, desc = 'Close database results' })
    end,
})

-- Global mappings
vim.keymap.set('n', '<Leader>db', vim.cmd.DBUIToggle, {
    desc = '[D]ata[b]ase drawer: toggle',
})
vim.keymap.set('n', '<Leader>dk', close_database_workspace, {
    desc = '[D]atabase workspace: [k]ill',
})
