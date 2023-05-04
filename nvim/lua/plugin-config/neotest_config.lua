local neotest = require('neotest')

neotest.setup({
    adapters = {
        require('neotest-python'),
    },
    diagnostic = {
        enabled = true,
    },
    status = {
        enabled = true,
        virtual_text = true,
        signs = false,
    },
    quickfix = {
        enabled = true,
        open = function()
            vim.cmd('copen')
            vim.cmd('wincmd p')
            vim.cmd('stopinsert')
        end,
    },
})

-- Mappings
local u = require('utils')
u.keymap('n', '<Leader>nto', function()
    neotest.output.open({ short = true })
end)
u.keymap('n', '<Leader>ntn', function()
    vim.cmd('cclose')
    neotest.run.run()
end)
u.keymap('n', '<Leader>ntf', function()
    vim.cmd('cclose')
    neotest.run.run(vim.fn.expand('%'))
end)
