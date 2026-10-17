local u = require('utils')

local adapters = require('codecompanion.adapters')
local extend = adapters.extend

local acp_helpers = require('plugin-config.codecompanion.helpers').acp
local build_messages = require('codecompanion.adapters.acp.helpers').build_messages

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

local function acp_messages(self, args)
    local parts = build_messages(self, args)
    -- Keep file markers separate from each other and the following user prompt
    for _, part in ipairs(parts) do
        if
            type(part.text) == 'string'
            and part.text:match('^Sharing the following file as context:')
        then
            part.text = part.text .. '\n'
        end
    end
    return parts
end

-- Credentials
local GITHUB_TOKEN = credential('GITHUB_TOKEN', 'git/github/petobens/api-key')
local OPENAI_API_KEY = credential('OPENAI_API_KEY', 'openai/yahoomail/apikey')

-- Inline editing and background titles
function M.openai_gpt_6_luna()
    return extend('openai', {
        name = 'openai_gpt_6_luna',
        env = { api_key = OPENAI_API_KEY },
        schema = {
            model = {
                default = 'gpt-6-luna',
                choices = {
                    ['gpt-6-luna'] = {
                        meta = {
                            context_window = 1050000,
                        },
                        opts = {
                            can_form_structured_outputs = true,
                            can_reason = true,
                            can_use_tools = true,
                            has_vision = true,
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
        handlers = { request = { build_messages = acp_messages } },
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
        handlers = { request = { build_messages = acp_messages } },
        env = {
            CLAUDE_CODE_EXECUTABLE = '/usr/bin/claude',
            GITHUB_TOKEN = GITHUB_TOKEN,
        },
        defaults = {
            effort = claude_config.effort,
            session_config_options = {
                -- Claude ACP resolves model aliases from settings.json itself
                mode = claude_config.mode,
            },
        },
    })
end

return M
