local M = {}

-- Stop at the nearest project so a missing tool cannot come from a parent repo
function M.tool(name, source)
    local root = vim.fs.root(source or 0, {
        {
            'pyproject.toml',
            'setup.py',
            'setup.cfg',
            'requirements.txt',
            '.git',
            '.venv',
        },
    })
    if root then
        local executable = vim.fs.joinpath(root, '.venv', 'bin', name)
        if vim.fn.executable(executable) == 1 then
            return executable
        end
    end
    return name
end

return M
