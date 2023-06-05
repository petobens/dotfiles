return {
    name = 'run_python',
    builder = function()
        local file = vim.fn.expand('%:p')
        local cmd = { 'python' }
        return {
            cmd = cmd,
            args = { file },
            metadata = { run_cmd = string.format('%s %s', cmd[1], file) },
            -- When setting specific components on a task, we must specify them
            -- before default component alias as per:
            -- https://github.com/stevearc/overseer.nvim/issues/143
            components = {
                { 'on_complete_notify', statuses = {} }, -- don't notify on completion
                { 'on_output_quickfix', tail = false, open = false },
                'default',
            },
            default_component_params = {
                errorformat = _G.OverseerConfig.python_errorformat,
            },
        }
    end,
    condition = {
        filetype = { 'python' },
    },
}
