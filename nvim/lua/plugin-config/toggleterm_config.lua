require('toggleterm').setup({
    size = function(term)
        if term.direction == 'horizontal' then
            return 15
        elseif term.direction == 'vertical' then
            return vim.o.columns * 0.4
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
    callback = function()
        vim.opt_local.statuscolumn = ''
        vim.opt_local.winfixbuf = true
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>st', ':ToggleTerm direction=horizontal<CR>')
vim.keymap.set('n', '<Leader>vt', ':ToggleTerm direction=vertical<CR>')
vim.keymap.set('n', '<Leader>tc', ':TermExec cmd="exit"<CR>')
vim.keymap.set('n', '<Leader>tw', ':TermExec cmd="clear"<CR>')
vim.keymap.set('n', '<Leader>rl', ':ToggleTermSendCurrentLine<CR>')
vim.keymap.set('v', '<Leader>ri', ':ToggleTermSendVisualSelection<CR>')
