local gitsigns = require('gitsigns')

-- Setup
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
vim.keymap.set('n', '<Leader>gg', gitsigns.toggle_signs, { desc = 'Toggle gitsigns' })

vim.keymap.set('n', ']h', function()
    if vim.wo.diff then
        return ']c'
    end
    vim.schedule(function()
        gitsigns.nav_hunk('next', { navigation_message = false, foldopen = true })
    end)
    return '<Ignore>'
end, { expr = true, desc = 'Next git hunk' })

vim.keymap.set('n', '[h', function()
    if vim.wo.diff then
        return '[c'
    end
    vim.schedule(function()
        gitsigns.nav_hunk('prev', { navigation_message = false, foldopen = true })
    end)
    return '<Ignore>'
end, { expr = true, desc = 'Previous git hunk' })

vim.keymap.set('n', '<Leader>hp', gitsigns.preview_hunk, { desc = 'Preview git hunk' })

vim.keymap.set('n', '<Leader>gm', function()
    gitsigns.blame_line({ full = true })
end, { desc = 'Show git blame message for current line' })

vim.keymap.set(
    'n',
    '<Leader>ib',
    gitsigns.toggle_current_line_blame,
    { desc = 'Toggle inline git blame' }
)
