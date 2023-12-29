local gitsigns = require('gitsigns')

gitsigns.setup({
    signcolumn = false, -- disable by default
    watch_gitdir = {
        interval = 600,
    },
    current_line_blame_opts = {
        delay = 0,
    },
})

-- Mappings
vim.keymap.set('n', '<Leader>gg', gitsigns.toggle_signs)
vim.keymap.set('n', ']h', function()
    if vim.wo.diff then
        return ']c'
    end
    vim.schedule(function()
        gitsigns.next_hunk({ navigation_message = false, foldopen = true })
    end)
    return '<Ignore>'
end, { expr = true })

vim.keymap.set('n', '[h', function()
    if vim.wo.diff then
        return '[c'
    end
    vim.schedule(function()
        gitsigns.prev_hunk({ navigation_message = false, foldopen = true })
    end)
    return '<Ignore>'
end, { expr = true })
vim.keymap.set('n', '<Leader>hp', gitsigns.preview_hunk)
vim.keymap.set('n', '<Leader>gm', function()
    gitsigns.blame_line({ full = true })
end)
vim.keymap.set('n', '<Leader>ib', gitsigns.toggle_current_line_blame)
