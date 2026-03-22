-- luacheck:ignore 631
local codecompanion = require('codecompanion')

local adapter_config = require('plugin-config.codecompanion.adapters')
local extensions = require('plugin-config.codecompanion.extensions')
local mappings = require('plugin-config.codecompanion.mappings')
local mcp = require('plugin-config.codecompanion.mcp')
local prompt_library = require('plugin-config.codecompanion.prompt_library')
local slash_commands = require('plugin-config.codecompanion.slash_commands')
local tools = require('plugin-config.codecompanion.tools')
local ui = require('plugin-config.codecompanion.ui')

local M = {}

-- Main CodeCompanion setup
function M.setup()
    codecompanion.setup({
        -- Adapters
        adapters = {
            http = {
                opts = {
                    show_presets = false,
                    show_model_choices = false,
                },
                openai_gpt_54 = adapter_config.openai_gpt_54,
                openai_gpt_54_nano = adapter_config.openai_gpt_54_nano,
                openai_gpt_54_nano_legacy = adapter_config.openai_gpt_54_nano_legacy,
                gemini_flash_3 = adapter_config.gemini_flash_3,
                ollama_qwen35_08b = adapter_config.ollama_qwen35_08b,
                tavily = adapter_config.tavily,
            },
            acp = {
                opts = {
                    show_presets = false,
                    show_model_choices = false,
                },
            },
        },
        -- Display
        display = {
            chat = {
                intro_message = '',
                icons = {
                    buffer_sync_all = ' ',
                    buffer_sync_diff = ' ',
                },
                window = {
                    layout = 'float',
                    border = 'rounded',
                    height = vim.o.lines - 5,
                    width = 0.45,
                    relative = 'editor',
                    col = vim.o.columns,
                    row = 1,
                    opts = { winfixbuf = true },
                },
                debug_window = {
                    width = math.floor(vim.o.columns * 0.535),
                    height = vim.o.lines - 4,
                },
            },
            action_palette = {
                prompt = '> ',
                opts = {
                    show_preset_actions = true,
                    show_preset_prompts = false,
                },
            },
            diff = { layout = 'vertical' },
        },
        -- Interactions
        interactions = {
            -- Chat
            chat = {
                adapter = 'openai_gpt_54',
                roles = {
                    user = 'Me',
                    llm = ui.llm_role,
                },
                opts = {
                    system_prompt = function()
                        return prompt_library.prompt('helpful_assistant')
                    end,
                    prompt_decorator = function(message)
                        return message
                    end,
                    goto_file_action = function(fname)
                        vim.cmd.wincmd('h')
                        vim.cmd.edit(fname)
                    end,
                },
                keymaps = mappings.chat_keymaps(),
                -- Slash commands
                slash_commands = slash_commands.build(),
                -- Tools
                tools = tools.build(),
                -- Editor context (variables)
                editor_context = {
                    ['buffer'] = {
                        opts = {
                            default_params = 'diff',
                        },
                    },
                },
            },
            -- Inline
            inline = {
                adapter = 'openai_gpt_54_nano',
            },
            -- Shared
            shared = {
                keymaps = mappings.shared_keymaps(),
            },
        },
        -- Prompt library
        prompt_library = prompt_library.build(),
        -- MCP
        mcp = mcp.build(),
        -- Extensions
        extensions = extensions.build(),
    })
end

return M
