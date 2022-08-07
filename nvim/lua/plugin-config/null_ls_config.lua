local null_ls = require('null-ls')
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
}

null_ls.setup({
    sources = sources,
})
