-- luacheck: globals hl

local geometry = require('conf.geometry')
local window_actions = require('conf.window_actions')
local maximized_tag = '+' .. window_actions.work_area_maximized_tag

-- Application layouts use fractions of the usable monitor area
local half = { x = 0.25, y = 0.25, width = 0.5, height = 0.5 }
local rectangle = { x = 0.125, y = 0.2, width = 0.75, height = 0.6 }
local right_half = { x = 0.5, y = 0, width = 0.5, height = 1 }
local layout_by_class = {
    kitty = half,
    ['org.localsend.localsend_app'] = right_half,
    ['org.pwmt.zathura'] = right_half,
    imv = right_half,
    ['xdg-desktop-portal-gtk'] = rectangle,
}
local layout_by_title = {
    ['About Arch'] = half,
    numbers = half,
    QuickTerm = half,
    ['docker-info'] = half,
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

local function app_layout(window)
    if
        window.class == 'org.localsend.localsend_app'
        and window.initial_title == 'Open File'
    then
        return half
    end

    return layout_by_class[window.initial_class]
        or layout_by_class[window.class]
        or layout_by_title[window.initial_title]
end

local function apply_layout(window)
    local layout = app_layout(window)
    if layout then
        geometry.place(window, layout)
    else
        fit_to_work_area(window)
    end
end

-- Application helpers
local function focus_google_sign_in(window)
    local browser = window.class == 'brave-browser'
        or window.class == 'firefox'
        or window.class:match('^microsoft%-edge%-dev')
    if
        not browser
        or not window.title:match('^Sign [iI]n %- Google Accounts%f[%z%s]')
        or not window.accepts_input
        or window.hidden
    then
        return
    end

    -- Page titles cannot distinguish a sign-in tab from a separate popup
    if not window.active then
        hl.dispatch(hl.dsp.focus({ window = window }))
    end
    hl.dispatch(hl.dsp.window.bring_to_top({ window = window }))
end

-- Tag the last main browser for scripts/brave_open to reuse for links
-- Ignore brief browser focus while switching to another app on its workspace
local function remember_main_brave(window)
    if not window or window.class ~= 'brave-browser' then
        return
    end
    local address = window.address
    hl.timer(function()
        local active = hl.get_active_window()
        if not active or active.address ~= address then
            return
        end
        hl.dispatch(hl.dsp.window.tag({
            tag = '-last-main-brave',
            window = 'tag:last-main-brave',
        }))
        hl.dispatch(hl.dsp.window.tag({ tag = '+last-main-brave', window = active }))
    end, { timeout = 50, type = 'oneshot' })
end

-- Defaults
window_rule('.*', { float = true, suppress_event = 'maximize' })
window_rule('^gcr-prompter$', { stay_focused = true })
window_rule('^com\\.gabm\\.satty$', { fullscreen = true })
hl.window_rule({
    -- Maximize the tagged main terminal because Ghostty ignores its requested class
    match = { tag = 'terminal' },
    tag = maximized_tag,
})

-- Assigned workspaces
window_rule('^(brave-browser|brave-calendar.*|firefox|microsoft-edge-dev.*)$', {
    workspace = '1 silent',
    tag = maximized_tag,
})
window_rule('^msedge-app\\.clickup\\.com.*$', {
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
hl.window_rule({
    -- Zoom restores its own size after the initial work-area placement
    match = { class = '^zoom$', title = '^Zoom Workplace.*$' },
    maximize = true,
})
window_rule('^spotify$', {
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
window_rule('^(DesktopEditors|ONLYOFFICE)$', {
    workspace = '4 silent',
    tag = maximized_tag,
})
hl.window_rule({
    -- Keep modal dialogs at the size requested by ONLYOFFICE
    match = { class = '^(DesktopEditors|ONLYOFFICE)$', modal = true },
    tag = '-' .. window_actions.work_area_maximized_tag,
})

-- Application layouts
hl.on('window.open', function(window)
    apply_layout(window)
    focus_google_sign_in(window)
    -- Follow new windows and dialogs even when workspace rules place them silently
    if window.accepts_input and not window.hidden and not window.active then
        hl.dispatch(hl.dsp.focus({ window = window }))
    end
end)

-- Browser events
-- Match the loaded page title, which may arrive after the window opens
hl.on('window.title', focus_google_sign_in)
hl.on('window.active', remember_main_brave)

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
hl.layer_rule({ match = { namespace = 'rofi' }, blur = true })
