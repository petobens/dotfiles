return {
    name = 'run_sh',
    builder = function()
        local file = vim.api.nvim_buf_get_name(0)
        local cmd = { 'bash' }
        return {
            cmd = cmd,
            args = { file },
            metadata = { run_cmd = string.format('%s %s', cmd[1], file) },
            components = {
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', open = true },
                'default',
            },
            default_component_params = {
                errorformat = ''
                    .. [[%f:\ %[%^0-9]%#\ %l:%m,]]
                    .. [[%f:\ %l:%m,%f:%l:%m,]]
                    .. [[%f[%l]:%m,]]
                    .. [[%-G[Process exited%.%#,]],
            },
        }
    end,
    condition = {
        filetype = { 'sh' },
    },
}
