local M = {}

-- Config
function M.build()
    return {
        agent = 'claude_code',
        agents = {
            codex = {
                cmd = 'codex',
            },
            claude_code = {
                cmd = 'claude',
            },
        },
    }
end

return M
