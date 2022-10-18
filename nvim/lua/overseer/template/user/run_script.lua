local function set_efm(ft)
    local efm = vim.go.errorformat
    if ft == 'python' then
        efm = [[%E\ \ File\ \"%f\"\\\,\ line\ %l\\\,%m%\\C,]]
            .. [[%E\ \ File\ \"%f\"\\\,\ line\ %l%\\C,]]
            .. [[%C%p^,]]
            .. [[%-C\ \ %.%#,]]
            .. [[%-C\ \ \ \ %.%#,]]
            .. [[%Z%\\@=%m,]]
            .. [[%+GTraceback%.%#,]]
            .. [[%+GDuring\ handling%.%#,]]
            .. [[%+GThe\ above\ exception%.%#,]]
            .. [[%f:%l:\ %.%#%tarning:%m,]]
    end
    return efm
end

return {
    name = 'Run Script',
    builder = function()
        local file = vim.fn.expand('%:p')
        local cmd = { vim.bo.filetype }
        return {
            cmd = cmd,
            args = { file },
            default_component_params = {
                errorformat = set_efm(vim.bo.filetype),
            },
            components = {
                'default',
                { 'on_output_quickfix', open = true },
            },
        }
    end,
    condition = {
        filetype = { 'python', 'bash', 'lua' },
    },
}
