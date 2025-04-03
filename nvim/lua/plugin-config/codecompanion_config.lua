-- luacheck:ignore 631

local adapters = require('codecompanion.adapters')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')

-- FIXME:
-- Add blank lines to system and user roles: https://github.com/olimorris/codecompanion.nvim/issues/959

-- TODO:
-- Custom prompts (a.k.a roles) and system role
-- https://github.com/olimorris/dotfiles/blob/main/.config/nvim/lua/plugins/coding.lua#L81
-- https://codecompanion.olimorris.dev/extending/prompts.html
-- Feature parity con prompts en chatgpt plugin
-- Agregar "writer prompt" pasando files de como escribo yo con los memos de Ops (references)

-- Send to input to different models
-- Also add gemini 2.5 pro model
-- https://github.com/olimorris/codecompanion.nvim/discussions/1153#discussioncomment-12560883

-- Create slash commands: https://github.com/olimorris/codecompanion.nvim/discussions/958
-- For git files, a specific and pyproject.toml root dir
-- https://github.com/olimorris/codecompanion.nvim/pull/960/files
-- Feature to pass a path to file slash commands: https://github.com/olimorris/codecompanion.nvim/discussions/947
-- Possible to share a PDF file?

-- Mapping to show open chats in telescope and move between chats (select which default
-- actions/prompts when to show rather than having a boolean)

-- Use/mappings for inline diffs

-- Not saving sessions: https://github.com/olimorris/codecompanion.nvim/discussions/139
-- https://github.com/olimorris/codecompanion.nvim/discussions/1098
-- https://github.com/olimorris/codecompanion.nvim/discussions/1129

-- Check how to use agents/tools (i.e @ commands, tipo @editor para que hagan acciones)

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local SYSTEM_ROLE = '󰮥 Helpful Assistant'
local SYSTEM_ROLE_PROMPT = [[
You are a helpful and friendly AI assistant.
Answer questions accurately and provide detailed explanations when necessary.
]]

-- Helpers
local function get_current_system_role_prompt()
    local chat = codecompanion.buf_get_chat()
    local messages = chat[1].chat.messages
    local system_role = nil
    for _, entry in ipairs(messages) do
        if entry.role == 'system' then
            system_role = entry.content
        end
    end
    return system_role
end

-- Setup
codecompanion.setup({
    adapters = {
        opts = {
            show_defaults = false,
        },
        openai_gpt_4o = function()
            return adapters.extend('openai', {
                env = { api_key = OPENAI_API_KEY },
                schema = {
                    model = { default = 'gpt-4o' },
                    max_tokens = { default = 2048 },
                    temperature = { default = 0.2 },
                    top_p = { default = 0.1 },
                },
            })
        end,
        openai_o3_mini = function()
            return adapters.extend('openai', {
                env = { api_key = OPENAI_API_KEY },
                schema = {
                    model = { default = 'o3-mini-2025-01-31' },
                },
            })
        end,
    },
    display = {
        chat = {
            intro_message = '',
            icons = {
                pinned_buffer = ' ',
                watched_buffer = ' ',
            },
            window = {
                layout = 'float',
                border = 'rounded',
                height = vim.o.lines - 5, -- (tabline, statuline and cmdline height + row)
                width = 0.45,
                relative = 'editor',
                col = vim.o.columns, -- right position
                row = 1,
                opts = {},
            },
            debug_window = {
                width = math.floor(vim.o.columns * 0.535),
                height = vim.o.lines - 4,
            },
        },
        action_palette = {
            prompt = '> ',
            provider = 'telescope',
            opts = {
                show_default_prompt_library = false,
                show_default_actions = false,
            },
        },
    },
    strategies = {
        chat = {
            adapter = 'openai_gpt_4o', -- default adapter
            roles = {
                user = 'Me',
                llm = function(adapter)
                    local current_system_role_prompt = get_current_system_role_prompt()
                    local system_role = SYSTEM_ROLE

                    for name, prompt in pairs(config.prompt_library) do
                        local prompt_content = prompt.prompts[1]
                            and prompt.prompts[1].content
                        if
                            type(prompt_content) == 'string'
                            and prompt_content == current_system_role_prompt
                        then
                            system_role = name
                            break
                        end
                    end
                    return string.format(
                        '%s (%s) | %s',
                        adapter.formatted_name,
                        adapter.schema.model.default,
                        system_role
                    )
                end,
            },
            keymaps = {
                send = { modes = { n = '<C-o>', i = '<C-o>' } },
                close = {
                    modes = { n = '<C-c>', i = '<C-c>' },
                    callback = function()
                        codecompanion.toggle()
                        vim.defer_fn(function()
                            vim.cmd('stopinsert')
                        end, 1)
                    end,
                },
                stop = { modes = { n = '<C-x>', i = '<C-x>' } },
                yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
                options = { modes = { n = '<A-h>', i = '<A-h>' } },
                previous_header = { modes = { n = '<C-[>' } },
                next_header = { modes = { n = '<C-]>' } },
                change_adapter = { modes = { n = '<Leader>cm' } },
                debug = { modes = { n = '<Leader>db' } },
                pin = { modes = { n = '<Leader>rp' } },
                watch = { modes = { n = '<Leader>rw' } },
                system_prompt = { modes = { n = '<Leader>ts' } },
            },
            slash_commands = {
                ['buffer'] = { opts = { provider = 'telescope' } },
                ['file'] = { opts = { provider = 'telescope' } },
            },
        },
    },
    opts = {
        system_prompt = function()
            return SYSTEM_ROLE_PROMPT
        end,
    },
    prompt_library = {
        [SYSTEM_ROLE] = {
            strategy = 'chat',
            description = 'Act as a helpful assistant.',
            opts = {
                short_name = 'assistant',
                is_slash_cmd = true,
                auto_submit = false,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = SYSTEM_ROLE_PROMPT,
                    opts = { visible = true },
                },
                {
                    role = 'user',
                    content = [[]],
                },
            },
        },
        [' Bash Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Bash developer.',
            opts = {
                short_name = 'bash',
                is_slash_cmd = true,
                auto_submit = false,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert Bash developer.
When giving code examples show the generated output.
]],
                    opts = { visible = true },
                },
                {
                    role = 'user',
                    content = [[]],
                },
            },
        },
        [' Lua Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Lua developer.',
            opts = {
                short_name = 'lua',
                is_slash_cmd = true,
                auto_submit = false,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert Lua developer.
Use a lua version that is compatible with the neovim editor (i.e 5.1).
When giving code examples show the generated output.
]],

                    opts = { visible = true },
                },
                {
                    role = 'user',
                    content = [[]],
                },
            },
        },
    },
})

