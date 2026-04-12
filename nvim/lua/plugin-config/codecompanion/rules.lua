local M = {}

-- Helpers
local function repo_root()
    local cwd = vim.uv.cwd() or vim.fn.getcwd()
    return vim.fs.root(cwd, '.git')
end

local function primary_repo_rule_files()
    local root = repo_root()
    if not root then
        return {}
    end

    local agents = vim.fs.joinpath(root, 'AGENTS.md')
    if vim.uv.fs_stat(agents) then
        return { agents }
    end

    local claude = vim.fs.joinpath(root, 'CLAUDE.md')
    if vim.uv.fs_stat(claude) then
        return { claude }
    end

    return {}
end

local function has_primary_repo_rule_files()
    return not vim.tbl_isempty(primary_repo_rule_files())
end

function M.build()
    local files = primary_repo_rule_files()

    return {
        default = {
            description = 'Repo-root AI rules, AGENTS.md first, CLAUDE.md fallback',
            files = files,
            enabled = has_primary_repo_rule_files,
            is_preset = true,
        },
        opts = {
            chat = {
                autoload = function()
                    return has_primary_repo_rule_files() and 'default' or {}
                end,
                enabled = true,
            },
        },
    }
end

return M
