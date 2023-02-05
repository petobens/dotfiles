return {
    name = 'run_script',
    builder = function()
        local file = vim.fn.expand('%:p')
        local cmd = { vim.bo.filetype }
        return {
            cmd = cmd,
            args = { file },
            components = {
                'default',
                { 'on_output_quickfix', open = true },
            },
        }
    end,
    condition = {
        filetype = { 'bash' },
    },
}
