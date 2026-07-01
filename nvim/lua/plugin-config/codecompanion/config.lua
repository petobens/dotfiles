local module_prefix = 'plugin-config.codecompanion.'

local adapters = require(module_prefix .. 'adapters')
local cli = require(module_prefix .. 'cli')
local extensions = require(module_prefix .. 'extensions')
local mappings = require(module_prefix .. 'mappings')
local mcp = require(module_prefix .. 'mcp')
local prompt_library = require(module_prefix .. 'prompt_library')
local rules = require(module_prefix .. 'rules')
local slash_commands = require(module_prefix .. 'slash_commands')
local tools = require(module_prefix .. 'tools')
local ui = require(module_prefix .. 'ui')

local M = {}

function M.setup()
    -- General config
    require('codecompanion').setup({
        -- Adapters
        adapters = {
            http = {
                opts = {
                    show_presets = false,
                    show_model_choices = false,
                },
                openai_gpt_55 = adapters.openai_gpt_55,
                openai_gpt_54_nano = adapters.openai_gpt_54_nano,
                openai_gpt_54_nano_legacy = adapters.openai_gpt_54_nano_legacy,
                gemini_flash_35 = adapters.gemini_flash_35,
                ollama_qwen35_08b = adapters.ollama_qwen35_08b,
                tavily = adapters.tavily,
            },
            acp = {
                opts = {
                    show_presets = false,
                    show_model_choices = false,
                },
                claude_code = adapters.claude_code,
                codex = adapters.codex,
            },
        },
        -- Display
        display = {
            chat = ui.chat_display(),
            action_palette = {
                prompt = '> ',
                opts = {
                    show_preset_actions = true,
                    show_preset_prompts = false,
                },
            },
            diff = {
                layout = 'vertical',
                threshold_for_chat = 15,
            },
        },
        -- Interactions
        interactions = {
            -- Chat
            chat = {
                adapter = 'claude_code',
                roles = {
                    user = 'Me',
                    llm = ui.llm_role,
                },
                opts = {
                    context_management = {
                        editing = {
                            trigger = 0.99,
                        },
                        compaction = {
                            trigger = 0.99,
                        },
                    },
                    system_prompt = function(ctx)
                        if ctx.adapter and ctx.adapter.type == 'acp' then
                            return ''
                        end
                        return 'You are a helpful assistant.'
                    end,
                    prompt_decorator = function(message)
                        return message
                    end,
                    goto_file_action = function(fname)
                        vim.cmd.wincmd('h')
                        vim.cmd.edit(fname)
                    end,
                },
                keymaps = vim.tbl_extend(
                    'force',
                    mappings.chat_keymaps(),
                    rules.chat_keymaps()
                ),
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
            -- CLI
            cli = cli.build(),
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
        -- Rules
        rules = rules.build(),
        -- Extensions
        extensions = extensions.build(),
    })
    -- UI specific
    ui.setup()
    -- Mappings
    local group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true })
    cli.setup_mappings(group)
    mappings.setup(group)
    rules.setup_mappings()
    slash_commands.setup_mappings(group)
end

return M
