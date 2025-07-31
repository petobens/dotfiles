local overseer = require('overseer')

_G.OverseerConfig = {} -- to store error formats

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
    vim.cmd.OverseerQuickAction({ args = { 'open', 'hsplit' } })
    vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight')
    vim.cmd([[nmap <silent> q :close<CR>]])
    if attach then
        vim.cmd.startinsert()
        return
    end
    vim.opt_local.winfixbuf = true
    vim.opt_local.modifiable = true
    vim.cmd.normal({ args = { 'kdGggG' }, bang = true, mods = { silent = true } })
    vim.opt_local.modifiable = false
end

-- Mappings
vim.keymap.set('n', '<Leader>os', '<Cmd>OverseerToggle bottom<CR>')
vim.keymap.set('n', '<Leader>oo', overseer_last_task)
vim.keymap.set('n', '<Leader>oa', function()
    overseer_last_task(true)
end)
local overseer_augroup = vim.api.nvim_create_augroup('OverseerConfig', {})
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'OverseerList',
    group = overseer_augroup,
    callback = function(e)
        vim.opt_local.winfixbuf = true
        vim.defer_fn(function()
            vim.cmd.stopinsert()
        end, 1)

        vim.keymap.set('n', 'q', function()
            pcall(vim.api.nvim_win_close, 0, true)
            vim.cmd.wincmd({ args = { 'p' } })
        end, { buffer = e.buf })
    end,
})
