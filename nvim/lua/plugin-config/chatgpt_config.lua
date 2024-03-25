local NuiText = require('nui.text')
local chatgpt = require('chatgpt')
local colors = require('onedarkpro.helpers').get_colors()

_G.ChatGPTConfig = {}

chatgpt.setup({
    api_key_cmd = 'pass show openai/yahoomail/apikey',
    openai_params = {
        model = 'gpt-4-turbo-preview',
        max_tokens = 4096,
        temperature = 0.2,
        top_p = 0.1,
        n = 1,
    },
    popup_layout = {
        default = 'right',
        right = { width = '45%' },
    },
    chat = {
        welcome_message = '',
        loading_text = 'Loading...',
        question_sign = ' ',
        keymaps = {
            -- Input
            scroll_up = '<A-k>',
            scroll_down = '<A-j>',
            cycle_windows = { '<C-k>', '<C-j>' },
            cycle_modes = '<Tab>',
            toggle_settings = '<C-p>',
            toggle_help = '<A-h>',
            toggle_system_role_open = '<A-s>',
            toggle_message_role = '<C-m>',
            new_session = '<A-n>',
            -- Output
            next_message = '<C-]>',
            prev_message = '<C-[>',
            -- Sessions
            toggle_sessions = '<C-s>',
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
    popup_input = {
        prompt = NuiText('󰥭 ', 'Statement'),
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
        help_key = '@chatgpt.help_key',
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
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf })
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
        vim.keymap.set('n', 'i', '<C-k>', { buffer = e.buf, remap = true })
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
---- Settings (params)
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('chatgpt-params', { clear = true }),
    pattern = { 'chatgpt-params' },
    callback = function()
        -- FIXME: This changes the global identifier color
        vim.api.nvim_set_hl(0, 'Identifier', { fg = colors.green })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>cg', function()
    -- Remove line signs
    for _, v in pairs({ 'start', 'middle', 'end' }) do
        pcall(vim.fn.sign_undefine, 'chatgpt_chat_' .. v .. '_block')
    end

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
