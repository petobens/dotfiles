return {
    name = 'run_arara',
    builder = function()
        ---@diagnostic disable-next-line: undefined-field
        local file = vim.b.vimtex.tex
        return {
            metadata = { filename = file },
            cmd = { 'arara', '-p', 'minimize_runs' },
            args = { file },
            ---@diagnostic disable-next-line: undefined-field
            cwd = vim.b.vimtex.root,
            components = {
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'tex' },
    },
}
