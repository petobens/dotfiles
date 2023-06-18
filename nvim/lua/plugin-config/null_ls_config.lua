local null_ls = require('null-ls')
local diagnostics = null_ls.builtins.diagnostics
local formatting = null_ls.builtins.formatting

-- Ruff settings
local ruff_severities = {
    ['E'] = vim.diagnostic.severity.ERROR,
    ['F8'] = vim.diagnostic.severity.ERROR,
    ['F'] = vim.diagnostic.severity.WARN,
    ['W'] = vim.diagnostic.severity.WARN,
    ['D'] = vim.diagnostic.severity.INFO,
    ['B'] = vim.diagnostic.severity.INFO,
}
local ruff = diagnostics.ruff.with({
    diagnostics_postprocess = function(diagnostic)
        local code = string.sub(diagnostic.code, 1, 2)
        if code ~= 'F8' then
            code = string.sub(code, 1, 1)
        end
        local new_severity = ruff_severities[code]
        if new_severity then
            diagnostic.severity = new_severity
        end
    end,
})

-- Sources configuration
local sources = {
    -- Bash
    formatting.shfmt.with({
        extra_args = { '-i', '4', '-ci', '-sr' },
    }),
    -- Lua
    formatting.stylua.with({
        extra_args = {
            '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml',
        },
    }),
    -- Python (note that formatters will run in the defined order)
    formatting.isort.with({
        extra_args = {
            '--settings-file=' .. vim.env.HOME .. '/.isort.cfg',
        },
    }),
    formatting.black.with({
        extra_args = {
            '--config=' .. vim.env.HOME .. '/.config/.black.toml',
        },
    }),
    -- pylint,mypy and ruff search for the correct config file by default
    diagnostics.pylint,
    diagnostics.mypy,
    ruff,
}

-- Actual setup
null_ls.setup({
    sources = sources,
    debug = false,
    should_attach = function(bufnr)
        -- Don't attach to fugitive git diff buffers
        return not vim.api.nvim_buf_get_name(bufnr):match('^fugitive://')
    end,
    on_attach = function(client)
        -- Don't use null-ls for (cmp-lsp) compeltion
        client.server_capabilities.completionProvider = false
    end,
})
