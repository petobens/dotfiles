local codecompanion_config = require('codecompanion.config')
local codecompanion_rules = require('codecompanion.interactions.shared.rules')
local repo_helpers = require('plugin-config.codecompanion.helpers').repo
local u = require('utils')

local M = {}
local RULES_DIR = vim.fs.normalize(
    vim.fs.joinpath(vim.env.HOME, 'git-repos', 'private', 'ai-harness', 'rules')
)

-- Helpers
local function user_rule_file()
    local user_rules = vim.fs.joinpath(RULES_DIR, 'USER.md')
    local stat = vim.uv.fs_stat(user_rules)
    if stat and stat.type == 'file' then
        return user_rules
    end
    return nil
end

local function repo_rule_file(path)
    return repo_helpers.git_root_file('AGENTS.md', path)
        or repo_helpers.git_root_file('CLAUDE.md', path)
end

local function rule_files(path)
    local files = {}
    local user_file = user_rule_file()
    if user_file then
        table.insert(files, user_file)
    end
    local file = repo_rule_file(path or vim.uv.cwd())
    if file then
        table.insert(files, file)
    end

    return files
end

-- Globals
function M.edit_repo_rule_file()
    local git_root = repo_helpers.git_root_or_notify()
    if not git_root then
        return
    end

    local file = repo_rule_file(git_root)
    if not file then
        vim.notify(
            'Could not find AGENTS.md or CLAUDE.md in the current git repository root',
            vim.log.levels.WARN
        )
        return
    end

    u.split_open(file)
end

function M.reload_chat_rules(chat)
    chat:remove_tagged_message('rules')
    chat:refresh_context()

    local files = rule_files()
    if not vim.tbl_isempty(files) then
        codecompanion_rules.add_to_chat_from_config(chat, {
            name = 'default',
            files = files,
        })
    end

    chat:refresh_context()
    vim.notify('Reloaded CodeCompanion rules', vim.log.levels.INFO)
end

-- Setup
function M.build()
    return {
        default = {
            description = 'USER rules plus repo-root AGENTS.md or CLAUDE.md',
            files = {},
            is_preset = true,
        },
        opts = {
            chat = {
                autoload = function()
                    -- Resolve files at chat-open time, not startup
                    local bufname = vim.api.nvim_buf_get_name(0)
                    local dir = bufname ~= '' and vim.fs.dirname(bufname) or vim.uv.cwd()
                    local files = rule_files(dir)
                    codecompanion_config.rules.default.files = files
                    return not vim.tbl_isempty(files) and 'default' or {}
                end,
                enabled = true,
            },
        },
    }
end

return M
