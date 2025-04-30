-- luacheck:ignore 631

local adapters = require('codecompanion.adapters')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')

-- FIXME:
-- Help/options map is broken: https://github.com/olimorris/codecompanion.nvim/issues/1335
-- Add gemini model parameters: https://github.com/olimorris/codecompanion.nvim/discussions/1337

-- TODO:
-- Inline mode with custom prompts (as in python_role)

-- Create additional slash commands:
-- https://github.com/olimorris/codecompanion.nvim/discussions/958
-- For git files, a specific and pyproject.toml root dir
-- https://github.com/olimorris/codecompanion.nvim/pull/960/files
-- Feature to pass a path to file slash commands: https://github.com/olimorris/codecompanion.nvim/discussions/947
-- https://github.com/olimorris/codecompanion.nvim/discussions/641

-- Check how to use agents/tools (i.e @ commands, tipo @editor para que hagan acciones)
-- Add tool to fix quickfix errors

-- Possible to share a PDF file?
-- https://github.com/olimorris/codecompanion.nvim/discussions/1208

-- Plugins/Extensions:
-- Try VectorCode
-- https://github.com/olimorris/codecompanion.nvim/discussions/1252
-- Try MCP Hub plugin integration https://github.com/ravitemer/mcphub.nvim

-- Not saving sessions:
-- https://github.com/olimorris/codecompanion.nvim/discussions/139
-- https://github.com/olimorris/codecompanion.nvim/discussions/1098
-- https://github.com/olimorris/codecompanion.nvim/discussions/1129
-- https://github.com/olimorris/codecompanion.nvim/discussions/652

-- Nice to Haves:
-- Add ability to rename chat?
-- Choose only some default prompts/actions
-- When using editor tool enter normal mode after exiting the chat buffer and into a diff

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local GEMINI_API_KEY = 'cmd:pass show google/muttmail/gemini/api-key'
local SYSTEM_ROLE = '󰮥 Helpful Assistant'
local SYSTEM_ROLE_PROMPT = [[
You are a helpful and friendly AI assistant.
Answer questions accurately and provide detailed explanations when necessary.]]

-- Helpers
local function get_current_system_role_prompt()
    local chat = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    local system_role = nil
    for _, entry in ipairs(chat.messages) do
        if entry.role == 'system' then
            system_role = entry.content
        end
    end
    return system_role
end

local function get_last_user_prompt()
    local chat_msgs = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf()).messages
    local last_user_prompt = nil
    for i = #chat_msgs, 1, -1 do
        if chat_msgs[i].role == 'user' then
            last_user_prompt = chat_msgs[i].content
            break
        end
    end
    return last_user_prompt
end

local function set_chat_win_title()
    local chatmap = {}
    local chats = codecompanion.buf_get_chat()
    for _, chat in pairs(chats) do
        chatmap[chat.chat.ui.winnr] = chat.name
    end

    local chat = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
    vim.api.nvim_win_set_config(chat.ui.winnr, {
        title = string.format('CodeCompanion - %s', chatmap[chat.ui.winnr]),
    })
end

