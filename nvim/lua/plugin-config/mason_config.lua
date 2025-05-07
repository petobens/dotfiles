require('mason').setup({
    ui = { border = 'rounded' },
})

require('mason-tool-installer').setup({
    auto_update = true,
    ensure_installed = {
        'basedpyright',
        'bash-language-server',
        'lua-language-server',
        'marksman',
        'texlab',
    },
})

vim.keymap.set('n', '<Leader>ms', '<Cmd>Mason<CR>')
