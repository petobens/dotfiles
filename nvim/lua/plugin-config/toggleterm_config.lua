-- Setup
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

-- Autocmd options
local term_acg = vim.api.nvim_create_augroup('TermAcg', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    desc = 'Enter insert mode on terminal buffer',
    group = term_acg,
    pattern = { '*' },
    callback = function()
        if vim.startswith(vim.api.nvim_buf_get_name(0), 'term://') then
            vim.defer_fn(function()
                vim.cmd.startinsert()
            end, 1)
        end
    end,
})
vim.api.nvim_create_autocmd('TermOpen', {
    desc = 'Remove statuscolumn in terminal buffer',
    group = term_acg,
    callback = function()
        vim.opt_local.statuscolumn = ''
    end,
})

-- Helpers
local function close_all_terminals()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match('^term://') then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end
end

-- Mappings
vim.keymap.set('n', '<Leader>st', function()
    vim.cmd.ToggleTerm('direction=horizontal')
end, { desc = 'Open horizontal terminal' })

vim.keymap.set('n', '<Leader>vt', function()
    vim.cmd.ToggleTerm('direction=vertical')
end, { desc = 'Open vertical terminal' })

vim.keymap.set('n', '<Leader>tc', close_all_terminals, { desc = 'Close all terminals' })

vim.keymap.set('n', '<Leader>tw', function()
    vim.cmd.TermExec('cmd=clear')
end, { desc = 'Clear(wipe) terminal' })

vim.keymap.set(
    'n',
    '<Leader>rl',
    vim.cmd.ToggleTermSendCurrentLine,
    { desc = 'Run current line in terminal' }
)

vim.keymap.set(
    'v',
    '<Leader>ri',
    vim.cmd.ToggleTermSendVisualSelection,
    { desc = 'Run visual selection in terminal interpreter' }
)
