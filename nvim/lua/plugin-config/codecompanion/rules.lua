local codecompanion_rules = require('codecompanion.interactions.shared.rules')
local repo_helpers = require('plugin-config.codecompanion.helpers').repo
local u = require('utils')

local M = {}

-- Helpers
local function rule_file(path)
    return repo_helpers.git_root_file('AGENTS.md', path)
        or repo_helpers.git_root_file('CLAUDE.md', path)
end

local function rule_files()
    local file = rule_file(vim.uv.cwd())
    if file then
        return { file }
    end

    return {}
end

-- Globals
function M.edit_rule_file()
    local git_root = repo_helpers.git_root_or_notify()
    if not git_root then
        return
    end

    local file = rule_file(git_root)
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

    local file = rule_file(vim.uv.cwd())
    if file then
        codecompanion_rules.add_to_chat_from_config(chat, {
            name = 'default',
            files = { file },
        })
    end

    chat:refresh_context()
    vim.notify('Reloaded CodeCompanion rules', vim.log.levels.INFO)
end

-- Setup
function M.build()
    local files = rule_files()

    return {
        default = {
            description = 'Repo-root AI rules, AGENTS.md first, CLAUDE.md fallback',
            files = files,
            enabled = function()
                return not vim.tbl_isempty(rule_files())
            end,
            is_preset = true,
        },
        opts = {
            chat = {
                autoload = function()
                    return rule_file(vim.uv.cwd()) and 'default' or {}
                end,
                enabled = true,
            },
        },
    }
end

return M
