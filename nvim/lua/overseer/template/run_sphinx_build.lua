return {
    generator = function(opts)
        local project_root = vim.fs.root(opts.dir, 'pyproject.toml')
        if not project_root then
            return {}
        end
        local docs_dir = vim.fs.joinpath(project_root, 'docs')
        local config = vim.uv.fs_stat(vim.fs.joinpath(docs_dir, 'source', 'conf.py'))
        if not config or config.type ~= 'file' then
            return {}
        end
        return {
            {
                name = 'run_sphinx_build',
                builder = function()
                    return {
                        cwd = docs_dir,
                        cmd = {
                            'uv',
                            'run',
                            '--no-sync',
                            'sphinx-build',
                            '-M',
                            'html',
                            'source',
                            'build',
                            '-W',
                            '--keep-going',
                        },
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
            },
        }
    end,
    condition = {
        filetype = { 'markdown', 'python' },
    },
}