-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register('markdown', 'codecompanion')

-- Override the default icon for codecompanion filetype
local devicons = require('nvim-web-devicons')
devicons.set_icon({
    codecompanion = { icon = ' ' },
})
devicons.set_icon_by_filetype({ codecompanion = 'codecompanion' })

-- Show a spinner loading indicator when a request is being made
local spinner_states = { '', '', '' }
local current_state = 1
local timer = vim.loop.new_timer()
local ns_id = vim.api.nvim_create_namespace('codecompanion_loading_spinner')
local spinner_line = nil

local function update_spinner()
    if spinner_line then
        vim.api.nvim_buf_clear_namespace(0, ns_id, spinner_line, spinner_line + 1)
        vim.api.nvim_buf_set_virtual_text(
            0,
            ns_id,
            spinner_line,
            { { ' Loading ' .. spinner_states[current_state], 'Comment' } },
            {}
        )
        current_state = current_state % #spinner_states + 1
    end
end

vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionRequestStarted',
    callback = function()
        vim.defer_fn(function()
            vim.cmd('stopinsert')
        end, 1)
        spinner_line = vim.api.nvim_win_get_cursor(0)[1] - 1
        timer:start(0, 250, vim.schedule_wrap(update_spinner))
    end,
})
vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionRequestStreaming',
    callback = function()
        timer:stop()
        if spinner_line then
            vim.api.nvim_buf_clear_namespace(0, ns_id, spinner_line, spinner_line + 1)
            spinner_line = nil
        end
    end,
})
vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionRequestFinished',
    callback = function()
        if spinner_line then
            -- /fetch doesn't trigger RequestStreaming event so we also clear spinner here
            vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
            spinner_line = nil
        end
        vim.defer_fn(function()
            vim.cmd('startinsert')
        end, 1)
    end,
})

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true }),
    pattern = { 'codecompanion' },
    callback = function(e)
        -- Mappings
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf })
        vim.keymap.set({ 'i', 'n' }, '<A-p>', function()
            local chat = codecompanion.buf_get_chat()
            vim.print(
                string.format('Model Params:\n%s', vim.inspect(chat[1].chat.settings))
            )
        end, { buffer = e.buf })
        vim.keymap.set({ 'i', 'n' }, '<A-r>', function()
            local system_role = get_current_system_role_prompt()
            if system_role then
                vim.print(string.format('System Role:\n%s', system_role))
            end
        end, { buffer = e.buf })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>xx', function()
    -- Focus window if already open (we simply search for a floating window)
    for w = 1, vim.fn.winnr('$') do
        local win_id = vim.fn.win_getid(w)
        local win_conf = vim.api.nvim_win_get_config(win_id)
        if win_conf.focusable and win_conf.relative ~= '' and win_conf.zindex == 45 then
            vim.api.nvim_set_current_win(win_id)
            return
        end
    end

    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd('startinsert')
    end, 1)
end)
vim.keymap.set({ 'n', 'v' }, '<Leader>xa', '<Cmd>CodeCompanionActions<CR>')
