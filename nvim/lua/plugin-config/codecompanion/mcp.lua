-- luacheck:ignore 631
local M = {}

-- Commands
local GITHUB_MCP_CMD = {
    'docker',
    'run',
    '-i',
    '--rm',
    '-e',
    'GITHUB_PERSONAL_ACCESS_TOKEN',
    'ghcr.io/github/github-mcp-server',
}

-- Setup
local mcp = {
    servers = {
        github = {
            cmd = GITHUB_MCP_CMD,
            env = {
                GITHUB_PERSONAL_ACCESS_TOKEN = 'cmd:pass show git/github/petobens/api-key',
            },
        },
    },
}

function M.build()
    return mcp
end

return M
