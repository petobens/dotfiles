-- luacheck: globals hl

local cursor_size = '24'

local environment = {
    -- Cursors
    HYPRCURSOR_SIZE = cursor_size,
    XCURSOR_SIZE = cursor_size,
    XCURSOR_THEME = 'capitaine-cursors',

    -- Application toolkits
    ELECTRON_OZONE_PLATFORM_HINT = 'auto',
    GDK_BACKEND = 'wayland,x11,*',
    MOZ_ENABLE_WAYLAND = '1',
    QT_QPA_PLATFORM = 'wayland;xcb',
    QT_WAYLAND_DISABLE_WINDOWDECORATION = '1',
    SDL_VIDEODRIVER = 'wayland',
}

for name, value in pairs(environment) do
    hl.env(name, value)
end
