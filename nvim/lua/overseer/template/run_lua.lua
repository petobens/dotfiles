return {
    name = 'run_lua',
    builder = function()
        local file = vim.fn.expand('%:p')
        return {
            cmd = { 'nvim', '-ll' },
            args = { file },
            metadata = { run_cmd = string.format('%s', file) },
            components = {
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', open = true },
                'default',
            },
            default_component_params = {
                errorformat = [[%f:%l:%m,%-G[Process exited%.%#]],
            },
        }
    end,
    condition = {
        filetype = { 'lua' },
    },
}
