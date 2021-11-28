require('nvim-treesitter.configs').setup({
    highlight = {
        enable = true,
    },
    ensure_installed = {
        'bash',
        'json',
        'lua',
        'python',
        'vim',
    },
})
