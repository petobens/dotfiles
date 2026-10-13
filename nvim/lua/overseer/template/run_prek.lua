return {
    name = 'run_prek',
    builder = function()
        -- TODO: We probably want this for other filetypes too
        local hook_root = vim.fs.root(
            0,
            { { 'prek.toml', '.pre-commit-config.yaml', '.pre-commit-config.yml' } }
        ) or vim.uv.cwd()
        return {
            cmd = { require('python').tool('prek', hook_root), 'run' },
            -- prek reports paths relative to the repository root
            cwd = hook_root,
            metadata = { run_cmd = 'prek run' },
            components = {
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', tail = false, open = false },
                'default',
            },
            default_component_params = {
                errorformat = [[%f:%l:%c:%m,%-G%.%#]],
            },
        }
    end,
    condition = {
        filetype = { 'python' },
    },
}
