local module_prefix = 'plugin-config.codecompanion.'

local adapters = require(module_prefix .. 'adapters')
local background = require(module_prefix .. 'background')
local cli = require(module_prefix .. 'cli')
local mappings = require(module_prefix .. 'mappings')
local monkeypatches = require(module_prefix .. 'monkeypatches')
local prompt_library = require(module_prefix .. 'prompt_library')
local slash_commands = require(module_prefix .. 'slash_commands')
local ui = require(module_prefix .. 'ui')

local M = {}

local function remove_agent_features()
    local config = require('codecompanion.config')
    local opts = config.interactions.chat.tools.opts
    config.interactions.chat.tools = { groups = {}, opts = opts }
    config.interactions.chat.slash_commands.mcp = nil
    config.interactions.chat.slash_commands.rules = nil
end

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
                    show_preset_actions = false,
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
            -- Background
            background = background.build(adapters.openai_gpt_56_luna()),
            -- Chat
            chat = {
                adapter = 'codex',
                roles = {
                    user = 'Me',
                    llm = ui.llm_role,
                },
                opts = {
                    goto_file_action = function(fname)
                        vim.cmd.wincmd('h')
                        vim.cmd.edit(fname)
                    end,
                },
                keymaps = mappings.chat_keymaps(),
                slash_commands = slash_commands.build(),
            },
            -- CLI
            cli = cli.build(),
            -- Shared
            shared = {
                editor_context = {
                    buffer = {
                        opts = {
                            default_params = 'diff',
                        },
                    },
                },
                keymaps = mappings.shared_keymaps(),
            },
        },
        -- Prompt library
        prompt_library = prompt_library.build(),
        -- Disable rules since ACP agents load repository instructions themselves
        rules = {
            opts = {
                chat = { autoload = false, enabled = false },
                show_presets = false,
            },
        },
    })

    -- ACP agents provide their own tools and MCP servers
    remove_agent_features()

    -- UI specific
    ui.setup()

    -- Mappings
    local group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true })
    cli.setup_mappings(group)
    mappings.setup(group)
    slash_commands.setup_mappings(group)

    -- Local CodeCompanion monkey patches
    monkeypatches.apply()
end

return M
