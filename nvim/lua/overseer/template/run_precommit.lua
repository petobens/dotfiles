return {
    name = 'run_precommit',
    builder = function()
        local cmd = { 'pre-commit', 'run' }
        -- TODO: We probably want this for other filetypes too
        local py_files = vim.fs.find(function(name)
            return name:match('.*%.py$')
        end, {
            limit = math.huge,
            type = 'file',
            path = vim.fn.fnamemodify(
                vim.fn.findfile('.pre-commit-config.yaml', vim.fn.getcwd() .. ';'),
                ':p:h'
            ),
        })
        return {
            cmd = cmd,
            metadata = { run_cmd = 'pre-commit run', project_files = py_files },
            components = {
                'default',
                { 'on_output_quickfix', tail = false, open = false },
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
