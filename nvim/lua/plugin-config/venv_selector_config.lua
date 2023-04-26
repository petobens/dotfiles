local u = require('utils')

require('venv-selector').setup({
    search = false,
})

-- Mappings
vim.api.nvim_create_autocmd({ 'Filetype' }, {
    group = vim.api.nvim_create_augroup('pyvenv', { clear = true }),
    pattern = { 'python' },
    callback = function()
        u.keymap('n', '<Leader>tv', ':VenvSelect<CR>', { buffer = true })
    end,
})
