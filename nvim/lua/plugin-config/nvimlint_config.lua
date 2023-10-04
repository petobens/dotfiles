local lint = require('lint')

-- Automatically run linters
vim.api.nvim_create_autocmd(
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        group = vim.api.nvim_create_augroup('nvim_lint', { clear = true }),
        callback = function(opts)
            vim.defer_fn(function()
                lint.try_lint(nil, { ignore_errors = true })
            end, 1)

            if opts.event == 'BufWritePost' then
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

                    -- Using set.diagnostics is weird so we first set the location list
                    -- with the original diagnostics and then modify it with the new
                    -- diagnostic msg
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
            end
        end,
    }
)

-- Linters by filetype
lint.linters_by_ft = {
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
---- Lua
linters.luacheck.args = vim.list_extend(vim.deepcopy(linters.luacheck.args), {
    '--config=' .. vim.env.HOME .. '/.config/.luacheckrc',
})
---- TeX
linters.chktex.args = vim.list_extend(vim.deepcopy(linters.chktex.args), {
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
})
linters.chktex.ignore_exitcode = true

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
