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
        and title[1][1] == 'Debug Chat'
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
-- Workaround for Arch packaging mismatch: the `/usr/bin/luacheck` wrapper
-- targets a Lua version whose rock tree no longer exists. Derive the installed
-- version from the rock path so this survives package bumps.
local luacheck_entry =
    vim.fn.glob('/usr/lib/luarocks/rocks-*/luacheck/*/bin/luacheck', true, true)[1]
local lua_ver = luacheck_entry and luacheck_entry:match('rocks%-(%d+%.%d+)')
if lua_ver then
    local luacheck_path = string.format(
        '/usr/share/lua/%s/?.lua;/usr/share/lua/%s/?/init.lua;',
        lua_ver,
        lua_ver
    )
    local luacheck_cpath = string.format('/usr/lib/lua/%s/?.so;', lua_ver)
    linters.luacheck.cmd = 'lua' .. lua_ver
    linters.luacheck.args = vim.list_extend(
        {
            '-e',
            table.concat({
                ('package.path=%q..package.path'):format(luacheck_path),
                ('package.cpath=%q..package.cpath'):format(luacheck_cpath),
                ('dofile(%q)'):format(luacheck_entry),
            }, ';'),
            '--',
        },
        vim.list_extend(vim.deepcopy(linters.luacheck.args), {
            '--config=' .. vim.fs.joinpath(vim.env.HOME, '.config', '.luacheckrc'),
        })
    )
end

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
    parser = function(output, bufnr)
        local text = type(output) == 'table' and table.concat(output, '\n')
            or (output or '')
        text = text:gsub('\r\n', '\n')
        local sev = vim.diagnostic.severity
        local map = { error = sev.ERROR, warning = sev.WARN, note = sev.HINT }
        local diags = {}
        for line in vim.gsplit(text, '\n', { trimempty = true }) do
            local file, l1, c1, l2, c2, s, msg, code = line:match(
                '^(.+):(%d+):(%d+):(%d+):(%d+):%s*(%a+):%s*(.-)%s*%[([^%]]+)%]%s*$'
            )
            if file then
                diags[#diags + 1] = {
                    bufnr = bufnr,
                    lnum = tonumber(l1) - 1,
                    col = math.max(tonumber(c1) - 1, 0),
                    end_lnum = tonumber(l2) - 1,
                    end_col = math.max(tonumber(c2) - 1, 0),
                    severity = map[s] or sev.ERROR,
                    message = msg,
                    code = code,
                    source = 'zmypy',
                }
            end
        end
        return diags
    end,
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
    dockerfile = { 'hadolint' },
    fish = { 'fish' },
    ghaction = { 'actionlint' },
    javascript = { 'oxlint' },
    json = { 'jq' },
    lua = { 'luacheck' },
    markdown = { 'rumdl' },
    python = { 'zmypy', 'ruff' },
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
