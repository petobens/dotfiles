local dbee = require('dbee')

-- Setup
dbee.setup({
    drawer = {
        disable_help = true,
        window_options = {
            number = true,
            relativenumber = true,
        },
        mappings = {
            { key = '<C-r>', mode = 'n', action = 'refresh' },
            { key = 'o', mode = 'n', action = 'action_1' }, -- open
            { key = 'r', mode = 'n', action = 'action_2' }, -- rename
            { key = 'd', mode = 'n', action = 'action_3' }, --delete/remove
            { key = 'zc', mode = 'n', action = 'collapse' },
            { key = 'zo', mode = 'n', action = 'expand' },
            { key = '<CR>', mode = 'n', action = 'menu_confirm' },
            { key = '<Esc>', mode = 'i', action = 'menu_close' },
        },
        candies = {
            source = {
                icon_highlight = 'dbee_source',
                text_highlight = 'dbee_source',
            },
            connection = {
                icon_highlight = 'dbee_connection',
            },
            note = {
                icon_highlight = 'dbee_note',
            },
        },
    },
    editor = {
        mappings = {
            { key = '<F7>', mode = 'n', action = 'run_file' },
            { key = '<F7>', mode = 'v', action = 'run_selection' },
        },
    },
    result = {
        mappings = {
            { key = '<C-c>', mode = '', action = 'cancel_call' },
        },
    },
    call_log = {
        mappings = {
            { key = '<C-c>', mode = '', action = 'cancel_call' },
        },
    },
    sources = {
        -- Json file entries should have the following form:
        -- "first": {
        --     "id": "1",
        --     "name": "docker-postgres",
        --     "type": "postgres",
        --     "url": "postgres://postgres:passwd@localhost:5432?sslmode=disable"
        -- }
        require('dbee.sources').FileSource:new(
            vim.fs.joinpath(vim.env.HOME, '.config', '.dbee_connections.json')
        ),
    },
    extra_helpers = {
        ['postgres'] = {
            ['Count'] = 'SELECT count(*) FROM {{ .Table }}',
            ['Head'] = 'SELECT * FROM {{ .Table }} LIMIT 10',
        },
    },
})

-- Autocmds
vim.api.nvim_create_autocmd({ 'FileType' }, {
    desc = 'Enable cmp-dbee completion for SQL files',
    group = vim.api.nvim_create_augroup('dbee_sql', { clear = true }),
    pattern = { 'sql' },
    callback = function()
        require('cmp-dbee').setup()
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>db', dbee.toggle, { desc = 'Toggle dbee drawer' })
