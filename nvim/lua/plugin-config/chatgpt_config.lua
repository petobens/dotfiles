require('chatgpt').setup({
    api_key_cmd = 'pass show openai/yahoomail/apikey',
    chat = {
        welcome_message = '',
        loading_text = 'Loading...',
        question_sign = ' ',
        keymaps = {
            -- Input
            scroll_up = '<A-k>',
            scroll_down = '<A-j>',
            cycle_windows = { '<C-n>', '<C-p>' },
            toggle_settings = '<C-i>',
            toggle_help = '<C-l>',
            toggle_system_role_open = '<nop>',
            -- Output
            next_message = '<C-]>',
            prev_message = '<C-[>',
            -- Sessions
            toggle_sessions = '<C-s>',
            new_session = '<A-n>',
            select_session = '<CR>',
            rename_session = 'r',
            delete_session = 'd',
        },
        sessions_window = {
            active_sign = '* ',
            inactive_sign = '',
            current_line_sign = '',
        },
    },
    popup_layout = {
        default = 'right',
        right = { width = '45%' },
    },
    popup_window = {
        buf_options = {
            filetype = 'chatgpt',
        },
    },
    popup_input = {
        prompt = ' ',
        submit = '<C-o>',
    },
})

-- Ensure popup_window (out) is treated as markdown despite being a chatgpt file
vim.treesitter.language.register('markdown', 'chatgpt')

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('chatgpt', { clear = true }),
    pattern = { 'chatgpt-input' },
    callback = function(e)
        vim.keymap.set('i', '<C-h>', '<ESC><C-w>h', { buffer = e.buf, noremap = true })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>cg', '<Cmd>ChatGPT<CR>')
