-- luacheck: globals hl

-- Layout values
local half_width = '(monitor_w*0.50)'
local half_height = '(monitor_h*0.50)'
local rectangle_size = { '(monitor_w*0.75)', '(monitor_h*0.60)' }

-- Helpers
local function window_rule(class, options)
    options.match = { class = class }
    hl.window_rule(options)
end

-- Defaults
window_rule('.*', { float = true, suppress_event = 'maximize' })
window_rule('^terminal$', { maximize = true })

-- Assigned workspaces
window_rule(
    '^(brave-browser|brave-calendar|edge-clickup|microsoft-edge-dev)$',
    { workspace = '1 silent', maximize = true }
)
window_rule(
    '^(Slack|brave-teams|brave-meet|brave-gmail)$',
    { workspace = '2 silent', maximize = true }
)
window_rule('^zoom$', {
    workspace = '2 silent',
    size = { half_width, half_height },
    center = true,
})
window_rule('^(Spotify|mpv)$', { workspace = '3 silent', maximize = true })
window_rule(
    '^(transmission-gtk|obs|com.obsproject.Studio)$',
    { workspace = '4 silent', maximize = true }
)
window_rule('^(DesktopEditors|ONLYOFFICE)$', { workspace = '4 silent' })
window_rule('^Qemu-system-x86_64$', { workspace = '1', maximize = true })

-- Application layouts
window_rule(
    '^(blueman-manager|Blueman-manager|hyprpwcenter|'
        .. 'org.hyprland.hyprpwcenter|localsend|localsend_app|numbers|quickterm)$',
    { size = { half_width, half_height }, center = true }
)
window_rule(
    '^(docker-info|htop|nmtui|onedrive|yazi)$',
    { size = rectangle_size, center = true }
)
window_rule('^(org.pwmt.zathura|imv)$', {
    size = { half_width, 'monitor_h' },
    move = { half_width, 0 },
})
window_rule('^xdg-desktop-portal-gtk$', { size = rectangle_size, center = true })

-- Layers
hl.layer_rule({ match = { namespace = 'waybar' }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = 'rofi' }, blur = true })
