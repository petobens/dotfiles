-- luacheck:ignore 631
local lint = require('lint')

-- Automatically run linters
local lint_group = vim.api.nvim_create_augroup('nvim_lint', { clear = true })
local lint_generation = {}

local function should_lint(bufnr)
    local win_config = vim.api.nvim_win_get_config(0)
    local title = win_config.title
    local is_float = win_config.relative ~= ''
    if is_float and vim.bo[bufnr].filetype == 'markdown' then
        return false
    end
    if
        is_float
        and type(title) == 'table'
        and type(title[1]) == 'table'
        and vim.trim(title[1][1]) == 'Debug Chat'
    then
        return false
    end
    return vim.bo[bufnr].buftype ~= 'nofile' or vim.bo[bufnr].buflisted
end

local function run_linters(bufnr, filter)
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_call(bufnr, function()
            if should_lint(bufnr) then
                lint.try_lint(nil, { ignore_errors = true, filter = filter })
            end
        end)
    end
end

local function live_linter(linter)
    return linter.stdin and linter.name ~= 'rumdl' and linter.name ~= 'sqlfluff'
end

vim.api.nvim_create_autocmd('BufEnter', {
    desc = 'Run live nvim-lint linters when entering buffers',
    group = lint_group,
    callback = function(e)
        lint_generation[e.buf] = (lint_generation[e.buf] or 0) + 1
        run_linters(e.buf, live_linter)
    end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
    desc = 'Run all nvim-lint linters after saving',
    group = lint_group,
    callback = function(e)
        lint_generation[e.buf] = (lint_generation[e.buf] or 0) + 1
        run_linters(e.buf)
    end,
})

vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    desc = 'Run stdin-aware nvim-lint linters after edits',
    group = lint_group,
    callback = function(e)
        local bufnr = e.buf
        lint_generation[bufnr] = (lint_generation[bufnr] or 0) + 1
        local generation = lint_generation[bufnr]
        vim.defer_fn(function()
            if
                lint_generation[bufnr] ~= generation
                or not vim.api.nvim_buf_is_valid(bufnr)
            then
                return
            end
            run_linters(bufnr, live_linter)
        end, 300)
    end,
})

-- Linter config/args
local linters = lint.linters
---- Lua
table.insert(
    linters.luacheck.args,
    '--config=' .. vim.fs.joinpath(vim.env.HOME, '.config', '.luacheckrc')
)

---- Markdown
linters.rumdl.stream = 'stdout'
---- TOML
linters.tombi.args = {
    'lint',
    '--quiet',
    '--stdin-filename',
    function()
        return vim.api.nvim_buf_get_name(0)
    end,
    '-',
}
linters.tombi.stdin = true
linters.tombi.stream = 'both'
local tombi_severities = {
    Error = vim.diagnostic.severity.ERROR,
    Warning = vim.diagnostic.severity.WARN,
}
linters.tombi.parser = function(output, bufnr)
    local diagnostics = {}
    local message
    local severity
    for line in vim.gsplit(output, '\n', { trimempty = true }) do
        local level, text = line:match('^%s*(%a+):%s*(.+)$')
        if tombi_severities[level] then
            message = text
            severity = tombi_severities[level]
        elseif message then
            local lnum, col = line:match('^%s*at .+:(%d+):(%d+)%s*$')
            if lnum then
                diagnostics[#diagnostics + 1] = {
                    bufnr = bufnr,
                    lnum = tonumber(lnum) - 1,
                    col = tonumber(col) - 1,
                    severity = severity,
                    message = message,
                    source = 'tombi',
                }
                message = nil
            end
        end
    end
    return diagnostics
end
---- Python
-- Ruff:
linters.ruff.cmd = function()
    return require('python').tool('ruff')
end
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
        if vim.isnil(code) or type(code) ~= 'string' then
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
---- Sqlfluff
linters.sqlfluff.args = { 'lint', '--format=json', '-' }
linters.sqlfluff.stdin = true
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
    dockerfile = { 'hadolint' },
    fish = { 'fish' },
    ghaction = { 'actionlint' },
    javascript = { 'oxlint' },
    json = { 'jq' },
    lua = { 'luacheck' },
    markdown = { 'rumdl' },
    python = { 'ruff' },
    sh = { 'shellcheck' },
    sql = { 'sqlfluff' },
    tex = { 'chktex' },
    toml = { 'tombi' },
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
