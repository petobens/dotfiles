require('noice').setup({
    cmdline = { enabled = false },
    messages = { enabled = false },
    popupmenu = { enabled = false },
    notify = { enabled = false },
    lsp = {
        progress = { enabled = false },
        override = {
            -- Make cmp and other plugins use treesitter markdown highlighting
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
            ['cmp.entry.get_documentation'] = true,
        },
        signature = {
            enabled = true,
            auto_open = {
                enabled = false, -- to avoid conflicts with cmp-lsp-signature
            },
        },
    },
})
