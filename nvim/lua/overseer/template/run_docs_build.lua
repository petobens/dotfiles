return {
    generator = function(opts)
        local project_root = vim.fs.root(opts.dir, 'zensical.toml')
        if not project_root then
            return {}
        end
        return {
            {
                name = 'run_docs_build',
                builder = function()
                    return {
                        cwd = project_root,
                        cmd = { 'just', 'docs-local' },
                        components = {
                            { 'on_complete_notify', statuses = { 'SUCCESS' } },
                            { 'on_output_quickfix', open_on_match = true, close = true },
                            'default',
                        },
                    }
                end,
            },
        }
    end,
    condition = {
        filetype = { 'markdown', 'python', 'toml' },
    },
}
