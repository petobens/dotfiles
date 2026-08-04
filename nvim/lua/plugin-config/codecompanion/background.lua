local M = {}

local background = {
    adapter = 'openai_gpt_56_luna',
    chat = {
        callbacks = {
            ['on_ready'] = {
                actions = {
                    'plugin-config.codecompanion.background.title_refresh',
                },
                enabled = true,
            },
        },
        opts = {
            enabled = true,
        },
    },
}

function M.build()
    return background
end

return M
