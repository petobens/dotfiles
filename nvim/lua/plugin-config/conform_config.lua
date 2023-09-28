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
    formatters_by_ft = {
        ['_'] = { 'trim_whitespace' },
        json = { 'jq' },
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        -- TODO: missing sqlfluff
        -- sql = {}
        toml = { 'taplo' },
        yaml = { 'prettierd' },
    },
})

-- Formatter args
local utils = require('conform.util')
---- Json
utils.add_formatter_args(require('conform.formatters.jq'), { '--indent', '4' })
---- Lua
utils.add_formatter_args(
    require('conform.formatters.stylua'),
    { '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml' }
)
---- Python
utils.add_formatter_args(
    require('conform.formatters.isort'),
    { '--settings-file=' .. vim.env.HOME .. '/.isort.cfg' }
)
utils.add_formatter_args(
    require('conform.formatters.black'),
    { '--config=' .. vim.env.HOME .. '/.config/.black.toml' }
)
---- sh
utils.add_formatter_args(require('conform.formatters.shfmt'), { '-i', '4', '-ci', '-sr' })
---- TOML
require('conform.formatters.taplo').args =
    { 'format', '--config=' .. vim.env.HOME .. '/taplo.toml', '-' }

-- Maps
-- FIXME: Visual formatting doesn't seem to be working
u.keymap({ 'n', 'v' }, '<Leader>fc', function()
    require('conform').format({ async = true, lsp_fallback = false })
end)
