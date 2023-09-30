local u = require('utils')

local conform = require('conform')
local conform_utils = require('conform.util')
local formatters = require('conform.formatters')

-- Global options
vim.o.formatexpr = [[v:lua.require('conform').formatexpr()]]

-- Formatters args
conform_utils.add_formatter_args(formatters.jq, { '--indent', '4' })
conform_utils.add_formatter_args(
    formatters.stylua,
    { '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml' }
)
conform_utils.add_formatter_args(
    formatters.isort,
    { '--settings-file=' .. vim.env.HOME .. '/.isort.cfg' }
)
conform_utils.add_formatter_args(
    formatters.black,
    { '--config=' .. vim.env.HOME .. '/.config/.black.toml' }
)
conform_utils.add_formatter_args(formatters.shfmt, { '-i', '4', '-ci', '-sr' })
formatters.taplo.args = { 'format', '--config=' .. vim.env.HOME .. '/taplo.toml', '-' }

-- Custom Formatters
local custom_formatters = {
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
}

-- Setup
conform.setup({
    format_on_save = {
        timeout_ms = 700,
        quiet = true,
        lsp_fallback = false,
    },
    notify_on_error = false,
    formatters = custom_formatters,
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

-- Mappings
u.keymap({ 'n', 'v' }, '<Leader>fc', function()
    conform.format({ async = true, lsp_fallback = false })
end)
