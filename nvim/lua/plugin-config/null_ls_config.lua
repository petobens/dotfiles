local null_ls = require('null-ls')
local diagnostics = null_ls.builtins.diagnostics
local formatting = null_ls.builtins.formatting

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
    diagnostics.pylint,
}

null_ls.setup({
    sources = sources,
    debug = false,
    on_attach = function(client)
        -- Don't use null-ls for (cmp-lsp) compeltion
        client.server_capabilities.completionProvider = false
    end,
})
