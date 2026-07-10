local image_colors = require('mdmath.highlight-colors')
local mdmath = require('mdmath')

-- Kitty's Unicode-placeholder protocol encodes the image ID in foreground RGB.
-- Neovim's winblend alters that color in floats, so Kitty cannot match the
-- placeholder to its image. Disable blending only for mdmath's generated
-- placeholder highlights; the floating windows still keep winblend=6.
local image_color = getmetatable(image_colors).__index
getmetatable(image_colors).__index = function(colors, id)
    local name = image_color(colors, id)
    vim.api.nvim_set_hl(0, name, { fg = id, blend = 0 })
    return name
end

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
    dynamic_scale = 0.75,
    filetypes = {},
})

-- Autocmd mappings
vim.api.nvim_create_autocmd('FileType', {
    desc = 'Setup MdMath toggle mapping for certain filetypes',
    pattern = { 'codecompanion', 'markdown', 'tex' },
    callback = function(args)
        local bufnr = args.buf
        vim.b[bufnr].mdmath_enabled = false
        vim.keymap.set(
            'n',
            '<Leader>rm',
            toggle_mdmath,
            { buf = bufnr, desc = 'Toggle MdMath equation rendering' }
        )
    end,
})
