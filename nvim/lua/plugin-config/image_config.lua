--- Ensure magick luarock is loaded
local luarocks = vim.fs.joinpath(vim.env.HOME, '.luarocks', 'share', 'lua', '5.1')
package.path = package.path .. ';' .. vim.fs.joinpath(luarocks, '?', 'init.lua') .. ';'
package.path = package.path .. ';' .. vim.fs.joinpath(luarocks, '?.lua') .. ';'

local image = require('image')
local image_utils = require('image/utils')

image.setup({
    tmux_show_only_in_active_window = true,
    max_height_window_percentage = 30,
    window_overlap_clear_enabled = true,
    integrations = {
        markdown = {
            enabled = true,
            clear_in_insert_mode = true,
            only_render_image_at_cursor = true,
            only_render_image_at_cursor_mode = 'inline',
        },
    },
})

-- Helpers
local function get_image_path()
    local line = vim.api.nvim_get_current_line()
    local img_path = line:match('!%[.*%]%((.+)%)') -- md image ![](path)
    if not img_path then
        img_path = line:match('%[.*%]%((.+)%)') -- md-like without !: [](path)
    end
    if not img_path then
        img_path = line:match('<image>(.-)</image>') -- html-like: <image>path</image>
    end
    if not img_path then
        -- Match the first filename-like word ending with an image extension
        img_path = line:match('([%w/%._%-:]+%.png)')
            or line:match('([%w/%._%-:]+%.jpg)')
            or line:match('([%w/%._%-:]+%.jpeg)')
            or line:match('([%w/%._%-:]+%.svg)')
            or line:match('([%w/%._%-:]+%.bmp)')
    end
    return img_path
end

local function open_image_preview()
    local path = get_image_path()
    if not path or path == '' then
        vim.notify('No image path found on current line', vim.log.levels.WARN)
        return
    end
    local preview = image.from_file(path, {})
    local term_size = image_utils.term.get_size()
    if not preview or not term_size then
        return
    end
    local width, height = image_utils.math.adjust_to_aspect_ratio(
        term_size,
        preview.image_width,
        preview.image_height,
        math.floor(vim.o.columns * 0.8),
        math.floor(vim.o.lines * 0.8)
    )
    preview:render({
        x = math.floor((vim.o.columns - width) / 2),
        y = math.floor((vim.o.lines - height) / 2),
        width = width,
        height = height,
    })
end

local function open_image_system()
    local path = get_image_path()
    if not path or path == '' then
        vim.notify('No image path found on current line', vim.log.levels.WARN)
        return
    end
    local _, err = vim.ui.open(path)
    if err then
        vim.notify(err, vim.log.levels.ERROR)
    end
end

local function clear_images()
    for _, preview in ipairs(image.get_images()) do
        preview:clear()
    end
end

-- Mappings
vim.keymap.set(
    'n',
    '<Leader>ii',
    open_image_preview,
    { desc = 'Preview image under cursor' }
)
vim.keymap.set('n', '<Leader>iw', clear_images, { desc = 'Wipe all image previews' })
vim.keymap.set(
    'n',
    '<Leader>is',
    open_image_system,
    { desc = 'Open image under cursor with system handler' }
)
