return {
    name = 'run_precommit',
    builder = function()
        local cmd = { 'pre-commit', 'run' }
        -- TODO: We probably want this for other filetypes too
        local precommit_root = vim.fs.root(0, '.pre-commit-config.yaml') or vim.uv.cwd()
        return {
            cmd = cmd,
            -- Pre-commit reports paths relative to the repository root
            cwd = precommit_root,
            metadata = { run_cmd = 'pre-commit run' },
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
