local mdmath = require('mdmath')

-- Helpers
local function toggle_mdmath()
    local bufnr = vim.api.nvim_get_current_buf()
    if not mdmath.is_loaded then
        mdmath.setup(false)
    end

    vim.b[bufnr].mdmath_enabled = not vim.b[bufnr].mdmath_enabled
    if vim.b[bufnr].mdmath_enabled then
        mdmath.enable(bufnr)
    else
        mdmath.disable(bufnr)
    end
end

-- Setup
mdmath.setup({
    filetypes = {},
})

-- Autocmd mappings
vim.api.nvim_create_autocmd('FileType', {
    desc = 'Setup MdMath toggle mapping for certain filetypes',
    -- FIXME: Doesn't work in floating windows as codecompanion
    pattern = { 'markdown', 'tex' },
    callback = function(args)
        local bufnr = args.buf
        vim.b[bufnr].mdmath_enabled = false
        vim.keymap.set(
            'n',
            '<Leader>rm',
            toggle_mdmath,
            { buffer = bufnr, desc = 'Toggle MdMath equation rendering' }
        )
    end,
})
