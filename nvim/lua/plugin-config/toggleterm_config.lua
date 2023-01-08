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
    },
    winbar = {
        enabled = false,
    },
})

u.keymap('n', '<Leader>st', ':ToggleTerm direction=horizontal<CR>')
u.keymap('n', '<Leader>vt', ':ToggleTerm direction=vertical<CR>')
u.keymap('n', '<Leader>tc', ':TermExec cmd="exit"<CR>')
u.keymap('n', '<Leader>tw', ':TermExec cmd="clear"<CR>')
u.keymap('n', '<Leader>ri', ':ToggleTermSendCurrentLine<CR>')
u.keymap('v', '<Leader>ri', ':ToggleTermSendVisualSelection<CR>')
