-- luacheck:ignore 631
local lint = require('lint')

-- Automatically run linters
vim.api.nvim_create_autocmd(
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
        desc = 'Run nvim-lint on buffer events',
        group = vim.api.nvim_create_augroup('nvim_lint', { clear = true }),
        callback = function(e)
            local win_config = vim.api.nvim_win_get_config(0)
            local is_float = win_config.relative ~= ''
            local title = win_config.title

            -- Don't lint markdown floating windows
            if is_float and e.buf and vim.bo[e.buf].filetype == 'markdown' then
                return
            end
            -- Don't lint codecompanion debug window
            if
                is_float
                and type(title) == 'table'
                and type(title[1]) == 'table'
                and title[1][1] == 'Debug Chat'
            then
                return
            end

            -- Defer linting to avoid blocking UI
            vim.defer_fn(function()
                lint.try_lint(nil, { ignore_errors = true })
            end, 1)
        end,
    }
)

-- Linter config/args
local linters = lint.linters
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
-- Ruff:
local severity = vim.diagnostic.severity
local ruff_severities = {
    ['E'] = severity.ERROR,
    ['F8'] = severity.ERROR,
    ['F'] = severity.WARN,
    ['W'] = severity.WARN,
    ['D'] = severity.INFO,
    ['B'] = severity.INFO,
}
local ruff_parser = linters.ruff.parser
linters.ruff.parser = function(output, bufnr)
    local diagnostics = ruff_parser(output, bufnr)
    for _, v in pairs(diagnostics) do
        local code = v.code
        if code == nil or code == vim.NIL or type(code) ~= 'string' then
            code = 'E'
        elseif vim.startswith(code, 'invalid-syntax') then
            code = 'E'
        else
            -- 'F8' is a special case; all other codes use first char for severity mapping
            code = string.sub(code, 1, 2)
            if code ~= 'F8' then
                code = string.sub(code, 1, 1)
            end
        end
        local new_severity = ruff_severities[code]
        if new_severity then
            v.severity = new_severity
        end
    end
    return diagnostics
end
-- Zuban
linters.zmypy = {
    cmd = 'zmypy',
    stdin = false,
    stream = 'both',
    ignore_exitcode = true,
    args = {
        '--no-pretty',
        '--show-error-end',
    },
    parser = require('lint.parser').from_pattern(
        '([^:]+):(%d+):(%d+): (%a+): (.*) %[(%a[%a-]+)%]',
        { 'file', 'lnum', 'col', 'severity', 'message', 'code' },
        {
            error = vim.diagnostic.severity.ERROR,
            warning = vim.diagnostic.severity.WARN,
            note = vim.diagnostic.severity.HINT,
        },
        { source = 'zmypy' }
    ),
}
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

-- Linters by filetype
lint.linters_by_ft = {
    -- FIXME: can't run mypy/zmpy without save
    -- https://github.com/mfussenegger/nvim-lint/issues/235
    dockerfile = { 'hadolint' },
    ghaction = { 'actionlint' },
    json = { 'jsonlint' },
    lua = { 'luacheck' },
    markdown = { 'markdownlint' },
    python = { 'zmypy', 'ruff' },
    sh = { 'shellcheck' },
    sql = { 'sqlfluff' },
    tex = { 'chktex' },
    yaml = { 'yamllint' },
}

-- Commands
vim.api.nvim_create_user_command('LinterInfo', function()
    local ft = vim.bo.filetype
    local configured = require('lint').linters_by_ft[ft]
    if configured and #configured > 0 then
        vim.notify(
            string.format(
                'Configured linters for `%s` filetype:\n%s',
                ft,
                table.concat(configured, '\n')
            ),
            vim.log.levels.INFO
        )
    else
        vim.notify(
            string.format('No linters configured for filetype "%s"', ft),
            vim.log.levels.WARN
        )
    end
end, { desc = 'Show configured linters for current filetype' })
