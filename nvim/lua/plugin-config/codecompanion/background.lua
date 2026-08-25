local M = {}

function M.build(adapter)
    return {
        adapter = adapter,
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
end

return M
