local u = require('utils')

-- Options
vim.opt_local.colorcolumn = ''
vim.opt_local.textwidth = 0
vim.opt_local.spell = false
vim.opt_local.buflisted = false

-- Appearance
vim.cmd('wincmd J')
vim.cmd(math.max(1, math.min(vim.fn.line('$'), 15)) .. 'wincmd _')

-- Mappings
local map_opts = { buffer = true }
u.keymap('n', 'q', '<Cmd>bdelete<CR>', map_opts)
u.keymap('n', 'Q', '<Cmd>bdelete<CR>', map_opts)
u.keymap('n', '<C-s>', '<C-w><Enter>', map_opts)
u.keymap('n', '<C-v>', '<C-w><Enter><C-w>L', map_opts)
u.keymap('n', '<C-q>', '<Cmd>cclose<bar>wincmd p<bar>Telescope quickfix<CR>', map_opts)
u.keymap('n', '<C-l>', '<Cmd>lclose<bar>wincmd p<bar>Telescope loclist<CR>', map_opts)

-- Autocmds
vim.api.nvim_create_autocmd({ 'QuitPre', 'BufDelete' }, {
    group = vim.api.nvim_create_augroup('ft_qf', { clear = true }),
    callback = function()
        -- Automatically close corresponding loclist when quitting a window
        if vim.bo.filetype ~= 'qf' then
            vim.cmd('silent! lclose')
        end
    end,
})
