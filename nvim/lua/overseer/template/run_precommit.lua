return {
    name = 'run_precommit',
    builder = function()
        local cmd = { 'pre-commit', 'run' }
        -- TODO: We probably want this for other filetypes too
        local precommit_root = vim.fs.root(0, '.pre-commit-config.yaml') or vim.uv.cwd()
        local py_files = vim.fs.find(function(name)
            return name:match('.*%.py$')
        end, {
            limit = math.huge,
            type = 'file',
            path = precommit_root,
        })
        return {
            cmd = cmd,
            metadata = { run_cmd = 'pre-commit run', project_files = py_files },
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
