require('noice').setup({
    presets = {
        lsp_doc_border = true,
    },
    cmdline = { enabled = false },
    messages = { enabled = false },
    popupmenu = { enabled = false },
    notify = { enabled = false },
    lsp = {
        -- Hover, signature and messages are enabled by default (and
        -- override/replace cmp config)
        progress = { enabled = false },
        override = {
            -- Make cmp and other plugins use treesitter markdown highlighting
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
            ['cmp.entry.get_documentation'] = true,
        },
    },
})

-- Mappings (mostly for scrolling signatures)
vim.keymap.set({ 'n', 'i', 's' }, '<A-j>', function()
    if not require('noice.lsp').scroll(4) then
        return '<A-j>'
    else
        require('noice.lsp').scroll(4)
    end
end)

vim.keymap.set({ 'n', 'i', 's' }, '<A-k>', function()
    if not require('noice.lsp').scroll(-4) then
        return '<A-k>'
    else
        require('noice.lsp').scroll(-4)
    end
end)
