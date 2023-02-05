return {
    name = 'run_lua',
    builder = function()
        local file = vim.fn.expand('%:p')
        return {
            cmd = { 'nvim', '-ll' },
            args = { file },
            metadata = { run_cmd = string.format('%s', file) },
            components = {
                'default',
                { 'on_output_quickfix', open = true },
            },
        }
    end,
    condition = {
        filetype = { 'lua' },
    },
}
