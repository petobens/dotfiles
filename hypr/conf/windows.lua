-- luacheck: globals hl

local geometry = require('conf.geometry')
local window_actions = require('conf.window_actions')
local maximized_tag = '+' .. window_actions.work_area_maximized_tag

-- Application layouts use fractions of the usable monitor area
local half = { x = 0.25, y = 0.25, width = 0.5, height = 0.5 }
local rectangle = { x = 0.125, y = 0.2, width = 0.75, height = 0.6 }
local right_half = { x = 0.5, y = 0, width = 0.5, height = 1 }
local layout_by_class = {
    hyprpwcenter = rectangle,
    ['org.hyprland.hyprpwcenter'] = rectangle,
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

local function fit_to_work_area(window)
    if window.fullscreen == 0 and window_actions.fills_work_area(window) then
        geometry.fill_work_area(window)
    else
        geometry.constrain(window)
    end
end

local function fit_all_to_work_area()
    for _, window in ipairs(hl.get_windows()) do
        fit_to_work_area(window)
    end
end

local function apply_layout(window)
    local layout = layout_by_class[window.initial_class]
        or layout_by_class[window.class]
        or layout_by_title[window.initial_title]
    if layout then
        geometry.place(window, layout)
    else
        fit_to_work_area(window)
    end
end

-- Defaults
window_rule('.*', { float = true, suppress_event = 'maximize' })
hl.window_rule({
    -- Maximize the tagged main terminal because Ghostty ignores its requested class
    match = { tag = 'terminal' },
    tag = maximized_tag,
})

-- Assigned workspaces
window_rule('^(brave-browser|brave-calendar.*|microsoft-edge-dev.*)$', {
    workspace = '1 silent',
    tag = maximized_tag,
})
window_rule('^Qemu-system-x86_64$', {
    workspace = '1',
    tag = maximized_tag,
})
window_rule(
    '^(slack|brave-teams.*|brave-meet.*|brave-mail.*|zoom)$',
    { workspace = '2 silent', tag = maximized_tag }
)
window_rule('^Spotify$', {
    workspace = '3 silent',
    tag = maximized_tag,
})
window_rule('^mpv$', {
    -- Native maximization keeps MPV's fullscreen idle inhibitor active
    maximize = true,
})
window_rule(
    '^(com\\.transmissionbt\\.transmission.*|obs|com.obsproject.Studio)$',
    { workspace = '4 silent', tag = maximized_tag }
)
window_rule('^(DesktopEditors|ONLYOFFICE)$', { workspace = '4 silent' })

-- Application layouts
hl.on('window.open', apply_layout)

-- Move the pointer inside QEMU when keyboard focus cannot trigger grab-on-hover
hl.on('window.active', function(window)
    if window and window.class == 'Qemu-system-x86_64' then
        local cursor = hl.get_cursor_pos()
        local outside = cursor.x < window.at.x
            or cursor.x >= window.at.x + window.size.x
            or cursor.y < window.at.y
            or cursor.y >= window.at.y + window.size.y
        if outside then
            hl.dispatch(hl.dsp.cursor.move({
                x = window.at.x + window.size.x / 2,
                y = window.at.y + window.size.y / 2,
            }))
        end
    end
end)

-- Reapply work-area bounds when windows move or monitor reservations change
hl.on('window.move_to_workspace', fit_to_work_area)
hl.on('monitor.layout_changed', function()
    fit_all_to_work_area()
end)
hl.on('layer.opened', function(layer)
    if layer.namespace == 'waybar' then
        fit_all_to_work_area()
    end
end)

-- Keep the session awake while call apps are focused or mpv is fullscreen
window_rule('^(zoom|brave-meet.*|brave-teams.*)$', { idle_inhibit = 'focus' })
window_rule('^mpv$', { idle_inhibit = 'fullscreen' })

-- Layers
hl.layer_rule({ match = { namespace = 'waybar' }, blur = true, ignore_alpha = 0.2 })
-- Rofi lists passwords and clipboard history, so hide it from screen shares
hl.layer_rule({ match = { namespace = 'rofi' }, blur = true, no_screen_share = true })
