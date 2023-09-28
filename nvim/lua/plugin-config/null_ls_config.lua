local null_ls = require('null-ls')
local null_ls_diagnostics = null_ls.builtins.diagnostics

-- Custom sources
local ruff_severities = {
    ['E'] = vim.diagnostic.severity.ERROR,
    ['F8'] = vim.diagnostic.severity.ERROR,
    ['F'] = vim.diagnostic.severity.WARN,
    ['W'] = vim.diagnostic.severity.WARN,
    ['D'] = vim.diagnostic.severity.INFO,
    ['B'] = vim.diagnostic.severity.INFO,
}
local ruff = null_ls_diagnostics.ruff.with({
    diagnostics_postprocess = function(diagnostic)
        local code = string.sub(diagnostic.code, 1, 2)
        if code ~= 'F8' then
            code = string.sub(code, 1, 1)
        end
        local new_severity = ruff_severities[code]
        if new_severity then
            diagnostic.severity = new_severity
        end
    end,
})

-- Sources configuration
-- Note: for each language linters will run in the declared order
local sources = {
    -- Bash
    null_ls_diagnostics.shellcheck,

    -- JSON
    null_ls_diagnostics.jsonlint,

    -- Latex
    null_ls_diagnostics.chktex.with({
        extra_args = {
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
        },
    }),

    -- Lua
    null_ls_diagnostics.luacheck.with({
        extra_args = {
            '--config=' .. vim.env.HOME .. '/.config/.luacheckrc',
        },
    }),

    -- Python
    null_ls_diagnostics.pylint,
    null_ls_diagnostics.mypy,
    ruff,

    -- SQL (dialect is set in sqlfluff config)
    null_ls_diagnostics.sqlfluff,

    -- YAML
    null_ls_diagnostics.yamllint,
}

-- Helpers

-- On-Attach
local diagnostic_augroup = vim.api.nvim_create_augroup('NullLsDiagnostics', {})
local function on_attach(client, bufnr)
    -- Don't use null-ls for (cmp-lsp) completion
    if client.name == 'null-ls' then
        client.server_capabilities.completionProvider = false
    end

    vim.api.nvim_clear_autocmds({ group = diagnostic_augroup, buffer = bufnr })

    -- Open diagnostics on save (if there are diagnostics)
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = diagnostic_augroup,
        buffer = bufnr,
        callback = function()
            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics > 0 then
                -- Modify message to add source and error code
                local new_msg = {}
                for _, v in pairs(diagnostics) do
                    if not string.match(v.message, v.source) then
                        v.message = string.format('%s: %s', v.source, v.message)
                        if v.code ~= '' then
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
end

-- Actual setup
null_ls.setup({
    sources = sources,
    debug = false,
    should_attach = function(bufnr)
        -- Don't attach to fugitive git diff buffers
        return not vim.api.nvim_buf_get_name(bufnr):match('^fugitive://')
    end,
    on_attach = on_attach,
})
