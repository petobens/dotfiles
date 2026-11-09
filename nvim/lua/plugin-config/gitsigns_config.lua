local gitsigns = require('gitsigns')

-- Setup
gitsigns.setup({
    signcolumn = false, -- disable by default
    current_line_blame_opts = {
        delay = 0,
    },
})

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'gitsigns-diff',
    desc = 'Set up previews, highlight, and staging toggle in the Gitsigns diff panel',
    callback = function(args)
        -- Match the Aerial outline. Gitsigns marks the opened file with QuickFixLine,
        -- which would otherwise cover part of the cursor line.
        vim.opt_local.winhighlight = 'CursorLine:AerialLine,QuickFixLine:AerialLine'
        vim.keymap.set('n', '-', '<Space>', {
            buffer = args.buf,
            remap = true,
            desc = 'Toggle file or directory staging',
        })

        vim.api.nvim_create_autocmd('CursorMoved', {
            buffer = args.buf,
            desc = 'Open the Gitsigns panel entry under the cursor',
            callback = function()
                local line = vim.api.nvim_win_get_cursor(0)[1]
                -- Wait until the cursor rests so holding j does not open every file
                vim.defer_fn(function()
                    if
                        vim.api.nvim_get_current_buf() == args.buf
                        and vim.api.nvim_win_get_cursor(0)[1] == line
                    then
                        -- Same as <S-CR>: open the file and keep focus in the panel
                        vim.fn.maparg('<S-CR>', 'n', false, true).callback()
                    end
                end, 150)
            end,
        })
    end,
})

-- Mappings
vim.keymap.set(
    'n',
    '<Leader>gg',
    gitsigns.toggle_signs,
    { desc = '[G]it [g]utter: toggle signs (Gitsigns)' }
)

vim.keymap.set('n', '<Leader>ge', function()
    -- Focus this tab's panel; Gitsigns would otherwise stack a second diff tab
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'gitsigns-diff' then
            return vim.api.nvim_set_current_win(win)
        end
    end
    gitsigns.diff()
end, { desc = '[G]it [e]xplore changes' })

vim.keymap.set('n', ']h', function()
    if vim.wo.diff then
        return ']c'
    end
    local count = vim.v.count1
    vim.schedule(function()
        gitsigns.nav_hunk(
            'next',
            { count = count, navigation_message = false, foldopen = true }
        )
    end)
    return '<Ignore>'
end, { expr = true, desc = 'Next git hunk' })

vim.keymap.set('n', '[h', function()
    if vim.wo.diff then
        return '[c'
    end
    local count = vim.v.count1
    vim.schedule(function()
        gitsigns.nav_hunk(
            'prev',
            { count = count, navigation_message = false, foldopen = true }
        )
    end)
    return '<Ignore>'
end, { expr = true, desc = 'Previous git hunk' })

vim.keymap.set('n', '<Leader>hp', gitsigns.preview_hunk, { desc = '[H]unk [p]review' })

vim.keymap.set('n', '<Leader>gm', function()
    gitsigns.blame_line({ full = true })
end, { desc = '[G]it blame [m]essage for current line' })

vim.keymap.set(
    'n',
    '<Leader>ib',
    gitsigns.toggle_current_line_blame,
    { desc = '[I]nline git [b]lame: toggle' }
)
