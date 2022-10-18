local overseer = require('overseer')
local u = require('utils')

overseer.setup({
    templates = { 'builtin', 'user.run_script', 'user.run_arara' },
})

-- Mappings
u.keymap('n', '<F7>', function()
    vim.cmd('silent noautocmd update')
    overseer.run_template({ name = 'Run Script' }, function()
        vim.cmd('cclose')
    end)
end)
u.keymap('n', '<Leader>lt', '<Cmd>OverseerQuickAction open hsplit<CR>')
