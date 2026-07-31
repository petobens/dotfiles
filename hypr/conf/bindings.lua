-- luacheck: globals hl

local monitor_modes = require('conf.monitors')

-- Commands
local scripts = os.getenv('HOME') .. '/.config/hypr/scripts/'
local app_command = scripts .. 'app '
local brightness_command = scripts .. 'brightness '
local player_command = 'playerctl --player=spotify'
local volume_command = scripts .. 'volume '
local volume_up = volume_command .. 'up'
local volume_down = volume_command .. 'down'
local volume_mute = volume_command .. 'mute'

-- Modifiers
local alt = 'ALT'
local super = 'SUPER'
local super_alt = super .. ' + ALT'
local super_ctrl = super .. ' + CTRL'
local super_shift = super .. ' + SHIFT'
local ctrl_alt = 'CTRL + ALT'
local ctrl_shift = 'CTRL + SHIFT'

-- Helpers
local function bind(keys, dispatcher, description, options)
    options = options or {}
    options.description = description
    hl.bind(keys, dispatcher, options)
end

local function exec(keys, command, description, options)
    bind(keys, hl.dsp.exec_cmd(command), description, options)
end

local function launch(keys, app, description)
    exec(keys, app_command .. app, description)
end

local function close_workspace()
    for _, window in ipairs(hl.get_workspace_windows(hl.get_active_workspace())) do
        hl.dispatch(hl.dsp.window.close({ window = window }))
    end
end

local function place_window(placement)
    return function()
        local window = hl.get_active_window()
        if not window then
            return
        end

        local monitor = window.monitor
        local width = monitor.width / monitor.scale
        local height = monitor.height / monitor.scale
        hl.dispatch(hl.dsp.window.float({ action = 'enable', window = window }))
        hl.dispatch(hl.dsp.window.resize({
            x = width * placement[5],
            y = height * placement[6],
            window = window,
        }))
        hl.dispatch(hl.dsp.window.move({
            x = monitor.x + width * placement[3],
            y = monitor.y + height * placement[4],
            window = window,
        }))
    end
end

local function move_to_monitor(kind, direction)
    return function()
        local source = hl.get_active_monitor()
        local target = hl.get_monitor(direction)
        if not source or not target or source == target then
            return
        end

        local windows
        if kind == 'window' then
            local window = hl.get_active_window()
            if not window then
                return
            end
            windows = { window }
        else
            windows = hl.get_workspace_windows(hl.get_active_workspace())
        end

        local geometries = {}
        for _, window in ipairs(windows) do
            if window.fullscreen == 0 then
                table.insert(geometries, {
                    window = window,
                    position = window.at,
                    size = window.size,
                })
            end
        end

        if kind == 'window' then
            hl.dispatch(hl.dsp.window.move({ monitor = direction, follow = true }))
        else
            hl.dispatch(hl.dsp.workspace.move({ monitor = direction }))
        end

        local scale_x = target.width / target.scale / (source.width / source.scale)
        local scale_y = target.height / target.scale / (source.height / source.scale)
        for _, geometry in ipairs(geometries) do
            hl.dispatch(hl.dsp.window.resize({
                x = geometry.size.x * scale_x,
                y = geometry.size.y * scale_y,
                window = geometry.window,
            }))
            hl.dispatch(hl.dsp.window.move({
                x = target.x + (geometry.position.x - source.x) * scale_x,
                y = target.y + (geometry.position.y - source.y) * scale_y,
                window = geometry.window,
            }))
        end
    end
end

-- Session and windows
exec(super_ctrl .. ' + R', 'hyprctl reload', 'Reload Hyprland')
bind(
    super .. ' + E',
    hl.dsp.window.fullscreen({ action = 'toggle' }),
    'Toggle fullscreen'
)
bind(super .. ' + Q', hl.dsp.window.close({}), 'Close window')
bind(super_shift .. ' + W', close_workspace, 'Close workspace windows')
for _, keys in ipairs({
    super_shift .. ' + Q',
    super_shift .. ' + S',
    super_shift .. ' + R',
}) do
    exec(keys, scripts .. 'session_menu', 'Session menu')
end
exec(super_shift .. ' + L', 'loginctl lock-session', 'Lock session')
bind(super .. ' + mouse:272', hl.dsp.window.drag(), 'Move window', { mouse = true })
bind(super .. ' + mouse:273', hl.dsp.window.resize(), 'Resize window', { mouse = true })

