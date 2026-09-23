local telescope = require('telescope')

local M = {}

function M.setup()
    telescope.load_extension('aerial')
    telescope.load_extension('frecency')
    telescope.load_extension('fzf')
    telescope.load_extension('luasnip')
    telescope.load_extension('neoclip')
    telescope.load_extension('thesaurus')
    telescope.load_extension('ui-select')
    telescope.load_extension('undo')

    -- Zoxide
    telescope.load_extension('z')
    vim.api.nvim_create_autocmd('BufEnter', {
        desc = 'Track opened file directories in zoxide',
        group = vim.api.nvim_create_augroup('zoxide_files', { clear = true }),
        callback = function(event)
            local buf = event.buf
            -- Ignore scratch buffers, including Telescope previews
            if not vim.bo[buf].buflisted or vim.bo[buf].buftype ~= '' then
                return
            end
            local path = vim.api.nvim_buf_get_name(buf)
            local stat = vim.uv.fs_stat(path)
            if stat and stat.type == 'file' then
                vim.system({ 'zoxide', 'add', '--', vim.fs.dirname(path) })
            end
        end,
    })
end

return M
