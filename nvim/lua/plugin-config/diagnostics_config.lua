local u = require('utils')

-- Helpers
local function get_diagnostic_sources_count()
    local sources = require('lint').linters_by_ft[vim.bo.filetype]
    if sources then
        return #sources
    else
        return 1
    end
end

-- Diagnostic format
local function diagnostic_icon(diagnostic)
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
    return icon
end

local function diagnostic_format_virtual(diagnostic)
    if
        get_diagnostic_sources_count() > 1
        and not string.match(diagnostic.message, diagnostic.source)
    then
        return string.format('%s: %s', diagnostic.source, diagnostic.message)
    else
        return diagnostic.message
    end
end

local function diagnostic_format_float(diagnostic)
    local msg
    local icon = diagnostic_icon(diagnostic)
    if
        get_diagnostic_sources_count() > 1
        and not string.match(diagnostic.message, diagnostic.source)
    then
        msg = string.format('%s %s: %s', icon, diagnostic.source, diagnostic.message)
    else
        msg = string.format('%s %s', icon, diagnostic.message)
    end
    if diagnostic.code ~= vim.NIL then
        if diagnostic.code and not string.match(msg, diagnostic.code) then
            msg = string.format(msg .. ' [%s]', diagnostic.code)
        end
    end
    return msg
end

local function diagnostic_suffix(diagnostic)
    if not diagnostic.code or diagnostic.code == vim.NIL then
        return ''
    end
    if not string.match(diagnostic.message, diagnostic.code) then
        return (' [%s]'):format(diagnostic.code)
    end
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

-- Setup
vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    underline = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = u.icons.error,
            [vim.diagnostic.severity.WARN] = u.icons.warning,
            [vim.diagnostic.severity.INFO] = u.icons.info,
            [vim.diagnostic.severity.HINT] = u.icons.hint,
        },
    },
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
    group = vim.api.nvim_create_augroup('diagnostics_format', { clear = true }),
    callback = function()
        local diagnostics = vim.diagnostic.get(0)
        if #diagnostics <= 0 then
            vim.cmd.lclose()
            vim.fn.setloclist(0, {})
            return
        end

        -- Modify message to add source and error code
        local neotest = false
        local new_msg = {}
        for _, v in vim.iter(pairs(diagnostics)) do
            local old_msg = v.message
            if not string.match(v.message, v.source) then
                v.message = string.format('%s: %s', v.source, v.message)
                if v.code ~= vim.NIL then
                    if v.code and v.code ~= '' then
                        v.message = string.format('%s [%s]', v.message, v.code)
                    end
                end
            end
            new_msg[old_msg] = v.message

            if v.source == 'neotest' then
                neotest = true
            end
        end

        -- Using set.diagnostics is weird so we first set the location list
        -- with the original diagnostics and then modify it with the new
        -- diagnostic msg
        vim.diagnostic.setloclist({ open = false })
        local current_ll = vim.fn.getloclist(0)
        local new_ll = {}
        for _, v in vim.iter(pairs(current_ll)) do
            v.text = new_msg[v.text]
            table.insert(new_ll, v)
        end
        vim.fn.setloclist(0, {}, ' ', {
            title = string.format(
                'Diagnostics: %s',
                vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
            ),
            items = new_ll,
        })

        if not neotest then
            -- We use the qf for neotest so only open if neotest is not the source
            vim.cmd.lopen()
        end
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>fd', vim.diagnostic.open_float)
vim.keymap.set('n', '<Leader>ld', function()
    local win_id = vim.api.nvim_get_current_win()
    vim.diagnostic.setloclist({
        title = string.format(
            'Diagnostics: %s',
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
        ),
    })
    vim.api.nvim_set_current_win(win_id)
end)
vim.keymap.set('n', '<Leader>dt', toggle_buffer_diagnostics)
vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump({ count = -1 })
end)
vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump({ count = 1 })
end)
