return {
    name = 'run_sphinx_build',
    builder = function()
        local package_manager = (
            next(_G.PyVenv.active_venv) and _G.PyVenv.active_venv.package_manager
        ) or 'uv'
        return {
            cwd = vim.fn.fnamemodify(
                vim.fn.findfile('pyproject.toml', vim.fn.getcwd() .. ';'),
                ':p:h'
            ) .. '/docs',
            cmd = { package_manager, 'run', 'make', 'html' },
            components = {
                { 'on_complete_notify', statuses = { 'SUCCESS' } },
                { 'on_output_quickfix', open_on_match = true, close = true },
                'default',
            },
            default_component_params = {
                errorformat = ''
                    .. [[%E%f:%l: SEVER%t: %m,]]
                    .. [[%f:%l: %tRROR: %m,]]
                    .. [[%f:%l: %tARNING: %m,]]
                    .. [[%E%f:: SEVER%t: %m,]]
                    .. [[%f:: %tRROR: %m,]]
                    .. [[%f:: %tARNING: %m,]]
                    .. [[%trror: %m,]]
                    .. [[%+W%.%#:%m\ (%f,\ line\ %l),]]
                    .. [[%-G%.%#,]],
            },
        }
    end,
    condition = {
        filetype = { 'markdown', 'python' },
    },
}
