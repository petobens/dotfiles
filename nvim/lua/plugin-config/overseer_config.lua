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
            ['<A-v>'] = 'TogglePreview',
            ['[c'] = 'PrevTask',
            [']c'] = 'NextTask',
        },
    },
})

-- Mappings
u.keymap('n', '<Leader>os', '<Cmd>OverseerToggle bottom<CR>')
u.keymap('n', '<Leader>ot', function()
    vim.cmd('OverseerQuickAction open hsplit')
    vim.cmd('stopinsert | wincmd J | resize 15 | set winfixheight')
    vim.cmd([[nmap <silent> q :close<CR>]])
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
