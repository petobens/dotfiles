local codecompanion_config = require('codecompanion.config')
local codecompanion_rules = require('codecompanion.interactions.shared.rules')
local repo_helpers = require('plugin-config.codecompanion.helpers').repo
local u = require('utils')

local M = {}

-- Constants
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

local function rule_files(opts)
    opts = opts or {}

    local files = {}
    local user_file = user_rule_file()
    if user_file then
        table.insert(files, user_file)
    end

    if opts.skip_repo_rules then
        return files
    end

    local file = repo_rule_file(opts.path or vim.uv.cwd())
    if file then
        table.insert(files, file)
    end

    return files
end

local function edit_repo_rule_file()
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

local function reload_chat_rules(chat)
    chat:remove_tagged_message('rules')
    chat:refresh_context()

    local files = rule_files({ skip_repo_rules = chat.adapter.type == 'acp' })
    if not vim.tbl_isempty(files) then
        codecompanion_rules.add_to_chat_from_config(chat, {
            name = 'default',
            files = files,
        })
    end

    chat:refresh_context()
    vim.notify('Reloaded CodeCompanion rules', vim.log.levels.INFO)
end

-- Config
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
                    local adapter_name = codecompanion_config.interactions.chat.adapter
                    local bufname = vim.api.nvim_buf_get_name(0)
                    local dir = bufname ~= '' and vim.fs.dirname(bufname) or vim.uv.cwd()
                    local files = rule_files({
                        path = dir,
                        skip_repo_rules = codecompanion_config.adapters.acp[adapter_name]
                            ~= nil,
                    })
                    codecompanion_config.rules.default.files = files
                    return not vim.tbl_isempty(files) and 'default' or {}
                end,
                enabled = true,
            },
        },
    }
end

-- Mappings
function M.chat_keymaps()
    return {
        rules = {
            modes = { n = '<Leader>rc', i = '<Leader>rc' },
        },
        reload_rules = {
            modes = { n = '<Leader>rl', i = '<Leader>rl' },
            description = 'Reload CodeCompanion rules',
            callback = function(chat)
                vim.cmd.stopinsert()
                reload_chat_rules(chat)
            end,
        },
    }
end

function M.setup_mappings()
    vim.keymap.set('n', '<Leader>ea', edit_repo_rule_file, {
        desc = 'Edit repo AI rules file',
    })
end

return M
