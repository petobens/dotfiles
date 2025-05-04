-- luacheck:ignore 631

local adapters = require('codecompanion.adapters')
local codecompanion = require('codecompanion')
local config = require('codecompanion.config')
local keymaps = require('codecompanion.strategies.chat.keymaps')

-- FIXME:
-- Add gemini model parameters: https://github.com/olimorris/codecompanion.nvim/discussions/1337
-- Custom prompt (writer) slash cmd not loading references: https://github.com/olimorris/codecompanion.nvim/issues/1355
-- Retrieve model name in pre-process: https://github.com/olimorris/codecompanion.nvim/pull/1331#issuecomment-2849238617
-- and also add postprocess (to remove think or --- yaml)

-- TODO:
-- Disable diagnostics in debug window
-- Show only default model when selecting an adapter

-- Check how to use agents/tools (i.e @ commands, tipo @editor para que hagan acciones)
-- Add tool to fix quickfix errors

-- Plugins/Extensions:
-- Not saving sessions: https://github.com/ravitemer/codecompanion-history.nvim
-- MCP Hub https://github.com/ravitemer/mcphub.nvim
-- Possible to share a PDF file with this?
-- https://github.com/olimorris/codecompanion.nvim/discussions/1208
-- VectorCode https://github.com/olimorris/codecompanion.nvim/discussions/1252

-- Nice to Haves:
-- Add ability to rename chat?
-- Choose only some default prompts/actions
-- When using editor tool enter normal mode after exiting the chat buffer and into a diff

_G.CodeCompanionConfig = {}

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'
local GEMINI_API_KEY = 'cmd:pass show google/muttmail/gemini/api-key'
local SYSTEM_ROLE = '󰮥 Helpful Assistant'
local SYSTEM_ROLE_PROMPT = [[
You are a helpful and friendly AI assistant.
Answer questions accurately and provide detailed explanations when necessary.]]

-- Helpers
local function get_my_prompt_library()
    local prompt_md_files = {
        'bash_developer',
        'latex_developer',
        'lua_developer',
        'pydocs',
        'python_developer',
        'sql_developer',
        'translator_spa_eng',
        'writer_at_work',
    }
    local base_url =
        'https://raw.githubusercontent.com/petobens/llm-prompts/main/md-prompts/%s.md'
    local prompt_dir = vim.fn.expand('~/git-repos/private/llm-prompts/md-prompts/')
    local use_url = vim.fn.isdirectory(prompt_dir) ~= 1
    local prompt_library = {}

    for _, name in ipairs(prompt_md_files) do
        local lines
        if use_url then
            lines = vim.fn.systemlist({ 'curl', '-fsSL', string.format(base_url, name) })
        else
            lines = vim.fn.readfile(prompt_dir .. name .. '.md')
        end

        local filtered = {}
        for _, line in ipairs(lines) do
            if not line:lower():find('markdownlint') then
                table.insert(filtered, line)
            end
        end
        prompt_library[name] = table.concat(filtered, '\n'):gsub('\n$', '')
    end
    return prompt_library
end

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
        footer = vim.uv.cwd():match('([^/]+/[^/]+/[^/]+)$'),
        footer_pos = 'center',
    })
end

local function try_focus_chat_float()
    -- Focus window if already open (we search for a floating window with specifix zindex)
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        local conf = vim.api.nvim_win_get_config(win_id)
        if conf.focusable and conf.relative ~= '' and conf.zindex == 45 then
            vim.api.nvim_set_current_win(win_id)
            return true
        end
    end
    return false
end

local function focus_or_toggle_chat()
    if try_focus_chat_float() then
        return
    end
    codecompanion.toggle()
    vim.defer_fn(function()
        vim.cmd('startinsert')
    end, 1)
end

local function send_project_tree(chat, root)
    local tree = vim.fn.system({ 'tree', '-a', '-L', '2', '--noreport', root })
    chat:add_message({
        role = 'user',
        content = string.format('The project structure is given by:\n%s', tree),
    })
end

-- Globals
function _G.CodeCompanionConfig.add_references(files)
    local chat = codecompanion.last_chat()
    if not chat then
        chat = codecompanion.chat()
    end
    for _, file in ipairs(files) do
        local content = table.concat(vim.fn.readfile(file), '\n')
        chat:add_reference({
            role = 'user',
            content = string.format('Here is the content of %s:%s', file, content),
        }, 'file', string.format(
            '<file>%s</file>',
            vim.fn.fnamemodify(file, ':t')
        ))
    end
    focus_or_toggle_chat()
end

