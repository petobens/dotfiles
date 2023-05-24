return {
    name = 'run_script',
    builder = function()
        local file = vim.fn.expand('%:p')
        local cmd = { vim.bo.filetype }
        return {
            cmd = cmd,
            args = { file },
            components = {
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', open = true },
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'bash' },
    },
}
