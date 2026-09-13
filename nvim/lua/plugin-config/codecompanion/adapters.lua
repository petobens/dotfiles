local u = require('utils')

local adapters = require('codecompanion.adapters')
local extend = adapters.extend

local acp_helpers = require('plugin-config.codecompanion.helpers').acp

local M = {}

-- Helpers
local function credential(env_var, pass_entry)
    return function()
        local value = vim.env[env_var]
        if value and value ~= '' then
            return value
        end
        return u.resolve_pass(pass_entry)
    end
end

-- Credentials
local GITHUB_TOKEN = credential('GITHUB_TOKEN', 'git/github/petobens/api-key')
local OPENAI_API_KEY = credential('OPENAI_API_KEY', 'openai/yahoomail/apikey')

-- Background title generation
function M.openai_gpt_56_luna()
    return extend('openai_responses', {
        name = 'openai_gpt_56_luna',
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = {
                default = 'gpt-5.6-luna',
                choices = {
                    ['gpt-5.6-luna'] = {
                        meta = {
                            context_window = 1050000,
                        },
                        opts = {
                            can_form_structured_outputs = true,
                            can_reason = true,
                            can_use_tools = false,
                            has_vision = false,
                            stream = false,
                        },
                    },
                },
            },
            ['reasoning.effort'] = { default = 'none' },
            verbosity = { default = 'low' },
        },
    })
end

-- ACP
function M.codex()
    local codex_config = acp_helpers.codex_config()

    return extend('codex', {
        env = {
            GITHUB_TOKEN = GITHUB_TOKEN,
        },
        commands = {
            default = {
                'codex-acp',
            },
        },
        defaults = {
            auth_method = 'chat-gpt',
            effort = codex_config.effort,
            session_config_options = {
                model = codex_config.model,
            },
        },
    })
end

function M.claude_code()
    local claude_config = acp_helpers.claude_config()

    return extend('claude_code', {
        env = {
            CLAUDE_CODE_EXECUTABLE = '/usr/bin/claude',
            -- An unset string env reference becomes literal instead of using native auth
            CLAUDE_CODE_OAUTH_TOKEN = function()
                return vim.env.CLAUDE_CODE_OAUTH_TOKEN
            end,
            GITHUB_TOKEN = GITHUB_TOKEN,
        },
        defaults = {
            effort = claude_config.effort,
            session_config_options = {
                model = claude_config.model,
                mode = claude_config.mode,
            },
        },
    })
end

return M