-- Window placement
local placements = {
    { super .. ' + UP', 'full', 0, 0, 1, 1 },
    { super .. ' + LEFT', 'left', 0, 0, 0.5, 1 },
    { super .. ' + RIGHT', 'right', 0.5, 0, 0.5, 1 },
    { super_alt .. ' + UP', 'top', 0, 0, 1, 0.5 },
    { super_alt .. ' + DOWN', 'bottom', 0, 0.5, 1, 0.5 },
    { super_ctrl .. ' + 1', 'top-left', 0, 0, 0.5, 0.5 },
    { super_ctrl .. ' + 2', 'top-right', 0.5, 0, 0.5, 0.5 },
    { super_ctrl .. ' + 3', 'bottom-left', 0, 0.5, 0.5, 0.5 },
    { super_ctrl .. ' + 4', 'bottom-right', 0.5, 0.5, 0.5, 0.5 },
    { super_ctrl .. ' + 5', 'center', 0.25, 0.25, 0.5, 0.5 },
    { super_ctrl .. ' + 6', 'rectangle', 0.125, 0.2, 0.75, 0.6 },
    { super_ctrl .. ' + 7', 'dialog', 0.33, 0.3, 0.35, 0.25 },
    { super_ctrl .. ' + 8', 'semi-full', 0.01, 0, 0.985, 0.99 },
}
for _, placement in ipairs(placements) do
    bind(placement[1], place_window(placement), 'Place window ' .. placement[2])
end

local step = 60
local edge_resizes = {
    { super .. ' + H', step, 0, -step, 0, 'Grow window left' },
    { super_alt .. ' + L', -step, 0, step, 0, 'Shrink window left' },
    { super .. ' + L', step, 0, 0, 0, 'Grow window right' },
    { super_alt .. ' + H', -step, 0, 0, 0, 'Shrink window right' },
    { super .. ' + K', 0, step, 0, -step, 'Grow window up' },
    { super_alt .. ' + J', 0, -step, 0, step, 'Shrink window up' },
    { super .. ' + J', 0, step, 0, 0, 'Grow window down' },
    { super_alt .. ' + K', 0, -step, 0, 0, 'Shrink window down' },
}
local function resize_edge(resize)
    return function()
        hl.dispatch(hl.dsp.window.resize({
            x = resize[2],
            y = resize[3],
            relative = true,
        }))
        if resize[4] ~= 0 or resize[5] ~= 0 then
            hl.dispatch(hl.dsp.window.move({
                x = resize[4],
                y = resize[5],
                relative = true,
            }))
        end
    end
end
for _, resize in ipairs(edge_resizes) do
    bind(resize[1], resize_edge(resize), resize[6], { repeating = true })
end

-- Navigation and workspaces
bind(super .. ' + N', hl.dsp.focus({ workspace = 'm+1' }), 'Next workspace')
bind(super .. ' + P', hl.dsp.focus({ workspace = 'm-1' }), 'Previous workspace')
bind(alt .. ' + grave', hl.dsp.focus({ monitor = 'r' }), 'Focus monitor right')
bind(alt .. ' + escape', hl.dsp.focus({ monitor = 'd' }), 'Focus monitor down')

local monitor_directions = {
    { 'RIGHT', 'r', 'right' },
    { 'LEFT', 'l', 'left' },
    { 'DOWN', 'd', 'down' },
    { 'UP', 'u', 'up' },
}
for _, direction in ipairs(monitor_directions) do
    bind(
        super_ctrl .. ' + ' .. direction[1],
        move_to_monitor('window', direction[2]),
        'Move window to monitor ' .. direction[3]
    )
    bind(
        super_shift .. ' + ' .. direction[1],
        move_to_monitor('workspace', direction[2]),
        'Move workspace to monitor ' .. direction[3]
    )
end
bind(super .. ' + Return', monitor_modes.primary, 'Use laptop display')
bind(super_ctrl .. ' + Return', monitor_modes.multi, 'Use all displays')
bind(super_shift .. ' + Return', monitor_modes.mirror, 'Mirror laptop display')
bind(super_ctrl .. ' + J', function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, 'Focus previous window')

local marks = {
    { super_alt .. ' + M', super_ctrl .. ' + K' },
    { super_alt .. ' + bracketleft', super_ctrl .. ' + bracketleft' },
    { super_alt .. ' + bracketright', super_ctrl .. ' + bracketright' },
    { super_alt .. ' + period', super_ctrl .. ' + period' },
}
for index, mark in ipairs(marks) do
    local tag = 'markedwin' .. index
    bind(mark[1], function()
        hl.dispatch(hl.dsp.window.tag({ tag = '-' .. tag, window = 'tag:' .. tag }))
        hl.dispatch(hl.dsp.window.tag({ tag = '+' .. tag }))
    end, 'Mark window ' .. index)
    bind(
        mark[2],
        hl.dsp.focus({ window = 'tag:' .. tag }),
        'Focus marked window ' .. index
    )
end

for workspace = 1, 9 do
    local name = tostring(workspace)
    bind(super .. ' + ' .. name, hl.dsp.focus({ workspace = name }), 'Workspace ' .. name)
    bind(
        super_shift .. ' + ' .. name,
        hl.dsp.window.move({ workspace = name, follow = true }),
        'Move window to workspace ' .. name
    )
end

