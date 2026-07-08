local M = {}

local extensions = {
    -- History
    history = {
        enabled = true,
        opts = {
            auto_generate_title = false,
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
