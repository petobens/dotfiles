local function set_efm(ft)
    local efm = ''
    if ft == 'python' then
        efm = [[%-P**%f]]
            .. [[%-P**\"%f\"]]
            .. [[%E!\ LaTeX\ %trror:\ %m]]
            .. [[%E%f:%l:\ %m]]
            .. [[%E!\ %m]]
            .. [[%Z<argument>\ %m]]
            .. [[%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#]]
            .. [[%+W%.%#\ at\ lines\ %l--%*\\d]]
            .. [[%+WLaTeX\ %.%#Warning:\ %m]]
            .. [[%+W%.%#%.%#Warning:\ %m]]
            .. [[%-C(biblatex)%.%#in\ t%.%#]]
            .. [[%-C(biblatex)%.%#Please\ v%.%#]]
            .. [[%-C(biblatex)%.%#LaTeX\ a%.%#]]
            .. [[%-Z(biblatex)%m]]
            .. [[%-Z(babel)%.%#input\ line\ %l.]]
            .. [[%-C(babel)%m]]
            .. [[%-C(hyperref)%.%#on\ input\ line\ %l.]]
            .. [[%-G%.%#]]
    elseif ft == 'tex' then
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
        if vim.bo.filetype == 'tex' then
            cmd = { 'arara', '-p', 'minimize_runs' }
        end
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
        filetype = { 'python', 'bash', 'lua', 'tex' },
    },
}
