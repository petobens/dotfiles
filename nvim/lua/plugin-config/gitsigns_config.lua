local gitsigns = require('gitsigns')
local u = require('utils')

gitsigns.setup({
    signcolumn = false, -- disable by default
    watch_gitdir = {
        interval = 600,
    },
})

-- Mappings
u.keymap('n', '<Leader>gg', '<Cmd>Gitsigns toggle_signs<CR>')
u.keymap('n', ']h', function()
    if vim.wo.diff then
        return ']c'
    end
    vim.schedule(function()
        gitsigns.next_hunk({ navigation_message = false, foldopen = true })
    end)
    return '<Ignore>'
end, { expr = true })

u.keymap('n', '[h', function()
    if vim.wo.diff then
        return '[c'
    end
    vim.schedule(function()
        gitsigns.prev_hunk({ navigation_message = false, foldopen = true })
    end)
    return '<Ignore>'
end, { expr = true })
u.keymap('n', '<Leader>hp', gitsigns.preview_hunk)
