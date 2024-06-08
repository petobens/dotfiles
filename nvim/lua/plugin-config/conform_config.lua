local conform = require('conform')

-- Global options
vim.o.formatexpr = [[v:lua.require('conform').formatexpr()]]

-- Formatters args
conform.formatters.jq = { args = { '--indent', '4' } }
conform.formatters.stylua =
    { prepend_args = { '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml' } }
conform.formatters.shfmt = { prepend_args = { '-i', '4', '-ci', '-sr' } }
conform.formatters.taplo =
    { args = { 'format', '--config=' .. vim.env.HOME .. '/taplo.toml', '-' } }

-- Setup
conform.setup({
    formatters_by_ft = {
        ['_'] = { 'trim_whitespace' },
        ghaction = { 'prettierd' },
        json = { 'jq' },
        lua = { 'stylua' },
        markdown = { 'prettierd', 'injected' },
        python = { 'ruff_fix', 'ruff_format' },
        query = { 'format-queries' },
        sh = { 'shfmt' },
        sql = { 'sqlfluff' },
        toml = { 'taplo' },
        yaml = { 'prettierd' },
    },
    format_on_save = function(bufnr)
        local format_options = { timeout_ms = 700, quiet = true, lsp_fallback = false }
        if vim.bo[bufnr].filetype == 'markdown' then
            -- Don't run prettierd automatically until new line bug is fixed
            -- https://github.com/prettier/prettier/issues/8004
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
vim.keymap.set({ 'n', 'v' }, '<Leader>fc', function()
    conform.format({ async = true, lsp_fallback = false })
end)
