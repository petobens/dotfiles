-- Prefer Wayland while retaining XWayland fallbacks for older applications
local environment = {
    XCURSOR_SIZE = '24',
    HYPRCURSOR_SIZE = '24',
    ELECTRON_OZONE_PLATFORM_HINT = 'auto',
    MOZ_ENABLE_WAYLAND = '1',
    QT_QPA_PLATFORM = 'wayland;xcb',
    QT_WAYLAND_DISABLE_WINDOWDECORATION = '1',
    SDL_VIDEODRIVER = 'wayland',
    GDK_BACKEND = 'wayland,x11,*',
}

for name, value in pairs(environment) do
    hl.env(name, value)
end
