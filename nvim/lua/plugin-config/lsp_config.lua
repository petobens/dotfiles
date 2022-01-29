local u = require('utils')
local lsp_buf = vim.lsp.buf

-- Diagnostic
vim.diagnostic.config({
    signs = false,
})

-- Mappings
u.keymap('n', '<Leader>jd', lsp_buf.definition)
u.keymap('n', '<Leader>ap', lsp_buf.references)
u.keymap('n', '<Leader>rn', lsp_buf.rename)
u.keymap('n', 'K', lsp_buf.hover)
u.keymap('n', '<Leader>st', lsp_buf.signature_help)
u.keymap('n', '<Leader>fc', lsp_buf.formatting)
u.keymap('v', '<Leader>fc', ':<C-u>call v:lua.vim.lsp.buf.range_formatting()<CR>')
