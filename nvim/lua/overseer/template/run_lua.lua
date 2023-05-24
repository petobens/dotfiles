return {
    name = 'run_lua',
    builder = function()
        local file = vim.fn.expand('%:p')
        return {
            cmd = { 'nvim', '-ll' },
            args = { file },
            metadata = { run_cmd = string.format('%s', file) },
            components = {
                -- TODO: Better EFM
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', open = true },
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'lua' },
    },
}
