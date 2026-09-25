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
    if not vim.isnil(code) and not_in(msg, code) then
        msg = string.format('%s [%s]', msg, code)
    end
    return msg
end

local function diagnostic_suffix(diagnostic)
    local code = diagnostic.code
    local message = diagnostic.message
    if vim.isnil(code) then
        return ''
    end
    if not_in(message, code) then
        return string.format(' [%s]', code)
    end
    return ''
end

-- Toggle function
local function toggle_buffer_diagnostics()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled({ bufnr = 0 }), { bufnr = 0 })
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

-- Keep save-triggered lists in sync with asynchronous linter results
local saved_buffers = {}
local function update_saved_diagnostics(bufnr)
    local saved = saved_buffers[bufnr]
    if
        not saved
        or not vim.api.nvim_buf_is_valid(bufnr)
        or vim.api.nvim_buf_get_changedtick(bufnr) ~= saved.tick
        or not vim.api.nvim_win_is_valid(saved.win)
        or vim.api.nvim_win_get_buf(saved.win) ~= bufnr
        or (saved.list and vim.fn.getloclist(saved.win, { id = 0 }).id ~= saved.list)
    then
        return
    end

    local diagnostics = vim.diagnostic.get(bufnr)
    local neotest = false
    for _, diagnostic in ipairs(diagnostics) do
        local source = diagnostic.source and tostring(diagnostic.source) or ''
        local code = not vim.isnil(diagnostic.code) and tostring(diagnostic.code) or nil
        if source ~= '' and not diagnostic.message:find(source, 1, true) then
            diagnostic.message = source .. ': ' .. diagnostic.message
        end
        if code and not diagnostic.message:find(code, 1, true) then
            diagnostic.message = diagnostic.message .. ' [' .. code .. ']'
        end
        neotest = neotest or source == 'neotest'
    end

    local current_win = vim.api.nvim_get_current_win()
    local list_win = vim.fn.getloclist(saved.win, { winid = 0 }).winid
    local show = current_win == saved.win or current_win == list_win
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local rel = vim.fs.relpath(vim.uv.cwd(), bufname)
    vim.api.nvim_win_call(saved.win, function()
        vim.fn.setloclist(0, {}, saved.list and 'r' or ' ', {
            title = 'Diagnostics: ' .. (rel or bufname),
            items = vim.diagnostic.toqflist(diagnostics),
        })
        saved.list = vim.fn.getloclist(0, { id = 0 }).id
        if #diagnostics == 0 then
            vim.cmd.lclose()
        elseif show and not neotest then
            vim.cmd.lopen()
        end
    end)
end

local diagnostics_group =
    vim.api.nvim_create_augroup('diagnostics_format', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
    desc = 'Update location list with formatted diagnostics on save',
    group = diagnostics_group,
    callback = function(e)
        saved_buffers[e.buf] = {
            tick = vim.api.nvim_buf_get_changedtick(e.buf),
            win = vim.api.nvim_get_current_win(),
        }
        update_saved_diagnostics(e.buf)
    end,
})
vim.api.nvim_create_autocmd('DiagnosticChanged', {
    desc = 'Refresh saved-buffer location lists after diagnostics change',
    group = diagnostics_group,
    callback = function(e)
        vim.schedule(function()
            update_saved_diagnostics(e.buf)
        end)
    end,
})
vim.api.nvim_create_autocmd('BufWipeout', {
    desc = 'Forget saved diagnostic list state for deleted buffers',
    group = diagnostics_group,
    callback = function(e)
        saved_buffers[e.buf] = nil
    end,
})

-- Mappings
vim.keymap.set(
    'n',
    '<Leader>fd',
    vim.diagnostic.open_float,
    { desc = '[F]loating [d]iagnostics: show' }
)

vim.keymap.set('n', '<Leader>ld', function()
    local win_id = vim.api.nvim_get_current_win()
    local bufname = vim.api.nvim_buf_get_name(0)
    local rel = bufname and vim.fs.relpath(vim.uv.cwd(), bufname)
    vim.diagnostic.setloclist({
        title = 'Diagnostics: ' .. (rel or bufname or '[No Name]'),
    })
    vim.api.nvim_set_current_win(win_id)
end, { desc = '[L]ocation [d]iagnostics: show' })

vim.keymap.set(
    'n',
    '<Leader>dt',
    toggle_buffer_diagnostics,
    { desc = '[D]iagnostics [t]oggle for current buffer' }
)

vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump({ count = -vim.v.count1 })
end, { desc = 'Go to previous diagnostic' })

vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump({ count = vim.v.count1 })
end, { desc = 'Go to next diagnostic' })
