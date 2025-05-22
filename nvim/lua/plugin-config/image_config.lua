--- Ensure magick luarock is loaded
package.path = package.path
    .. ';'
    .. vim.fn.expand('$HOME')
    .. '/.luarocks/share/lua/5.1/?/init.lua;'
package.path = package.path
    .. ';'
    .. vim.fn.expand('$HOME')
    .. '/.luarocks/share/lua/5.1/?.lua;'

require('image').setup({
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
