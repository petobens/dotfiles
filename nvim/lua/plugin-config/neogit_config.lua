local neogit = require('neogit')

neogit.setup({
    kind = 'split',
    sections = {
        recent = {
            hidden = true,
        },
    },
    status = {
        recent_commit_count = 5,
    },
})

-- Mappings
vim.keymap.set('n', '<Leader>ng', function()
    neogit.open()
    vim.cmd('wincmd J | resize 15 | set winfixheight')
end)
