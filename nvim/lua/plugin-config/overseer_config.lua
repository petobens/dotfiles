local overseer = require('overseer')
local u = require('utils')

overseer.setup({
    templates = { 'builtin', 'user.run_script' },
})

-- Mappings
u.keymap('n', '<F7>', function()
    overseer.run_template({ name = 'Run Script' }, function(task)
        if task then
            local main_win = vim.api.nvim_get_current_win()
            overseer.run_action(task, 'open hsplit')
            vim.api.nvim_set_current_win(main_win)
        else
            print('Task not found')
        end
    end)
end)
