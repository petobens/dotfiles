local overseer = require('overseer')
local u = require('utils')

overseer.setup({
    templates = {
        'builtin',
        'user.run_arara',
        'user.run_lua',
        'user.run_python',
        'user.run_script',
    },
})

-- Mappings
u.keymap('n', '<F7>', function()
    vim.cmd('silent noautocmd update')
    overseer.run_template({ name = 'run_script' }, function()
        vim.cmd('cclose')
    end)
end)
u.keymap('n', '<Leader>lt', '<Cmd>OverseerQuickAction open hsplit<CR>')
