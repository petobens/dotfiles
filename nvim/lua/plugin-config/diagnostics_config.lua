local u = require('utils')

-- Setup
vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    underline = false,
    signs = true,
    float = { source = true },
    virtual_text = {
        spacing = 0,
        source = 'if_many',
        prefix = '',
        format = function(diagnostic)
            local icon
            if diagnostic.severity == vim.diagnostic.severity.ERROR then
                icon = u.icons.error
            elseif diagnostic.severity == vim.diagnostic.severity.WARN then
                icon = u.icons.warning
            elseif diagnostic.severity == vim.diagnostic.severity.INFO then
                icon = u.icons.info
            else
                icon = u.icons.hint
            end
            return string.format('%s %s', icon, diagnostic.message)
        end,
        suffix = function(diagnostic)
            return diagnostic.code and (' [%s]'):format(diagnostic.code) or ''
        end,
    },
})

-- Sign icons
local signs = {
    Error = u.icons.error,
    Warn = u.icons.warning,
    Info = u.icons.info,
    Hint = u.icons.hint,
}
for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = nil })
end

-- Toggle function
local diagnostics_active = true
local toggle_buffer_diagnostics = function()
    diagnostics_active = not diagnostics_active
    if diagnostics_active then
        vim.diagnostic.show(nil, 0)
    else
        vim.diagnostic.hide(nil, 0)
    end
end

-- Mappings
u.keymap('n', '<Leader>fd', vim.diagnostic.open_float)
u.keymap('n', '<Leader>ld', function()
    local win_id = vim.fn.win_getid()
    vim.diagnostic.setloclist({
        title = string.format(
            'Diagnostics: %s',
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
        ),
    })
    vim.fn.win_gotoid(win_id)
end)
u.keymap('n', '<Leader>dt', toggle_buffer_diagnostics)
u.keymap('n', '[d', function()
    vim.diagnostic.goto_prev({ float = false })
end)
u.keymap('n', ']d', function()
    vim.diagnostic.goto_next({ float = false })
end)
