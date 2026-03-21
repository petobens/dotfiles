-- luacheck:ignore 631
local M = {}

function M.build()
    return {
        servers = {
            github = {
                cmd = {
                    'docker',
                    'run',
                    '-i',
                    '--rm',
                    '-e',
                    'GITHUB_PERSONAL_ACCESS_TOKEN',
                    'ghcr.io/github/github-mcp-server',
                },
                env = {
                    GITHUB_PERSONAL_ACCESS_TOKEN = 'cmd:pass show git/github/petobens/api-key',
                },
            },
        },
    }
end

return M
