local u = require('utils')

-- Helpers
local function not_in(str, substr)
    return substr and not string.find(str, substr, 1, true)
end

local function count_diagnostic_sources()
    local sources = require('lint').linters_by_ft[vim.bo.filetype]
    if type(sources) == 'table' then
        return math.max(1, vim.tbl_count(sources))
    end
    return 1
end

local severity_icons = {
    [vim.diagnostic.severity.ERROR] = u.icons.error,
    [vim.diagnostic.severity.WARN] = u.icons.warning,
    [vim.diagnostic.severity.INFO] = u.icons.info,
    [vim.diagnostic.severity.HINT] = u.icons.hint,
}
local function diagnostic_icon(diagnostic)
    return severity_icons[diagnostic.severity] or u.icons.hint
end

local function diagnostic_format_virtual(diagnostic)
    local source = diagnostic.source
    local message = diagnostic.message
    if count_diagnostic_sources() > 1 and not_in(message, source) then
        return string.format('%s: %s', source, message)
    end
    return message
end

local function diagnostic_format_float(diagnostic)
    local icon = diagnostic_icon(diagnostic)
    local source = diagnostic.source
    local message = diagnostic.message
    local code = diagnostic.code
    local msg
    if count_diagnostic_sources() > 1 and not_in(message, source) then
        msg = string.format('%s %s: %s', icon, source, message)
    else
        msg = string.format('%s %s', icon, message)
    end
    if code and code ~= vim.NIL and not_in(msg, code) then
        msg = string.format('%s [%s]', msg, code)
    end
    return msg
end

local function diagnostic_suffix(diagnostic)
    local code = diagnostic.code
    local message = diagnostic.message
    if not code or code == vim.NIL then
        return ''
    end
    if not_in(message, code) then
        return string.format(' [%s]', code)
    end
    return ''
end

-- Toggle function
local diagnostics_active = true
local function toggle_buffer_diagnostics()
    diagnostics_active = not diagnostics_active
    local bufnr = 0
    if diagnostics_active then
        vim.diagnostic.show(nil, bufnr)
    else
        vim.diagnostic.hide(nil, bufnr)
    end
    return diagnostics_active
end

-- Setup
vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    underline = false,
    signs = { text = severity_icons },
    float = {
        source = false,
        format = diagnostic_format_float,
        -- FIXME: Sometimes adds suffix twice when writing a file
        suffix = '',
    },
    virtual_text = {
        spacing = 0,
        source = false,
        prefix = '',
        format = diagnostic_format_virtual,
        suffix = diagnostic_suffix,
    },
})

-- Autocmd options
vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    desc = 'Update location list with formatted diagnostics on save',
    group = vim.api.nvim_create_augroup('diagnostics_format', { clear = true }),
    callback = function()
        local bufnr = 0
        local diagnostics = vim.diagnostic.get(bufnr)
        if #diagnostics == 0 then
            vim.cmd.lclose()
            vim.fn.setloclist(bufnr, {})
            return
        end

        -- Reformat diagnostic messages to include source and code if not present
        local neotest = false
        local new_msg = {}
        for _, v in vim.iter(pairs(diagnostics)) do
            local old_msg = v.message
            local source = v.source and tostring(v.source) or ''
            local code = v.code and v.code ~= vim.NIL and tostring(v.code) or nil

            if source ~= '' and not string.find(old_msg, source, 1, true) then
                v.message = string.format('%s: %s', source, old_msg)
                if code and not string.find(v.message, code, 1, true) then
                    v.message = string.format('%s [%s]', v.message, code)
                end
            end
            new_msg[old_msg] = v.message

            if source == 'neotest' then
                neotest = true
            end
        end

        -- Update the location list with the new messages
        vim.diagnostic.setloclist({ open = false })
        local current_ll = vim.fn.getloclist(bufnr)
        local new_ll = {}
        for _, v in vim.iter(pairs(current_ll)) do
            v.text = new_msg[v.text] or v.text
            table.insert(new_ll, v)
        end
        vim.fn.setloclist(bufnr, {}, ' ', {
            title = string.format(
                'Diagnostics: %s',
                vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':p:.')
            ),
            items = new_ll,
        })

        if not neotest then
            vim.cmd.lopen()
        end
    end,
})

-- Mappings
vim.keymap.set(
    'n',
    '<Leader>fd',
    vim.diagnostic.open_float,
    { desc = 'Show diagnostics in floating window' }
)

vim.keymap.set('n', '<Leader>ld', function()
    local win_id = vim.api.nvim_get_current_win()
    vim.diagnostic.setloclist({
        title = string.format(
            'Diagnostics: %s',
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
        ),
    })
    vim.api.nvim_set_current_win(win_id)
end, { desc = 'Show diagnostics in location list' })

vim.keymap.set(
    'n',
    '<Leader>dt',
    toggle_buffer_diagnostics,
    { desc = 'Toggle diagnostics for current buffer' }
)

vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump({ count = -1 })
end, { desc = 'Go to previous diagnostic' })

vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump({ count = 1 })
end, { desc = 'Go to next diagnostic' })
