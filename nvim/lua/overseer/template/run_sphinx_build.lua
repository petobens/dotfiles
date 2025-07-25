return {
    name = 'run_sphinx_build',
    builder = function()
        local pyvenv = (_G.PyVenv and _G.PyVenv.active_venv) or {}
        local package_manager = pyvenv.package_manager or 'uv'
        local project_root = vim.fs.root(0, 'pyproject.toml')
        local docs_dir = vim.fs.joinpath(project_root, 'docs')
        return {
            cwd = docs_dir,
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
