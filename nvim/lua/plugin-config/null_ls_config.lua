local null_ls = require('null-ls')
local formatting = null_ls.builtins.formatting

null_ls.setup({
    sources = {
        formatting.stylua.with({
            extra_args = {
                '--config-path=/home/pedro/git-repos/private/dotfiles/config/stylua/stylua.toml',
            },
        }),
        on_attach = function(client)
            if client.resolved_capabilities.document_formatting then
                vim.cmd(
                    [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]
                )
            end
        end,
    },
})
