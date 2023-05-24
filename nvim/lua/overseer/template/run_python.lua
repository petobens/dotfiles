PYTHON_EFM = ''
    -- See https://github.com/python-mode/python-mode/blob/149ccf7c5be0753f5e9872c023ab2eeec3442105/autoload/pymode/run.vim#L4
    .. [[%E\ \ File\ \"%f\"\\\,\ line\ %l\\\,%m%\\C,]]
    .. [[%E\ \ File\ \"%f\"\\\,\ line\ %l%\\C,]]
    .. [[%C%p^,]]
    .. [[%-C\ \ %.%#,]]
    .. [[%-C\ \ \ \ %.%#,]]
    .. [[%Z%\\@=%m,]]
    .. [[%+GTraceback%.%#,]]
    .. [[%+GDuring\ handling%.%#,]]
    .. [[%+GThe\ above\ exception%.%#,]]
    .. [[%f:%l:\ %.%#%tarning:%m,]]

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
                errorformat = PYTHON_EFM,
            },
        }
    end,
    condition = {
        filetype = { 'python' },
    },
}
