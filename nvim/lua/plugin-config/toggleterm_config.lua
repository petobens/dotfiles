local u = require('utils')

require('toggleterm').setup({
    size = function(term)
        if term.direction == 'horizontal' then
            return 15
        elseif term.direction == 'vertical' then
            return vim.o.columns * 0.35
        end
    end,
    shade_terminals = false,
    highlights = {
        Normal = { link = 'Normal' },
        WinSeparator = { link = 'FloatBorder' },
    },
    winbar = {
        enabled = false,
    },
})

-- Get into insert mode whenever we enter a terminal buffer and remove statuscolumn
local term_acg = vim.api.nvim_create_augroup('TermAcg', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = term_acg,
    pattern = { '*' },
    callback = function()
        if vim.startswith(vim.api.nvim_buf_get_name(0), 'term://') then
            vim.cmd('startinsert')
        end
    end,
})
vim.api.nvim_create_autocmd('TermOpen', {
    group = term_acg,
    command = 'setlocal statuscolumn=',
})

-- Mappings
u.keymap('n', '<Leader>st', ':ToggleTerm direction=horizontal<CR>')
u.keymap('n', '<Leader>vt', ':ToggleTerm direction=vertical<CR>')
u.keymap('n', '<Leader>tc', ':TermExec cmd="exit"<CR>')
u.keymap('n', '<Leader>tw', ':TermExec cmd="clear"<CR>')
u.keymap('n', '<Leader>rl', ':ToggleTermSendCurrentLine<CR>')
u.keymap('v', '<Leader>ri', ':ToggleTermSendVisualSelection<CR>')
