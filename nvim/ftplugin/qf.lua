-- Options
vim.opt_local.colorcolumn = ''
vim.opt_local.textwidth = 0
vim.opt_local.spell = false
vim.opt_local.buflisted = false
vim.opt_local.winfixbuf = true

-- Appearance
vim.cmd.wincmd('J')
local last_line = vim.api.nvim_buf_line_count(0)
vim.cmd.wincmd('_', { count = math.max(1, math.min(last_line, 15)) })

-- Mappings
local map_opts = { buffer = true }
vim.keymap.set('n', 'q', function()
    local close_cmd = 'cclose'
    if vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0 then
        close_cmd = 'lclose'
    end
    vim.api.nvim_set_current_win(_G.LastWinId)
    vim.cmd(close_cmd)
end, map_opts)
vim.keymap.set('n', 'Q', 'q', { buffer = true, remap = true })
vim.keymap.set('n', '<C-s>', '<C-w><Enter>', map_opts)
vim.keymap.set('n', '<C-v>', '<C-w><Enter><C-w>L', map_opts)
vim.keymap.set(
    'n',
    '<C-q>',
    '<Cmd>cclose<bar>wincmd p<bar>Telescope quickfix<CR>',
    map_opts
)
vim.keymap.set(
    'n',
    '<C-l>',
    '<Cmd>lclose<bar>wincmd p<bar>Telescope loclist<CR>',
    map_opts
)

-- Autocmds
vim.api.nvim_create_autocmd({ 'QuitPre', 'BufDelete' }, {
    group = vim.api.nvim_create_augroup('ft_qf', { clear = true }),
    callback = function()
        -- Automatically close corresponding loclist when quitting a window
        if vim.bo.filetype ~= 'qf' then
            vim.cmd.lclose({ mods = { silent = true } })
        end
    end,
})
