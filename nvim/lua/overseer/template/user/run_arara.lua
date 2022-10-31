return {
    name = 'run_arara',
    builder = function()
        local file = vim.fn.expand('%:p')
        return {
            metadata = { filename = file },
            cmd = { 'arara', '-p', 'minimize_runs' },
            args = { file },
            cwd = vim.fn.fnamemodify(file, ':h'),
            components = {
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'tex' },
    },
}