-- Launchers and applications
exec(alt .. ' + TAB', scripts .. 'window_switcher', 'Window switcher')
exec(super .. ' + W', scripts .. 'window_switcher current', 'Workspace window switcher')
exec(super .. ' + S', 'rofi -show drun', 'Application launcher')
launch(super .. ' + A', 'menu', 'Curated application launcher')
exec(super .. ' + Z', scripts .. 'password_menu', 'Password menu')
exec(super_ctrl .. ' + Y', 'hyprpicker -a', 'Copy picked color')
exec(super .. ' + X', 'ghostty --class=terminal', 'Terminal')

local applications = {
    -- Assigned workspaces
    { super_ctrl .. ' + I', 'brave', 'Brave' },
    { super_ctrl .. ' + A', 'calendar', 'Calendar' },
    { super_ctrl .. ' + comma', 'clickup', 'ClickUp' },
    { super_ctrl .. ' + E', 'edge', 'Edge' },
    { super_ctrl .. ' + L', 'slack', 'Slack' },
    { super_ctrl .. ' + S', 'teams', 'Teams' },
    { super_ctrl .. ' + Z', 'zoom', 'Zoom' },
    { super_ctrl .. ' + O', 'meet', 'Google Meet' },
    { super_ctrl .. ' + G', 'gmail', 'Gmail' },
    { super_ctrl .. ' + M', 'spotify', 'Spotify' },
    { super_ctrl .. ' + U', 'transmission', 'Transmission' },
    { super_ctrl .. ' + D', 'onlyoffice', 'OnlyOffice' },
    { super_ctrl .. ' + C', 'terminal', 'Terminal' },

    -- Current workspace
    { super_ctrl .. ' + F', 'files', 'File manager' },
    { super_ctrl .. ' + P', 'zathura', 'PDF viewer' },
    { super_ctrl .. ' + V', 'images', 'Image viewer' },
    { super_ctrl .. ' + W', 'wifi', 'Wi-Fi' },
    { super_ctrl .. ' + Q', 'quickterm', 'Quick terminal' },
    { super_ctrl .. ' + N', 'numbers', 'IPython' },
    { super_ctrl .. ' + H', 'htop', 'Process monitor' },
    { super_ctrl .. ' + B', 'bluetooth', 'Bluetooth' },
}
for _, application in ipairs(applications) do
    launch(application[1], application[2], application[3])
end
exec(ctrl_alt .. ' + Delete', scripts .. 'process_killer', 'Kill process')

-- Screenshots and recordings
exec('Print', scripts .. 'screenshot full', 'Full screenshot')
exec(super_shift .. ' + C', scripts .. 'screenshot selection', 'Selection screenshot')
exec(super_shift .. ' + 0', scripts .. 'screenshot active', 'Window screenshot')
exec(super_shift .. ' + G', scripts .. 'screen_record gif', 'Toggle GIF recording')
exec(super_alt .. ' + G', scripts .. 'screen_record video', 'Toggle video recording')

-- Audio and media
exec('XF86AudioRaiseVolume', volume_up, 'Raise volume', { repeating = true })
exec('XF86AudioLowerVolume', volume_down, 'Lower volume', { repeating = true })
exec('XF86AudioMute', volume_mute, 'Mute audio', { locked = true })
exec(super_shift .. ' + PLUS', volume_up, 'Raise volume')
exec(super_shift .. ' + MINUS', volume_down, 'Lower volume')
exec(super_shift .. ' + M', volume_mute, 'Mute audio')
launch(super_shift .. ' + V', 'audio', 'Audio controls')
exec(super_shift .. ' + P', player_command .. ' play-pause', 'Play or pause')
exec(super_shift .. ' + J', player_command .. ' next', 'Next track')
exec(super_shift .. ' + K', player_command .. ' previous', 'Previous track')
exec(super_shift .. ' + T', scripts .. 'spotify_track', 'Show current track')

-- Hardware and desktop
exec(
    'XF86MonBrightnessUp',
    brightness_command .. 'up',
    'Raise brightness',
    { repeating = true }
)
exec(
    'XF86MonBrightnessDown',
    brightness_command .. 'down',
    'Lower brightness',
    { repeating = true }
)
exec(super_alt .. ' + RIGHT', brightness_command .. 'up', 'Raise brightness')
exec(super_alt .. ' + LEFT', brightness_command .. 'down', 'Lower brightness')
exec(
    super_alt .. ' + semicolon',
    scripts .. 'keyboard_backlight',
    'Cycle keyboard backlight'
)
exec(super .. ' + B', 'pkill -SIGUSR2 waybar', 'Reload Waybar')
exec(super_shift .. ' + B', scripts .. 'empty_trash', 'Empty trash')
launch(super_alt .. ' + B', 'trash', 'Show trash')
exec(ctrl_alt .. ' + SPACE', 'makoctl dismiss', 'Dismiss notification')
exec(ctrl_shift .. ' + SPACE', 'makoctl dismiss --all', 'Dismiss all notifications')
exec('CTRL + grave', 'makoctl restore', 'Restore notification')
exec(
    ctrl_shift .. ' + J',
    'makoctl menu -- rofi -dmenu -p notification',
    'Notification actions'
)
