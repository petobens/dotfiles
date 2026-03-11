local adapters = require('codecompanion.adapters')

local M = {}

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local GEMINI_API_KEY = 'cmd:pass show google/muttmail/gemini/api-key'
local TAVILY_API_KEY = 'cmd:pass show tavily/yahoomail/api-key'

M.MODEL_CONTEXT_WINDOWS = {
    ['gpt-5.4'] = 400000,
    ['gpt-5-nano'] = 400000,
    ['gemini-3-pro-preview'] = 1048576,
    ['gemini-3-flash-preview'] = 1048576,
    ['qwen3.5:0.8b'] = 32768,
}

function M.openai_gpt_54()
    return adapters.extend('openai_responses', {
        name = 'openai_gpt_54',
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = {
                default = 'gpt-5.4',
                choices = {
                    ['gpt-5.4'] = {
                        opts = {
                            has_vision = true,
                            can_reason = true,
                            stream = true,
                        },
                    },
                },
            },
            ['reasoning.effort'] = { default = 'low' },
            verbosity = { default = 'low' },
            top_p = {
                enabled = function()
                    return false
                end,
            },
        },
        available_tools = {
            ['web_search'] = {
                enabled = function()
                    return false
                end,
            },
        },
    })
end

function M.openai_gpt_5_nano()
    return adapters.extend('openai_responses', {
        name = 'openai_gpt_5_nano',
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = {
                default = 'gpt-5-nano',
                choices = {
                    ['gpt-5-nano'] = {
                        opts = {
                            has_vision = true,
                            can_reason = true,
                            stream = false,
                        },
                    },
                },
            },
            ['reasoning.effort'] = { default = 'minimal' },
        },
    })
end

function M.openai_gpt_5_nano_legacy()
    return adapters.extend('openai', {
        name = 'openai_gpt_5_nano_legacy',
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = { default = 'gpt-5-nano' },
            reasoning_effort = { default = 'minimal' },
        },
    })
end

function M.gemini_pro_3()
    return adapters.extend('gemini', {
        name = 'gemini_pro_3',
        env = { api_key = GEMINI_API_KEY },
        schema = {
            model = { default = 'gemini-3-pro-preview' },
        },
    })
end

function M.gemini_flash_3()
    return adapters.extend('gemini', {
        name = 'gemini_flash_3',
        env = { api_key = GEMINI_API_KEY },
        schema = {
            model = { default = 'gemini-3-flash-preview' },
            reasoning_effort = { default = 'none' },
        },
    })
end

function M.ollama_qwen35_08b()
    return adapters.extend('ollama', {
        name = 'ollama_qwen35_08b',
        schema = {
            model = { default = 'qwen3.5:0.8b' },
            think = { default = false },
        },
    })
end

function M.tavily()
    return adapters.extend('tavily', {
        env = { api_key = TAVILY_API_KEY },
    })
end

return M
