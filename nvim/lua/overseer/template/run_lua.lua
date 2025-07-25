return {
    name = 'run_lua',
    builder = function()
        local file = vim.api.nvim_buf_get_name(0)
        local cmd = { 'nvim', '-l' }
        return {
            cmd = cmd,
            args = { file },
            metadata = { run_cmd = string.format('%s %s %s', cmd[1], cmd[2], file) },
            components = {
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', open = true },
                'default',
            },
            default_component_params = {
                errorformat = ''
                    .. [[%t%n:\ Error\ while\ creating\ lua\ chunk:\ %f:%l:\ %m,]]
                    .. [[%t%n:\ Error\ while\ calling\ lua\ chunk:\ %f:%l:\ %m,]]
                    .. [[%f:%l:%m,]]
                    .. [[%-G[Process exited%.%#,]],
            },
        }
    end,
    condition = {
        filetype = { 'lua' },
    },
}
