local adapters = require('codecompanion.adapters')
local extend = adapters.extend

local M = {}

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local GEMINI_API_KEY = 'cmd:pass show google/muttmail/gemini/api-key'
local TAVILY_API_KEY = 'cmd:pass show tavily/yahoomail/api-key'
local CLAUDE_OAUTH_TOKEN = 'cmd:pass show mutt/claude/oauth-token'

-- Helpers
local function disabled()
    return false
end

-- OpenAI
local function openai_responses_adapter(name, model, stream, context_window)
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
                            has_vision = true,
                            can_reason = true,
                            stream = stream,
                        },
                    },
                },
            },
            ['reasoning.effort'] = { default = 'low' },
            verbosity = { default = 'low' },
            top_p = {
                enabled = disabled,
            },
        },
        available_tools = {
            ['web_search'] = {
                enabled = disabled,
            },
        },
    })
end

function M.openai_gpt_54()
    return openai_responses_adapter('openai_gpt_54', 'gpt-5.4', true, 400000)
end

function M.openai_gpt_54_nano()
    return openai_responses_adapter('openai_gpt_54_nano', 'gpt-5.4-nano', false, 400000)
end

function M.openai_gpt_54_nano_legacy()
    return extend('openai', {
        name = 'openai_gpt_54_nano_legacy',
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = {
                default = 'gpt-5.4-nano',
                choices = {
                    ['gpt-5.4-nano'] = {
                        meta = {
                            context_window = 400000,
                        },
                    },
                },
            },
            reasoning_effort = { default = 'none' },
        },
    })
end

-- Google
function M.gemini_flash_3()
    return extend('gemini', {
        name = 'gemini_flash_3',
        env = { api_key = GEMINI_API_KEY },
        schema = {
            model = {
                default = 'gemini-3-flash-preview',
                choices = {
                    ['gemini-3-flash-preview'] = {
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
    return extend('codex', {
        env = {
            OPENAI_API_KEY = OPENAI_API_KEY,
        },
        defaults = {
            model = 'gpt-5.4',
        },
    })
end

function M.claude_code()
    return extend('claude_code', {
        env = {
            CLAUDE_CODE_EXECUTABLE = '/usr/bin/claude',
            CLAUDE_CODE_OAUTH_TOKEN = CLAUDE_OAUTH_TOKEN,
        },
        defaults = {
            model = 'opus',
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
