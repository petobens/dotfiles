local overseer = require('overseer')

_G.OverseerConfig = {} -- to store error formats

-- Setup
overseer.setup({
    task_list = {
        min_height = 15,
        max_height = 15,
        min_width = 0.5,
        max_width = 0.5,
        separator = '',
        keymaps = {
            ['<C-k>'] = false,
            ['<C-j>'] = false,
            ['p'] = false,
            ['[t'] = 'keymap.prev_task',
            [']t'] = 'keymap.next_task',
            ['<A-v>'] = 'keymap.toggle_preview',
            ['<A-k>'] = 'keymap.scroll_output_up',
            ['<A-j>'] = 'keymap.scroll_output_down',
            ['dd'] = { 'keymap.run_action', opts = { action = 'dispose' } },
            ['ss'] = { 'keymap.run_action', opts = { action = 'stop' } },
        },
    },
})

-- Helpers
local function overseer_last_task(attach)
    local tasks = overseer.list_tasks({
        include_ephemeral = true,
        sort = function(a, b)
            return (a.time_start or 0) > (b.time_start or 0)
        end,
    })
    local task = tasks[1]
    if not task then
        vim.notify('No Overseer tasks found', vim.log.levels.WARN)
        return
    end
    overseer.run_action(task, 'open hsplit')

    vim.cmd.stopinsert()
    vim.cmd.wincmd('J')
    vim.cmd.resize('15')
    vim.opt_local.winfixheight = true
    vim.keymap.set('n', 'q', function()
        vim.cmd.close()
        vim.cmd.wincmd('p')
    end, { buffer = true, desc = 'Close Overseer output window and return' })

    if attach then
        vim.cmd.startinsert()
        return
    end

    vim.opt_local.winfixbuf = true
    vim.opt_local.modifiable = true
    vim.cmd.normal({ args = { 'kdGggG' }, bang = true, mods = { silent = true } })
    vim.opt_local.modifiable = false
end

-- Autocmd settings
vim.api.nvim_create_autocmd('FileType', {
    desc = 'Configure OverseerList window',
    pattern = 'OverseerList',
    group = vim.api.nvim_create_augroup('OverseerConfig', { clear = true }),
    callback = function(e)
        -- Options
        vim.opt_local.winfixbuf = true
        vim.defer_fn(function()
            vim.cmd.stopinsert()
        end, 1)
        -- Mappings
        vim.keymap.set('n', 'q', function()
            pcall(vim.api.nvim_win_close, 0, true)
            vim.cmd.wincmd('p')
        end, {
            buffer = e.buf,
            desc = 'Close OverseerList window and return to previous window',
        })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>os', function()
    vim.cmd.OverseerToggle('bottom')
end, { desc = 'Toggle Overseer task list' })

vim.keymap.set(
    'n',
    '<Leader>oo',
    overseer_last_task,
    { desc = 'Open last Overseer task output' }
)

vim.keymap.set('n', '<Leader>oa', function()
    overseer_last_task(true)
end, { desc = 'Attach to last Overseer task output' })
