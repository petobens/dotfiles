require('mason').setup({
    ui = { backdrop = 100 },
})

require('mason-tool-installer').setup({
    auto_update = true,
    debounce_hours = 24,
    ensure_installed = {
        'basedpyright',
        'bash-language-server',
        'lua-language-server',
        'marksman',
        'texlab',
        'tinymist',
    },
})

vim.keymap.set('n', '<Leader>ms', vim.cmd.Mason, { desc = '[M]a[s]on UI: open' })
