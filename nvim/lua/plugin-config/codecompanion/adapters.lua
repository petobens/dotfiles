local adapters = require('codecompanion.adapters')
local extend = adapters.extend

local acp_helpers = require('plugin-config.codecompanion.helpers').acp

local M = {}

-- Credentials
local CLAUDE_OAUTH_TOKEN = 'cmd:pass show mutt/claude/oauth-token'
local GITHUB_TOKEN = 'cmd:pass show git/github/petobens/api-key'
local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'

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
        schema = {
            model = {
                choices = {
                    -- Codex exposes 95% of its current 272k-token product limit
                    [codex_config.model] = { meta = { context_window = 258400 } },
                },
            },
        },
    })
end

function M.claude_code()
    local claude_config = acp_helpers.claude_config()

    return extend('claude_code', {
        env = {
            CLAUDE_CODE_EXECUTABLE = '/usr/bin/claude',
            CLAUDE_CODE_OAUTH_TOKEN = CLAUDE_OAUTH_TOKEN,
            GITHUB_TOKEN = GITHUB_TOKEN,
        },
        defaults = {
            effort = claude_config.effort,
            session_config_options = {
                model = claude_config.model,
                mode = claude_config.mode,
            },
        },
        schema = {
            model = {
                choices = {
                    -- The opus[1m] suffix enables Claude Code's full extended context
                    [claude_config.model] = { meta = { context_window = 1000000 } },
                },
            },
        },
    })
end

return M
