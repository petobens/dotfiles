local u = require('utils')

-- Global options
vim.o.formatexpr = [[v:lua.require('conform').formatexpr()]]

-- Setup
require('conform').setup({
    format_on_save = {
        timeout_ms = 200,
        lsp_fallback = false,
    },
    notify_on_error = false,
    formatters = {
        sqlfluff = {
            command = 'sqlfluff',
            args = {
                'fix',
                '--disable-progress-bar',
                '-f',
                '-n',
                '-',
            },
            stdin = true,
        },
    },
    formatters_by_ft = {
        ['_'] = { 'trim_whitespace' },
        json = { 'jq' },
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        sql = { 'sqlfluff' },
        toml = { 'taplo' },
        yaml = { 'prettierd' },
    },
})

-- Formatters args
local cu = require('conform.util')
local formatters = require('conform.formatters')
--- Json
cu.add_formatter_args(formatters.jq, { '--indent', '4' })
--- Lua
cu.add_formatter_args(
    formatters.stylua,
    { '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml' }
)
--- Python
cu.add_formatter_args(
    formatters.isort,
    { '--settings-file=' .. vim.env.HOME .. '/.isort.cfg' }
)
cu.add_formatter_args(
    formatters.black,
    { '--config=' .. vim.env.HOME .. '/.config/.black.toml' }
)
--- sh
cu.add_formatter_args(formatters.shfmt, { '-i', '4', '-ci', '-sr' })
--- TOML
formatters.taplo.args = { 'format', '--config=' .. vim.env.HOME .. '/taplo.toml', '-' }

-- Maps
u.keymap({ 'n', 'v' }, '<Leader>fc', function()
    require('conform').format({ async = true, lsp_fallback = false })
end)
