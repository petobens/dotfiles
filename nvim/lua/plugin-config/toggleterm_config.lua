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

-- Get into insert mode whenever we enter a terminal buffer
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('TermAcg', { clear = true }),
    pattern = { '*' },
    callback = function()
        if vim.bo.buftype == 'terminal' then
            vim.cmd('startinsert')
        end
    end,
})

-- Mappings
u.keymap('n', '<Leader>st', ':ToggleTerm direction=horizontal<CR>')
u.keymap('n', '<Leader>vt', ':ToggleTerm direction=vertical<CR>')
u.keymap('n', '<Leader>tc', ':TermExec cmd="exit"<CR>')
u.keymap('n', '<Leader>tw', ':TermExec cmd="clear"<CR>')
u.keymap('n', '<Leader>rl', ':ToggleTermSendCurrentLine<CR>')
u.keymap('v', '<Leader>ri', ':ToggleTermSendVisualSelection<CR>')