-- Setup
codecompanion.setup({
    adapters = {
        opts = {
            show_defaults = false,
        },
        openai_gpt = function()
            return adapters.extend('openai', {
                env = { api_key = OPENAI_API_KEY },
                schema = {
                    model = { default = 'gpt-4.1' },
                    max_tokens = { default = 2048 },
                    temperature = { default = 0.2 },
                    top_p = { default = 0.1 },
                },
            })
        end,
        openai_o_mini = function()
            return adapters.extend('openai', {
                env = { api_key = OPENAI_API_KEY },
                schema = {
                    model = { default = 'o4-mini' },
                },
            })
        end,
        gemini_flash = function()
            return adapters.extend('gemini', {
                env = { api_key = GEMINI_API_KEY },
                schema = {
                    model = { default = 'gemini-2.5-flash-preview-04-17' },
                    -- maxOutputTokens = { default = 2048 },
                    -- thinkingBudget = { default = 0 },
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
                show_default_actions = true,
                show_default_prompt_library = false,
            },
        },
        diff = { layout = 'vertical' },
    },
    strategies = {
        chat = {
            adapter = 'openai_gpt', -- default adapter
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
                send_to_other_model = {
                    modes = { n = '<C-s>', i = '<C-s>' },
                    callback = function(chat)
                        vim.g.codecompanion_adapter = 'gemini_flash'
                        chat:apply_model('gemini-2.5-flash-preview-04-17')
                        chat:submit()
                    end,
                },
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
                previous_header = { modes = { n = '<C-[>', i = '<C-[>' } },
                next_header = { modes = { n = '<C-]>', i = '<C-]>' } },
                change_adapter = { modes = { n = '<Leader>cm' } },
                debug = { modes = { n = '<Leader>db' } },
                pin = { modes = { n = '<Leader>rp' } },
                watch = { modes = { n = '<Leader>rw' } },
                system_prompt = { modes = { n = '<Leader>ts' } },
                next_chat = { modes = { n = '<A-n>', i = '<A-n>' } },
            },
            slash_commands = {
                ['buffer'] = { opts = { provider = 'telescope' } },
                ['file'] = { opts = { provider = 'telescope' } },
            },
        },
        inline = {
            adapter = 'openai_gpt',
            keymaps = {
                accept_change = { modes = { n = 'dp' } },
                reject_change = { modes = { n = 'de' } },
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
                short_name = 'assistant_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = SYSTEM_ROLE_PROMPT,
                },
                { role = 'user', content = '' },
            },
        },
        [' Bash Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Bash developer.',
            opts = {
                short_name = 'bash_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert Bash developer.
When giving code examples show the generated output.]],
                },
                { role = 'user', content = '' },
            },
        },
        [' LaTeX Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert LaTeX developer.',
            opts = {
                short_name = 'latex_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert LaTeX developer.
When giving code examples show the generated output.]],
                },
                { role = 'user', content = '' },
            },
        },
        [' Lua Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Lua developer.',
            opts = {
                short_name = 'lua_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert Lua developer.
Use a lua version that is compatible with the neovim editor (i.e 5.1).
When giving code examples show the generated output.]],
                },
                { role = 'user', content = '' },
            },
        },
        [' Python Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert Python developer.',
            opts = {
                short_name = 'python_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert Python developer with a machine learning engineer background.

Please ensure that all code examples adhere to the following guidelines:
1. Python Version: Use Python 3.12 or greater syntax.
2. Type Hinting: Include type hints whenever possible. Use the built-in `list` type for type hinting instead of importing `List` from the `typing` module and any other modern type hinting tricks and syntax.
3. Docstrings: Use NumPy-style docstrings. Don't specify the type in the `Parameters` section since it's already present in the type hint (i.e if a function receive an argument `n: int` don't write `n: int` in the `Parameters` section but simply `n:`).
4. Code Formatting: Format all code using the Black style formatter, double quotes are used for interpolation or natural language messages and single quotes for small symbol-like strings. Format docstrings to avoid D212 and D205 linter warnings.
5. Testing: Provide pytest test cases for every piece of generated code (but don't specify how to run these tests).
6. Output: Show the generated output for code examples ideally as markdown comments next to the print statements.
7. When prompted for Python code changes only show the new or modified lines, rather than repeating the entire code.]],
                },
                { role = 'user', content = '' },
            },
        },
        [' SQL Developer'] = {
            strategy = 'chat',
            description = 'Act as an expert SQL developer.',
            opts = {
                short_name = 'Sql_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
You are an expert SQL developer.
When giving code examples show the generated output.
Favour PostgreSQL syntax.]],
                },
                { role = 'user', content = '' },
            },
        },
        [' Writer'] = {
            strategy = 'chat',
            description = 'Write the way I write at work.',
            opts = {
                short_name = 'writer',
                is_slash_cmd = false,
                ignore_system_prompt = true,
            },
            references = {
                {
                    type = 'file',
                    path = {
                        '/home/pedro/git-repos/private/notes/mutt/ops/memos/1_tdms.md',
                        '/home/pedro/git-repos/private/notes/mutt/ops/memos/2_new_structure.md',
                    },
                },
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
I want you to answer questions in the same way I would write.
My style is exemplified in the shared markdown files.
When you respond, use similar vocabulary, sentence structure, and tone to closely match my writing style.
]],
                },
                { role = 'user', content = '' },
            },
        },
        ['󰗊 Translator'] = {
            strategy = 'chat',
            description = 'Act as a translator from Spanish to English.',
            opts = {
                short_name = 'translate',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
Translate the following Spanish sentence into English.
For each key word or phrase, provide at least one synonym in English.
Then, give an example sentence in English using the translation.
]],
                },
                { role = 'user', content = '' },
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

-- Set chat window title
vim.api.nvim_create_autocmd('User', {
    pattern = { 'CodeCompanionChatCreated', 'CodeCompanionChatOpened' },
    callback = function()
        vim.defer_fn(function()
            set_chat_win_title()
        end, 1)
    end,
})

-- Show a spinner working indicator when a request is being made
local spinner_states = { '', '', '' }
local current_state = 1
local timer = vim.loop.new_timer()
local ns_id = vim.api.nvim_create_namespace('codecompanion_working_spinner')
local spinner_line = nil

local function update_spinner()
    if spinner_line then
        vim.api.nvim_buf_clear_namespace(0, ns_id, spinner_line, spinner_line + 1)
        vim.api.nvim_buf_set_virtual_text(
            0,
            ns_id,
            spinner_line,
            { { ' Working ' .. spinner_states[current_state], 'Comment' } },
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

-- Ensure diffs start in normal mode and follow correct window order
vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionDiffAttached',
    callback = function()
        vim.defer_fn(function()
            vim.cmd('stopinsert')
            vim.cmd('wincmd x | wincmd p')
        end, 1)
    end,
})

-- Autocmd mappings
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('codecompanion-ft', { clear = true }),
    pattern = { 'codecompanion' },
    callback = function(e)
        -- Mappings
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf })
        vim.keymap.set({ 'i', 'n' }, '<A-p>', function()
            local chat = codecompanion.buf_get_chat(vim.api.nvim_get_current_buf())
            vim.print(string.format('Model Params:\n%s', vim.inspect(chat.settings)))
        end, { buffer = e.buf })
        vim.keymap.set({ 'i', 'n' }, '<A-r>', function()
            local system_role = get_current_system_role_prompt()
            if system_role then
                vim.print(string.format('System Role:\n%s', system_role))
            end
        end, { buffer = e.buf })
        vim.keymap.set({ 'i' }, '<C-p>', function()
            vim.cmd.stopinsert()
            local last_prompt = vim.split(get_last_user_prompt(), '\n', { plain = true })
            vim.api.nvim_put(last_prompt, 'c', true, true)
            vim.cmd.startinsert()
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
vim.keymap.set({ 'n' }, '<Leader>xe', function()
    codecompanion.actions()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    vim.defer_fn(function()
        local picker = action_state.get_current_picker(vim.api.nvim_get_current_buf())
        picker:move_selection(-1)
        actions.select_default(picker)
    end, 150)
end)
vim.keymap.set({ 'n', 'v' }, '<Leader>xr', ':CodeCompanion ', { silent = false })
vim.keymap.set({ 'v' }, '<Leader>xp', codecompanion.add)
