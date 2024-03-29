-- luacheck:ignore 631
local chatgpt = require('chatgpt')

_G.ChatGPTConfig = {}

chatgpt.setup({
    api_key_cmd = 'pass show openai/yahoomail/apikey',
    openai_params = {
        model = 'gpt-4-turbo-preview',
        max_tokens = 2048,
        temperature = 0.2,
        top_p = 0.1,
        n = 1,
    },
    predefined_chat_gpt_prompts = 'https://raw.githubusercontent.com/petobens/chatgpt-prompts/main/prompts.csv',
    popup_layout = {
        default = 'right',
        right = { width = '45%' },
    },
    chat = {
        welcome_message = '',
        loading_text = 'Loading...',
        question_sign = ' ',
        answer_sign = '> ',
        keymaps = {
            -- Input
            scroll_up = '<A-k>',
            scroll_down = '<A-j>',
            cycle_windows = { '<C-j>' },
            cycle_modes = '<Tab>',
            yank_last_code = '<C-y>',
            yank_last = '<A-y>',
            toggle_settings = '<A-p>',
            toggle_help = '<A-h>',
            toggle_system_role_open = '<A-r>',
            toggle_message_role = '<A-m>',
            new_session = '<A-n>',
            -- Output
            next_message = '<C-]>',
            prev_message = '<C-[>',
            -- Sessions
            toggle_sessions = '<A-s>',
            select_session = '<CR>',
            rename_session = 'r',
            delete_session = 'd',
        },
        sessions_window = {
            active_sign = ' ',
            inactive_sign = ' ',
            current_line_sign = ' ',
            border = {
                text = {
                    top = { { ' Sessions ', 'TelescopeTitle' } },
                },
            },
            buf_options = {
                filetype = 'chatgpt-sessions',
            },
            win_options = {
                winfixbuf = true,
            },
        },
    },
    edit_with_instructions = {
        keymaps = {
            toggle_diff = '<C-d>',
            toggle_settings = '<A-p>',
            toggle_help = '<A-h>',
            cycle_windows = { '<C-j>' },
            accept = '<C-r>', -- "replace"
            yank = '<C-y>',
            use_output_as_input = '<C-i>',
        },
    },
    popup_input = {
        prompt = '󰥭 ',
        submit = '<C-o>',
        border = {
            text = {
                top_align = 'center',
                top = { { ' Prompt ', 'TelescopeTitle' } },
            },
        },
        win_options = {
            winfixbuf = true,
        },
    },
    popup_window = {
        border = {
            text = {
                top = { { ' ChatGPT ', 'TelescopeTitle' } },
            },
        },
        buf_options = {
            filetype = 'chatgpt',
        },
        win_options = {
            foldenable = false,
            conceallevel = 2,
            concealcursor = 'nc',
            winfixbuf = true,
        },
    },
    settings_window = {
        border = {
            text = {
                top = { { ' Parameters ', 'TelescopeTitle' } },
            },
        },
        buf_options = {
            filetype = 'chatgpt-params',
        },
        win_options = {
            winfixbuf = true,
        },
    },
    help_window = {
        border = {
            text = {
                top = { { ' Help ', 'TelescopeTitle' } },
            },
        },
        buf_options = {
            filetype = 'chatgpt-help',
        },
        win_options = {
            winfixbuf = true,
        },
    },
    system_window = {
        border = {
            text = {
                top = { { ' System ', 'TelescopeTitle' } },
            },
        },
        buf_options = {
            filetype = 'chatgpt-system',
        },
        win_options = {
            winfixbuf = true,
        },
    },
    highlights = {
        active_session = '@chatgpt.active_session',
        code_edit_result_title = 'TelescopeTitle',
        help_key = '@chatgpt.help_key',
        input_title = 'TelescopeTitle',
        params_value = '@chatgpt.params_value',
    },
})

-- Ensure popup_window (out) is treated as markdown despite being a chatgpt file
vim.treesitter.language.register('markdown', 'chatgpt')

-- Autocmds
---- Input
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('chatgpt-in', { clear = true }),
    pattern = { 'chatgpt-input' },
    callback = function(e)
        vim.keymap.set({ 'n', 'i' }, '<C-k>', function()
            for w = 1, vim.fn.winnr('$') do
                local win_id = vim.fn.win_getid(w)
                local filetype = vim.bo[vim.api.nvim_win_get_buf(win_id)].filetype
                if filetype == 'chatgpt' then
                    vim.fn.win_gotoid(win_id)
                    vim.defer_fn(function()
                        vim.cmd('stopinsert')
                    end, 1)
                    return
                end
            end
        end, { buffer = e.buf, remap = true })
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf })
        vim.keymap.set('i', '<C-a>', '<Cmd>ChatGPTActAs<CR>')
    end,
})
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    group = vim.api.nvim_create_augroup('chatgpt-in-bufenter', { clear = true }),
    pattern = { '*' },
    callback = function()
        if vim.bo.filetype == 'chatgpt-input' then
            vim.defer_fn(function()
                vim.cmd('startinsert')
            end, 1)
        end
    end,
})
---- Output (chat)
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('chatgpt-ft', { clear = true }),
    pattern = { 'chatgpt' },
    callback = function(e)
        vim.keymap.set('n', 'i', function()
            for w = 1, vim.fn.winnr('$') do
                local win_id = vim.fn.win_getid(w)
                local filetype = vim.bo[vim.api.nvim_win_get_buf(win_id)].filetype
                if filetype == 'chatgpt-input' then
                    vim.fn.win_gotoid(win_id)
                    return
                end
            end
        end, { buffer = e.buf, remap = true })
    end,
})
vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    group = vim.api.nvim_create_augroup('chatgpt-bufleave', { clear = true }),
    pattern = { '*' },
    callback = function()
        if vim.bo.filetype == 'chatgpt' then
            vim.fn.win_gotoid(_G.ChatGPTConfig.last_winid)
            vim.defer_fn(function()
                vim.cmd('stopinsert')
            end, 2)
        end
    end,
})

-- Helpers
local function undefine_gpt_signs()
    for _, v in pairs({ 'start', 'middle', 'end' }) do
        pcall(vim.fn.sign_undefine, 'chatgpt_chat_' .. v .. '_block')
    end
end

-- Mappings
vim.keymap.set('n', '<Leader>cg', function()
    undefine_gpt_signs()

    -- Save last win_id to jump back
    _G.ChatGPTConfig.last_winid = vim.fn.win_getid()

    -- Focus window if already open
    for w = 1, vim.fn.winnr('$') do
        local win_id = vim.fn.win_getid(w)
        local win_conf = vim.api.nvim_win_get_config(win_id)
        if win_conf.focusable and win_conf.relative ~= '' then
            vim.api.nvim_set_current_win(win_id)
            return
        end
    end

    chatgpt.openChat()
    vim.defer_fn(function()
        vim.cmd('startinsert')
    end, 1)
end)
vim.keymap.set('n', '<Leader>aa', function()
    undefine_gpt_signs()
    chatgpt.selectAwesomePrompt()
end)
vim.keymap.set({ 'n', 'v' }, '<Leader>ei', ':ChatGPTEditWithInstructions<CR>')
vim.keymap.set('n', '<Leader>cp', '<Cmd>ChatGPTCompleteCode<CR>')
