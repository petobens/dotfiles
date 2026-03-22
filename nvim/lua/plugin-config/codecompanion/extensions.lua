local u = require('utils')

local M = {}

function M.build()
    return {
        history = {
            enabled = true,
            opts = {
                auto_generate_title = u.is_online(),
                title_generation_opts = {
                    adapter = 'openai_gpt_54_nano_legacy',
                    model = 'gpt-5.4-nano',
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
    }
end

return M
