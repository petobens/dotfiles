local lint = require('lint')

-- Run linters when changing text or leaving insert mode
local lint_acg = vim.api.nvim_create_augroup('Lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'InsertLeave' }, {
    group = lint_acg,
    callback = function()
        lint.try_lint(nil, { ignore_errors = true })
    end,
})

-- Populate qf diagnostics on save
vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    group = lint_acg,
    callback = function()
        lint.try_lint(nil, { ignore_errors = true })
        local diagnostics = vim.diagnostic.get(0)
        if #diagnostics > 0 then
            -- Modify message to add source and error code
            local new_msg = {}
            for _, v in pairs(diagnostics) do
                if not string.match(v.message, v.source) then
                    v.message = string.format('%s: %s', v.source, v.message)
                    if v.code and v.code ~= '' then
                        v.message = string.format('%s [%s]', v.message, v.code)
                    end
                end
                table.insert(new_msg, v.message)
            end

            -- Using set.diagnostics is weird so we first set the location list with
            -- the original diagnostics and then modify it with the new diagnostic msg
            vim.diagnostic.setloclist({ open = false })
            local current_ll = vim.fn.getloclist(0)
            local new_ll = {}
            for i, v in pairs(current_ll) do
                v.text = new_msg[i]
                table.insert(new_ll, v)
            end
            vim.fn.setloclist(0, {}, ' ', {
                title = string.format(
                    'Diagnostics: %s',
                    vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
                ),
                items = new_ll,
            })
            vim.cmd('lopen')
        else
            vim.cmd('lclose')
        end
    end,
})

-- Linters by filetype
lint.linters_by_ft = {
    -- FIXME: Jsonlint and sqlfluff are slow
    json = { 'jsonlint' },
    lua = { 'luacheck' },
    python = { 'mypy', 'pylint', 'ruff' },
    sh = { 'shellcheck' },
    sql = { 'sqlfluff' },
    tex = { 'chktex' },
    yaml = { 'yamllint' },
}

-- Linter config/args
local linters = require('lint').linters
linters.luacheck.args = {
    '--formatter',
    'plain',
    '--codes',
    '--ranges',
    '--config=' .. vim.env.HOME .. '/.config/.luacheckrc',
    '-',
}
linters.chktex.args = {
    '-v0',
    '-I0',
    '-s',
    ':',
    '-f',
    '%l%b%c%b%d%b%k%b%n%b%m%b%b%b',
    '-n1',
    '-n2',
    '-n3',
    '-n6',
    '-n7',
    '-n8',
    '-n13',
    '-n24',
    '-n25',
    '-n36',
}

-- Custom Ruff
-- TODO: Finish this
-- local ruff_severities = {
--     ['E'] = vim.diagnostic.severity.ERROR,
--     ['F8'] = vim.diagnostic.severity.ERROR,
--     ['F'] = vim.diagnostic.severity.WARN,
--     ['W'] = vim.diagnostic.severity.WARN,
--     ['D'] = vim.diagnostic.severity.INFO,
--     ['B'] = vim.diagnostic.severity.INFO,
-- }
-- local ruff = null_ls_diagnostics.ruff.with({
--     diagnostics_postprocess = function(diagnostic)
--         local code = string.sub(diagnostic.code, 1, 2)
--         if code ~= 'F8' then
--             code = string.sub(code, 1, 1)
--         end
--         local new_severity = ruff_severities[code]
--         if new_severity then
--             diagnostic.severity = new_severity
--         end
--     end,
-- })
