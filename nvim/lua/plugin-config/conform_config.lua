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
        markdown = { 'prettierd', 'injected' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        sql = { 'sqlfluff' },
        toml = { 'taplo' },
        yaml = { 'prettierd' },
    },
    format_on_save = function(bufnr)
        local format_options = { timeout_ms = 700, quiet = true, lsp_fallback = false }
        if vim.bo[bufnr].filetype == 'markdown' then
            -- Don't run prettierd automatically
            format_options = vim.tbl_extend(
                'keep',
                format_options,
                { formatters = { 'injected', 'trim_whitespace' } }
            )
        end
        if vim.bo[bufnr].filetype == 'sql' then
            -- Sqlfluff is slow
            format_options.timeout_ms = 1000
        end
        return format_options
    end,
    notify_on_error = false,
})

-- Mappings
u.keymap({ 'n', 'v' }, '<Leader>fc', function()
    conform.format({ async = true, lsp_fallback = false })
end)
