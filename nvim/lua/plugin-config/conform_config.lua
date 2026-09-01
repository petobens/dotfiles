local conform = require('conform')

-- Global options
vim.o.formatexpr = conform.formatexpr

-- Formatters args
conform.formatters.jq = { args = { '--indent', '4' } }
conform.formatters.stylua = {
    prepend_args = {
        '--config-path=' .. vim.fs.joinpath(vim.env.HOME, '.config', 'stylua.toml'),
    },
}
conform.formatters.shfmt = { prepend_args = { '-i', '4', '-ci', '-sr' } }
conform.formatters.oxfmt = {
    args = {
        '--config=' .. vim.fs.joinpath(vim.env.HOME, '.oxfmtrc.json'),
        '$FILENAME',
    },
    -- Pandoc output contains raw TeX that oxfmt cannot preserve
    condition = function(_, ctx)
        local markdown = vim.api.nvim_buf_get_name(ctx.buf)
        local source = markdown:gsub('%.md$', '.typ')
        return source == markdown or not vim.uv.fs_stat(source)
    end,
    stdin = false,
}
conform.formatters.typstyle = {
    prepend_args = { '--line-width', '80', '--wrap-text=fill' },
}

-- Setup
conform.setup({
    formatters_by_ft = {
        ['_'] = { 'trim_whitespace' },
        css = { 'oxfmt' },
        fish = { 'fish_indent' },
        ghaction = { 'oxfmt' },
        html = { 'oxfmt' },
        javascript = { 'oxfmt' },
        json = { 'jq' },
        jsonc = { 'oxfmt' },
        lua = { 'stylua' },
        markdown = { 'oxfmt', 'injected', 'trim_whitespace' },
        python = { 'ruff_fix', 'ruff_format' },
        query = { 'format-queries' },
        sh = { 'shfmt' },
        sql = { 'sqlfluff' },
        toml = { 'tombi' },
        typst = { 'typstyle' },
        yaml = { 'oxfmt' },
    },
    format_on_save = function(bufnr)
        local format_options = { timeout_ms = 700, quiet = true, lsp_format = 'never' }
        if vim.bo[bufnr].filetype == 'sql' then
            format_options.timeout_ms = 1000 -- Sqlfluff is slow
        end
        return format_options
    end,
    notify_on_error = false,
})

-- Mappings
vim.keymap.set({ 'n', 'v' }, '<Leader>fc', function()
    conform.format({ async = true, lsp_format = 'never' })
end, { desc = '[F]ormat [c]ode with Conform' })