-- Setup
local PROMPT_LIBRARY = get_my_prompt_library()
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
                    -- FIXME: These arguments are not working
                    -- maxOutputTokens = { default = 2048 },
                    -- thinkingBudget = { default = 0 },
                },
            })
        end,
        ollama_qwen3_2b = function()
            return adapters.extend('ollama', {
                schema = {
                    model = {
                        default = 'qwen3:1.7b',
                    },
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
            opts = {
                prompt_decorator = function(message, adapter, _)
                    if adapter.name == 'ollama' then
                        return string.format([[/no_think %s]], message)
                    else
                        return message
                    end
                end,
            },
            keymaps = {
                send = { modes = { n = '<C-o>', i = '<C-o>' } },
                send_to_other_model = {
                    modes = { n = '<C-s>', i = '<C-s>' },
                    description = 'Send input alternate model',
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
                clear = { modes = { n = '<A-w>', i = '<A-w>' } },
                yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
                options = {
                    modes = { n = '<A-h>', i = '<A-h>' },
                    callback = function()
                        keymaps.options.callback()
                        vim.defer_fn(function()
                            vim.cmd('stopinsert')
                        end, 1)
                    end,
                },
                previous_header = { modes = { n = '<C-[>', i = '<C-[>' } },
                next_header = { modes = { n = '<C-]>', i = '<C-]>' } },
                change_adapter = { modes = { n = '<Leader>cm', i = '<A-m>' } },
                debug = {
                    modes = { n = '<Leader>db', i = '<A-d>' },
                    callback = function(chat)
                        keymaps.debug.callback(chat)
                        vim.defer_fn(function()
                            vim.cmd('stopinsert')
                        end, 1)
                    end,
                },
                pin = { modes = { n = '<Leader>rp' } },
                watch = { modes = { n = '<Leader>rw' } },
                system_prompt = { modes = { n = '<Leader>ts' } },
                next_chat = { modes = { n = '<A-n>', i = '<A-n>' } },
            },
            slash_commands = {
                ['buffer'] = { opts = { provider = 'telescope' } },
                ['file'] = { opts = { provider = 'telescope' } },
                ['directory'] = {
                    callback = function(chat)
                        vim.ui.input(
                            { prompt = 'Context dir: ', completion = 'dir' },
                            function(dir)
                                dir = vim.fn
                                    .trim(vim.fn.fnamemodify(dir, ':ph'))
                                    :gsub('/$', '')
                                local glob_result = vim.fn.glob(dir .. '/*', false, true)
                                local files = {}
                                for _, file in ipairs(glob_result) do
                                    if vim.fn.isdirectory(file) == 0 then
                                        table.insert(files, file)
                                    end
                                end
                                send_project_tree(chat, dir)
                                _G.CodeCompanionConfig.add_references(files)
                            end
                        )
                    end,
                },
                ['git_files'] = {
                    callback = function(chat)
                        local git_root = vim.trim(
                            vim.fn.systemlist('git rev-parse --show-toplevel')[1]
                        )
                        local git_files =
                            vim.fn.systemlist('git ls-files --full-name ' .. git_root)
                        local files = vim.tbl_map(function(f)
                            return git_root .. '/' .. f
                        end, git_files)
                        send_project_tree(chat, git_root)
                        _G.CodeCompanionConfig.add_references(files)
                    end,
                },
                ['py_files'] = {
                    callback = function(chat)
                        send_project_tree(chat, _G.PyVenv.active_venv.project_root)
                        _G.CodeCompanionConfig.add_references(
                            _G.PyVenv.active_venv.project_files
                        )
                    end,
                },
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
                { role = 'system', content = PROMPT_LIBRARY['bash_developer'] },
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
                { role = 'system', content = PROMPT_LIBRARY['latex_developer'] },
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
                { role = 'system', content = PROMPT_LIBRARY['lua_developer'] },
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
                { role = 'system', content = PROMPT_LIBRARY['python_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' PyDocs'] = {
            strategy = 'inline',
            description = 'Write inline Python docstrings following NumPy-style.',
            opts = {
                short_name = 'pydocs',
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['pydocs'] },
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
                { role = 'system', content = PROMPT_LIBRARY['sql_developer'] },
                { role = 'user', content = '' },
            },
        },
        [' Writer at Work'] = {
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
                { role = 'system', content = PROMPT_LIBRARY['writer_at_work'] },
                { role = 'user', content = '' },
            },
        },
        ['󰗊 Translator'] = {
            strategy = 'chat',
            description = 'Act as a translator from Spanish to English.',
            opts = {
                short_name = 'translator_role',
                is_slash_cmd = true,
                ignore_system_prompt = true,
            },
            prompts = {
                { role = 'system', content = PROMPT_LIBRARY['translator_spa_eng'] },
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
vim.keymap.set('n', '<Leader>xx', focus_or_toggle_chat)
vim.keymap.set({ 'n', 'v' }, '<Leader>xr', ':CodeCompanion ', { silent = false })
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
vim.keymap.set({ 'v' }, '<Leader>xp', function()
    codecompanion.add()
    if vim.bo.filetype ~= 'codecompanion' then
        try_focus_chat_float()
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
            'n',
            false
        )
    end
end)
