-- luacheck:ignore 631

local adapters = require('codecompanion.adapters')
local codecompanion = require('codecompanion')

-- TODO:
-- Fetch enter url has no spaces: https://github.com/olimorris/codecompanion.nvim/pull/953
-- Feature to pass a path to file slash commands: https://github.com/olimorris/codecompanion.nvim/discussions/947
-- Render markdown icons for <file>, <buffer> and <url> fetch command: https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/336
-- Possible to share a PDF file?

-- Custom prompts (a.k.a roles) and system role
-- https://github.com/olimorris/dotfiles/blob/main/.config/nvim/lua/plugins/coding.lua#L81
-- https://codecompanion.olimorris.dev/extending/prompts.html
-- Ignoring system prompt not working: https://github.com/olimorris/codecompanion.nvim/issues/959
-- Show prompt name in system chat header message: https://github.com/olimorris/codecompanion.nvim/discussions/780#discussioncomment-12255241
-- Use another system prompt by default? https://codecompanion.olimorris.dev/configuration/system-prompt
-- Show a preview of the prompt in telescope
-- Feature parity con prompts en chatgpt plugin
-- Agregar prompt que le paso el file de como escribo yo con los memos de Ops

-- Create slash commands: https://github.com/olimorris/codecompanion.nvim/discussions/958
-- Tipo para ver gitfiles o lo que hay en un directorio
-- https://github.com/olimorris/codecompanion.nvim/pull/960/files
-- Use/mappings for inline diffs
-- Not saving sessions: https://github.com/olimorris/codecompanion.nvim/discussions/139
-- Check how to use agents/tools (i.e @ commands)

local OPENAI_API_KEY = 'cmd:pass show openai/yahoomail/apikey'

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
        },
    },
    strategies = {
        chat = {
            adapter = 'openai_gpt_4o', -- default adapter
            roles = {
                llm = function(adapter)
                    return string.format(
                        '%s (%s)',
                        adapter.formatted_name,
                        adapter.schema.model.default
                    )
                end,
                user = 'Me',
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
    prompt_library = {
        ['Bash Developer'] = {
            strategy = 'chat',
            opts = {
                index = 1,
                is_slash_cmd = true,
                is_default = true,
                short_name = 'bash',
                auto_submit = false,
                ignore_system_prompt = true,
            },
            prompts = {
                {
                    role = 'system',
                    content = [[
I want you to act as an expert Bash developer. When giving code examples show the generated output.
                    ]],
                    opts = { visible = true },
                },
                {
                    role = 'user',
                    -- FIXME: Add new line
                    content = string.format('i\n%s', ''),
                },
            },
        },
    },
})

-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register('markdown', 'codecompanion')

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
vim.keymap.set('n', '<Leader>xa', '<Cmd>CodeCompanionActions<CR>')
