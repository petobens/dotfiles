-- Options
vim.opt_local.colorcolumn = ''
vim.opt_local.textwidth = 0
vim.opt_local.spell = false
vim.opt_local.buflisted = false
vim.opt_local.winfixbuf = true
-- Show qf as bottom window
vim.cmd.wincmd('J')
vim.api.nvim_win_set_height(0, math.max(1, math.min(vim.api.nvim_buf_line_count(0), 15)))

-- Autocmd options
vim.api.nvim_create_autocmd({ 'QuitPre', 'BufDelete' }, {
    group = vim.api.nvim_create_augroup('ft_qf', { clear = true }),
    desc = 'Auto-close loclist when quitting a window',
    callback = function()
        if vim.bo.filetype ~= 'qf' then
            vim.cmd.lclose({ mods = { silent = true } })
        end
    end,
})

-- Mappings
vim.keymap.set('n', 'q', function()
    local close_cmd = vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0 and 'lclose'
        or 'cclose'
    if _G.LastWinId and vim.api.nvim_win_is_valid(_G.LastWinId) then
        vim.api.nvim_set_current_win(_G.LastWinId)
    end
    vim.cmd[close_cmd]()
end, { buffer = true, desc = 'Close quickfix/loclist and return to last window' })

vim.keymap.set(
    'n',
    'Q',
    'q',
    { buffer = true, remap = true, desc = "Alias for 'q' (close qf/loclist and return)" }
)

vim.keymap.set(
    'n',
    '<C-s>',
    '<C-w><Enter>',
    { buffer = true, desc = 'Open entry in split' }
)

vim.keymap.set(
    'n',
    '<C-v>',
    '<C-w><Enter><C-w>L',
    { buffer = true, desc = 'Open entry in vsplit' }
)

vim.keymap.set('n', '<C-q>', function()
    vim.cmd.cclose()
    vim.cmd.wincmd('p')
    vim.cmd.Telescope('quickfix')
end, { buffer = true, desc = 'Close quickfix and dump entries to Telescope' })

vim.keymap.set('n', '<C-l>', function()
    vim.cmd.lclose()
    vim.cmd.wincmd('p')
    vim.cmd.Telescope('loclist')
end, { buffer = true, desc = 'Close loclist and dump entries to Telescope' })
