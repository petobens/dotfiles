local overseer = require('overseer')
local u = require('utils')

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
            ['[c'] = 'PrevTask',
            [']c'] = 'NextTask',
            ['<A-v>'] = 'TogglePreview',
            ['<A-j>'] = 'ScrollOutputDown',
            ['<A-k>'] = 'ScrollOutputUp',
        },
    },
})

-- Helpers
local function overseer_last_task(attach)
    vim.cmd('OverseerQuickAction open hsplit')
    vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight')
    if attach then
        vim.cmd('startinsert')
    end
    vim.cmd([[nmap <silent> q :close<CR>]])
end

-- Mappings
u.keymap('n', '<Leader>os', '<Cmd>OverseerToggle bottom<CR>')
u.keymap('n', '<Leader>ot', overseer_last_task)
u.keymap('n', '<Leader>oa', function()
    overseer_last_task(true)
end)
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'OverseerList',
    group = vim.api.nvim_create_augroup('OverseerConfig', {}),
    callback = function()
        u.keymap('n', 'q', function()
            pcall(vim.api.nvim_win_close, 0, true)
            vim.cmd('wincmd p')
        end, { buffer = true })
    end,
})
