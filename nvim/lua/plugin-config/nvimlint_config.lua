-- luacheck:ignore 631
local lint = require('lint')

-- Automatically run linters
vim.api.nvim_create_autocmd(
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        group = vim.api.nvim_create_augroup('nvim_lint', { clear = true }),
        callback = function(e)
            local win_config = vim.api.nvim_win_get_config(0)
            local zindex = win_config.zindex
            local title = win_config.title

            -- Don't lint markdown floating windows
            if e.buf and vim.bo[e.buf].filetype == 'markdown' and zindex then
                return
            end
            -- Don't lint codecompanion debug window
            if
                zindex
                and type(title) == 'table'
                and type(title[1]) == 'table'
                and title[1][1] == 'Debug Chat'
            then
                return
            end

            vim.defer_fn(function()
                lint.try_lint(nil, { ignore_errors = true })
            end, 1)
        end,
    }
)

-- Linters by filetype
lint.linters_by_ft = {
    -- FIXME: can't run mypy without save
    -- https://github.com/mfussenegger/nvim-lint/issues/235
    dockerfile = { 'hadolint' },
    ghaction = { 'actionlint' },
    json = { 'jsonlint' },
    lua = { 'luacheck' },
    markdown = { 'markdownlint' },
    python = { 'mypy', 'ruff' },
    sh = { 'shellcheck' },
    sql = { 'sqlfluff' },
    tex = { 'chktex' },
    yaml = { 'yamllint' },
}

-- Linter config/args
local linters = require('lint').linters
---- Lua
linters.luacheck.args = vim.list_extend(vim.deepcopy(linters.luacheck.args), {
    '--config=' .. vim.fs.joinpath(vim.env.HOME, '.config', '.luacheckrc'),
})
---- Markdown
linters.markdownlint.args = {
    '--config=' .. vim.fs.joinpath(vim.env.HOME, '.markdownlint.json'),
    '--stdin',
}
---- Python
local ruff_severities = {
    ['E'] = vim.diagnostic.severity.ERROR,
    ['F8'] = vim.diagnostic.severity.ERROR,
    ['F'] = vim.diagnostic.severity.WARN,
    ['W'] = vim.diagnostic.severity.WARN,
    ['D'] = vim.diagnostic.severity.INFO,
    ['B'] = vim.diagnostic.severity.INFO,
}
local ruff_parser = linters.ruff.parser
linters.ruff.parser = function(output, bufnr)
    local diagnostics = ruff_parser(output, bufnr)
    for _, v in pairs(diagnostics) do
        local code
        if v.code == vim.NIL then
            code = 'E'
        else
            code = string.sub(v.code, 1, 2)
        end
        if code ~= 'F8' then
            code = string.sub(code, 1, 1)
        end
        local new_severity = ruff_severities[code]
        if new_severity then
            v.severity = new_severity
        end
    end
    return diagnostics
end
---- Sqlfluff
lint.linters.sqlfluff.args = { 'lint', '--format=json', '-' }
linters.sqlfluff.stdin = true
local fluff_parser = linters.sqlfluff.parser
linters.sqlfluff.parser = function(output, bufnr)
    local diagnostics = fluff_parser(output, bufnr)
    for _, v in pairs(diagnostics) do
        v.code = v.user_data.lsp.code
    end
    return diagnostics
end
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

-- Commands
vim.api.nvim_create_user_command('LinterInfo', function()
    local running_linters = table.concat(lint.get_running(), '\n')
    vim.notify(running_linters, vim.log.levels.INFO, { title = 'nvim-lint' })
end, {})
