return {
    name = 'run_arara',
    builder = function()
        local file = vim.b.vimtex.tex
        return {
            metadata = { filename = file },
            cmd = { 'arara', '-p', 'minimize_runs' },
            args = { file },
            cwd = vim.b.vimtex.root,
            components = {
                { 'on_complete_notify', statuses = { 'SUCCESS' } },
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'tex' },
    },
}
