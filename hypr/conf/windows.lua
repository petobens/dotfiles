-- luacheck: globals hl

local geometry = require('conf.geometry')

-- Application layouts use fractions of the usable monitor area
local half = { x = 0.25, y = 0.25, width = 0.5, height = 0.5 }
local rectangle = { x = 0.125, y = 0.2, width = 0.75, height = 0.6 }
local right_half = { x = 0.5, y = 0, width = 0.5, height = 1 }
local layout_by_class = {
    hyprpwcenter = half,
    ['org.hyprland.hyprpwcenter'] = half,
    localsend = half,
    localsend_app = half,
    ['org.pwmt.zathura'] = right_half,
    imv = right_half,
    ['xdg-desktop-portal-gtk'] = rectangle,
}
local layout_by_title = {
    ['About Arch'] = half,
    numbers = half,
    QuickTerm = half,
    ['docker-info'] = rectangle,
    htop = rectangle,
    OneDrive = rectangle,
    ['Trash Can'] = rectangle,
    yazi = rectangle,
}

-- Helpers
local function window_rule(class, options)
    options.match = { class = class }
    hl.window_rule(options)
end

-- Defaults
window_rule('.*', { float = true, suppress_event = 'maximize' })
hl.window_rule({
    match = { tag = 'terminal' },
    maximize = true,
    tag = '+default-maximized',
})

-- Assigned workspaces
window_rule('^(brave-browser|brave-calendar.*|microsoft-edge-dev.*)$', {
    workspace = '1 silent',
    maximize = true,
    tag = '+default-maximized',
})
window_rule(
    '^(slack|brave-teams.*|brave-meet.*|brave-mail.*|zoom)$',
    { workspace = '2 silent', maximize = true, tag = '+default-maximized' }
)
window_rule('^(Spotify|mpv)$', {
    workspace = '3 silent',
    maximize = true,
    tag = '+default-maximized',
})
window_rule(
    '^(com\\.transmissionbt\\.transmission.*|obs|com.obsproject.Studio)$',
    { workspace = '4 silent', maximize = true, tag = '+default-maximized' }
)
window_rule('^(DesktopEditors|ONLYOFFICE)$', { workspace = '4 silent' })
window_rule('^Qemu-system-x86_64$', {
    workspace = '1',
    maximize = true,
    tag = '+default-maximized',
})

-- Application layouts
hl.on('window.open', function(window)
    local layout = layout_by_class[window.initial_class]
        or layout_by_class[window.class]
        or layout_by_title[window.initial_title]
    if layout then
        geometry.place(window, layout)
    else
        geometry.constrain(window)
    end
end)

-- Reapply work-area bounds when windows move or monitor reservations change
hl.on('window.move_to_workspace', function(window)
    geometry.constrain(window)
end)
hl.on('monitor.layout_changed', function()
    geometry.constrain_all()
end)
hl.on('layer.opened', function(layer)
    if layer.namespace == 'waybar' then
        geometry.constrain_all()
    end
end)

-- Keep the session awake while call apps are focused or mpv is fullscreen
window_rule('^(zoom|brave-meet.*|brave-teams.*)$', { idle_inhibit = 'focus' })
window_rule('^mpv$', { idle_inhibit = 'fullscreen' })

-- Layers
hl.layer_rule({ match = { namespace = 'waybar' }, blur = true, ignore_alpha = 0.2 })
-- Rofi lists passwords and clipboard history, so hide it from screen shares
hl.layer_rule({ match = { namespace = 'rofi' }, blur = true, no_screen_share = true })
