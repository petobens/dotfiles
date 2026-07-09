local adapters = require('codecompanion.adapters')
local extend = adapters.extend

local acp_helpers = require('plugin-config.codecompanion.helpers').acp

local M = {}

-- Credentials
local CLAUDE_OAUTH_TOKEN = 'cmd:pass show mutt/claude/oauth-token'
local GEMINI_API_KEY = 'cmd:pass show google/muttmail/gemini/api-key'
local GITHUB_TOKEN = 'cmd:pass show git/github/petobens/api-key'
local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local TAVILY_API_KEY = 'cmd:pass show tavily/yahoomail/api-key'

-- Helpers
local function disabled()
    return false
end

-- OpenAI
local function openai_responses_adapter(
    name,
    model,
    stream,
    context_window,
    reasoning_effort
)
    return extend('openai_responses', {
        name = name,
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = {
                default = model,
                choices = {
                    [model] = {
                        meta = {
                            context_window = context_window,
                        },
                        opts = {
                            can_reason = true,
                            can_manage_context = true,
                            has_function_calling = true,
                            has_vision = true,
                            stream = stream,
                        },
                    },
                },
            },
            ['reasoning.effort'] = { default = reasoning_effort or 'medium' },
            verbosity = { default = 'low' },
        },
        available_tools = {
            ['web_search'] = {
                enabled = disabled,
            },
        },
    })
end

function M.openai_gpt_55()
    return openai_responses_adapter('openai_gpt_55', 'gpt-5.5', true, 1000000)
end

function M.openai_gpt_54_nano()
    return openai_responses_adapter(
        'openai_gpt_54_nano',
        'gpt-5.4-nano',
        false,
        400000,
        'none'
    )
end

-- Google
function M.gemini_flash_35()
    return extend('gemini', {
        name = 'gemini_flash_35',
        env = { api_key = GEMINI_API_KEY },
        schema = {
            model = {
                default = 'gemini-3.5-flash',
                choices = {
                    ['gemini-3.5-flash'] = {
                        meta = {
                            context_window = 1048576,
                        },
                    },
                },
            },
            reasoning_effort = { default = 'none' },
        },
    })
end

-- Ollama (Qwen)
function M.ollama_qwen35_08b()
    return extend('ollama', {
        name = 'ollama_qwen35_08b',
        schema = {
            model = {
                default = 'qwen3.5:0.8b',
                choices = {
                    ['qwen3.5:0.8b'] = {
                        meta = {
                            context_window = 32768,
                        },
                    },
                },
            },
            think = { default = false },
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
                '-c',
                'sandbox_permissions=["disk-full-read-access"]',
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
                    [codex_config.model] = { meta = { context_window = 1000000 } },
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
                    [claude_config.model] = { meta = { context_window = 1000000 } },
                },
            },
        },
    })
end

-- Tools
function M.tavily()
    return extend('tavily', {
        env = { api_key = TAVILY_API_KEY },
    })
end

return M
