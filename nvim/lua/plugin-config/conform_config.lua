local conform = require('conform')
local u = require('utils')

-- Global options
vim.o.formatexpr = [[v:lua.require('conform').formatexpr()]]

-- Formatters args
conform.formatters.jq = { args = { '--indent', '4' } }
conform.formatters.stylua =
    { prepend_args = { '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml' } }
conform.formatters.isort =
    { prepend_args = { '--settings-file=' .. vim.env.HOME .. '/.isort.cfg' } }
conform.formatters.black =
    { prepend_args = { '--config=' .. vim.env.HOME .. '/.config/.black.toml' } }
conform.formatters.shfmt = { prepend_args = { '-i', '4', '-ci', '-sr' } }
conform.formatters.taplo =
    { args = { 'format', '--config=' .. vim.env.HOME .. '/taplo.toml', '-' } }

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
    formatters = custom_formatters,
    formatters_by_ft = {
        ['_'] = { 'trim_whitespace' },
        json = { 'jq' },
        lua = { 'stylua' },
        markdown = { 'prettierd' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        sql = { 'sqlfluff' },
        toml = { 'taplo' },
        yaml = { 'prettierd' },
    },
    format_on_save = function(bufnr)
        local ignore_filetypes = { 'markdown' }
        if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
            return
        end
        return { timeout_ms = 700, quiet = true, lsp_fallback = false }
    end,
    notify_on_error = false,
})

-- Mappings
u.keymap({ 'n', 'v' }, '<Leader>fc', function()
    conform.format({ async = true, lsp_fallback = false })
end)
