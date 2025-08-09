local overseer = require('overseer')

_G.OverseerConfig = {} -- to store error formats

-- Setup
overseer.setup({
    templates = {
        'builtin',
        'user',
    },
    task_list = {
        default_detail = 2,
        min_height = 15,
        max_height = 15,
        min_width = 0.5,
        max_width = 0.5,
        separator = '',
        bindings = {
            ['zo'] = 'IncreaseDetail',
            ['zc'] = 'DecreaseDetail',
            ['zr'] = 'IncreaseDetail',
            ['zm'] = 'DecreaseDetail',
            [']'] = false,
            ['['] = false,
            ['[t'] = 'PrevTask',
            [']t'] = 'NextTask',
            ['<A-v>'] = 'TogglePreview',
            ['<A-j>'] = 'ScrollOutputDown',
            ['<A-k>'] = 'ScrollOutputUp',
            ['dd'] = 'Dispose',
            ['ss'] = 'Stop',
        },
    },
})

-- Helpers
local function overseer_last_task(attach)
    vim.cmd.OverseerQuickAction('open hsplit')
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
        end, { buffer = e.buf, desc = 'Close OverseerList window and return' })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>os', function()
    vim.cmd.OverseerToggle('bottom')
end, { desc = 'Toggle Overseer task list (bottom)' })

vim.keymap.set(
    'n',
    '<Leader>oo',
    overseer_last_task,
    { desc = 'Open last Overseer task output' }
)

vim.keymap.set('n', '<Leader>oa', function()
    overseer_last_task(true)
end, { desc = 'Attach to last Overseer task output' })
