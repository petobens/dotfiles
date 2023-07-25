local null_ls = require('null-ls')
local u = require('utils')
local null_ls_diagnostics = null_ls.builtins.diagnostics
local null_ls_formatting = null_ls.builtins.formatting

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
-- Note: for each language formatters/linters will run in the declared order
local sources = {
    -- Bash
    null_ls_formatting.shfmt.with({
        extra_args = { '-i', '4', '-ci', '-sr' },
    }),

    null_ls_diagnostics.shellcheck,
    -- JSON
    null_ls_formatting.jq.with({
        extra_args = { '--indent', '4' },
    }),

    null_ls_diagnostics.jsonlint,

    -- Lua
    null_ls_formatting.stylua.with({
        extra_args = {
            '--config-path=' .. vim.env.HOME .. '/.config/stylua.toml',
        },
    }),
    null_ls_diagnostics.luacheck.with({
        extra_args = {
            '--config=' .. vim.env.HOME .. '/.config/.luacheckrc',
        },
    }),

    -- Python
    null_ls_formatting.isort.with({
        extra_args = {
            '--settings-file=' .. vim.env.HOME .. '/.isort.cfg',
        },
    }),
    null_ls_formatting.black.with({
        extra_args = {
            '--config=' .. vim.env.HOME .. '/.config/.black.toml',
        },
    }),
    null_ls_diagnostics.pylint,
    null_ls_diagnostics.mypy,
    ruff,

    -- SQL (dialect is set in sqlfluff config)
    null_ls_formatting.sqlfluff,
    null_ls_diagnostics.sqlfluff,

    -- TOML
    -- TODO: not diagnostics as per https://github.com/tamasfe/taplo/issues/328
    null_ls_formatting.taplo.with({
        extra_args = {
            '--config=' .. vim.env.HOME .. '/taplo.toml',
        },
    }),

    -- YAML
    null_ls_formatting.prettierd.with({
        filetypes = { 'yaml' },
    }),
    null_ls_diagnostics.yamllint,
}

-- Helpers
local function custom_lsp_format(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            return client.name == 'null-ls'
        end,
        bufnr = bufnr,
        -- FIXME: if set to true then diagnostic list autocloses
        async = false,
    })
end

-- On-Attach
local format_augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local function on_attach(client, bufnr)
    -- Don't use null-ls for (cmp-lsp) completion
    if client.name == 'null-ls' then
        client.server_capabilities.completionProvider = false
    end

    vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })

    -- Autoformat on save with null-ls
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = format_augroup,
        buffer = bufnr,
        callback = function()
            custom_lsp_format(bufnr)
        end,
    })

    -- Open diagnostics on save (if there are diagnostics)
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = format_augroup,
        buffer = bufnr,
        callback = function()
            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics > 0 then
                -- Format location list to include source and error code (but do
                -- it only once to avoid repetition when reopening the location list)
                for _, v in pairs(diagnostics) do
                    if not string.match(v.message, v.source) then
                        v.message = string.format('%s: %s', v.source, v.message)
                        if v.code ~= '' then
                            v.message = string.format('%s [%s]', v.message, v.code)
                        end
                    end
                end
                vim.diagnostic.setloclist({
                    title = string.format(
                        'Diagnostics: %s',
                        vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:.')
                    ),
                })
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

-- Mappings
u.keymap('n', '<Leader>fc', custom_lsp_format)
u.keymap('v', '<Leader>fc', 'gq', { remap = true })
