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
            components = {
                'default',
                { 'on_output_quickfix', tail = false, open = false },
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
