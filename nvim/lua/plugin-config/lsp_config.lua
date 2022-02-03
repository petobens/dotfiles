local u = require('utils')
local lsp_buf = vim.lsp.buf

-- Diagnostic
vim.diagnostic.config({
    signs = false,
    virtual_text = {
        prefix = '',
        format = function(diagnostic)
            local icon
            if diagnostic.severity == vim.diagnostic.severity.ERROR then
                icon = ' '
            elseif diagnostic.severity == vim.diagnostic.severity.WARN then
                icon = ' '
            elseif diagnostic.severity == vim.diagnostic.severity.INFO then
                icon = ' '
            else
                icon = ' '
            end
            return string.format('%s %s', icon, diagnostic.message)
        end,
    },
})

-- Mappings
u.keymap('n', '<Leader>jd', lsp_buf.definition)
u.keymap('n', '<Leader>ap', lsp_buf.references)
u.keymap('n', '<Leader>rn', lsp_buf.rename)
u.keymap('n', 'K', lsp_buf.hover)
u.keymap('n', '<Leader>st', lsp_buf.signature_help)
u.keymap('n', '<Leader>fc', lsp_buf.formatting)
u.keymap('v', '<Leader>fc', ':<C-u>call v:lua.vim.lsp.buf.range_formatting()<CR>')
