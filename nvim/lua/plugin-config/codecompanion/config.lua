local adapter_config = require('plugin-config.codecompanion.adapters')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local keymaps = require('codecompanion.interactions.chat.keymaps')
local u = require('utils')

local helpers = require('plugin-config.codecompanion.helpers')
local prompt_library = require('plugin-config.codecompanion.prompt_library')
local slash_commands = require('plugin-config.codecompanion.slash_commands')

local M = {}

-- Chat role label helper
local function llm_role(adapter)
    local current_system_role_prompt = helpers.get_current_system_role_prompt()
    local system_role = prompt_library.SYSTEM_ROLE

    for name, prompt in pairs(config.prompt_library or {}) do
        local prompts = prompt and prompt.prompts
        if type(prompts) == 'table' then
            local first = prompts[1]
            if first and type(first.content) == 'string' then
                if first.content == current_system_role_prompt then
                    system_role = name
                    break
                end
            end
        end
    end

    return string.format(
        '%s (%s) | %s |  %d |  %s',
        adapter.formatted_name,
        adapter.schema.model.default,
        system_role,
        helpers.get_chat_cycles(),
        helpers.get_context_usage(adapter)
    )
end

-- Chat window keymap callbacks
local function hide_chats()
    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
    end, 1)
end

local function send_message(chat)
    vim.cmd.stopinsert()
    keymaps.send.callback(chat)
end

local function open_options()
    keymaps.options.callback()
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        vim.api.nvim_win_set_width(0, math.min(160, vim.o.columns))
    end, 1)
end

local function open_debug(chat)
    keymaps.debug.callback(chat)
    vim.defer_fn(function()
        vim.cmd.stopinsert()
        local win = vim.api.nvim_get_current_win()
        local win_config = vim.api.nvim_win_get_config(win)
        if win_config.relative == 'editor' then
            win_config.col = 1
            vim.api.nvim_win_set_config(win, win_config)
        end
    end, 1)
end

-- Main setup
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
                openai_gpt_5_nano = adapter_config.openai_gpt_5_nano,
                openai_gpt_5_nano_legacy = adapter_config.openai_gpt_5_nano_legacy,
                gemini_pro_3 = adapter_config.gemini_pro_3,
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
                    llm = llm_role,
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
                keymaps = {
                    create_chat = {
                        modes = { n = '<A-c>', i = '<A-c>' },
                        description = 'Create new chat',
                        callback = vim.cmd.CodeCompanionChat,
                    },
                    close = { modes = { n = '<A-x>', i = '<A-x>' } },
                    hide_chats = {
                        modes = { n = '<C-c>', i = '<C-c>' },
                        description = 'Hide chats',
                        callback = hide_chats,
                    },
                    next_chat = { modes = { n = '<A-n>', i = '<A-n>' } },
                    previous_header = { modes = { n = '<C-[>', i = '<C-[>' } },
                    next_header = { modes = { n = '<C-]>', i = '<C-]>' } },
                    send = {
                        modes = { n = '<C-o>', i = '<C-o>' },
                        description = 'Send message',
                        callback = send_message,
                    },
                    stop = { modes = { n = '<C-x>', i = '<C-x>' } },
                    clear = { modes = { n = '<A-w>', i = '<A-w>' } },
                    yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
                    fold_code = { modes = { n = 'zc' } },
                    goto_file_under_cursor = { modes = { n = 'gf' } },
                    options = {
                        modes = { n = '<A-h>', i = '<A-h>' },
                        callback = open_options,
                    },
                    change_adapter = { modes = { n = '<A-m>', i = '<A-m>' } },
                    debug = {
                        modes = { n = '<A-d>', i = '<A-d>' },
                        callback = open_debug,
                    },
                    buffer_sync_all = { modes = { n = '<Leader>rp' } },
                    buffer_sync_diff = { modes = { n = '<Leader>rw' } },
                    system_prompt = { modes = { n = '<Leader>ts' } },
                    action_palette = {
                        modes = { n = '<A-a>', i = '<A-a>' },
                        description = 'Action palette',
                        callback = vim.cmd.CodeCompanionActions,
                    },
                },
                -- Slash commands
                slash_commands = slash_commands.build(),
                -- Tools
                tools = {
                    read_file = {
                        opts = {
                            require_approval_before = false,
                        },
                    },
                },
                -- Editor context
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
                adapter = 'openai_gpt_5_nano',
            },

            -- Shared
            shared = {
                keymaps = {
                    always_accept = { modes = { n = 'aa' } },
                    accept_change = { modes = { n = 'dp' } },
                    reject_change = { modes = { n = 'de' } },
                    next_hunk = { modes = { n = ']h' } },
                    previous_hunk = { modes = { n = '[h' } },
                },
            },
        },
        -- Prompt library
        prompt_library = prompt_library.build(),
        -- Extensions
        extensions = {
            history = {
                enabled = true,
                opts = {
                    auto_generate_title = u.is_online(),
                    title_generation_opts = {
                        adapter = 'openai_gpt_5_nano_legacy',
                        model = 'gpt-5-nano',
                        refresh_every_n_prompts = 3,
                        max_refreshes = 10,
                    },
                    auto_save = true,
                    expiration_days = 30,
                    keymap = { n = '<A-s>', i = '<A-s>' },
                    picker_keymaps = {
                        rename = { n = 'r', i = '<A-r>' },
                        delete = { n = 'd', i = '<A-d>' },
                    },
                    save_chat_keymap = { n = '<nop>', i = '<nop>' },
                },
            },
        },
    })
end

return M
