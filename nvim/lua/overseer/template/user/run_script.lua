return {
    name = 'Run Script',
    builder = function()
        local file = vim.fn.expand('%:p')
        return {
            cmd = { vim.bo.filetype },
            args = { file },
            components = {
                { 'on_output_quickfix', set_diagnostics = true },
                'on_result_diagnostics',
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'python', 'bash', 'lua' },
    },
}
