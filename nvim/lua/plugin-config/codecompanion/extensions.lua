local u = require('utils')

local M = {}

local extensions = {
    -- History
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
            -- <A-s> is remapped in mappings.lua to dispatch by adapter type
            -- (acp -> ACP session picker, http -> this history browser)
            keymap = { n = '<nop>', i = '<nop>' },
            picker_keymaps = {
                rename = { n = 'r', i = '<A-r>' },
                delete = { n = 'd', i = '<A-d>' },
            },
            save_chat_keymap = { n = '<nop>', i = '<nop>' },
        },
    },
}

function M.build()
    return extensions
end

return M
