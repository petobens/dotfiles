-- luacheck: globals hl

local monitor_modes = require('conf.monitors')
local window_actions = require('conf.window_actions')

-- Commands
local scripts = os.getenv('HOME') .. '/.config/hypr/scripts/'
local app_command = scripts .. 'raise_or_launch '
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

-- Session
exec(
    super .. ' + R',
    'hyprctl reload && notify-send -i preferences-system-windows -t 2000 '
        .. '-h string:x-dunst-stack-tag:hyprland-reload "Hyprland reloaded"',
    'Reload Hyprland'
)
exec(super_shift .. ' + Q', scripts .. 'session_menu quit-apps', 'Quit all applications')
exec(super_shift .. ' + S', scripts .. 'session_menu poweroff', 'Shut down')
exec(super_shift .. ' + R', scripts .. 'session_menu reboot', 'Reboot')
exec(super_shift .. ' + L', 'loginctl lock-session', 'Lock session')

-- Windows
bind(
    super .. ' + E',
    hl.dsp.window.fullscreen({ action = 'toggle' }),
    'Toggle fullscreen'
)
bind(super .. ' + Q', hl.dsp.window.close({}), 'Close window')
bind(super_shift .. ' + W', hl.dsp.window.kill({}), 'Force close window')
bind(super_alt .. ' + W', window_actions.close_workspace, 'Close workspace windows')
bind(super .. ' + mouse:272', hl.dsp.window.drag(), 'Move window', { mouse = true })
bind(super .. ' + mouse:273', hl.dsp.window.resize(), 'Resize window', { mouse = true })

-- Window placement
bind(super .. ' + UP', window_actions.maximize, 'Maximize window')

local function placement(keys, name, x, y, width, height)
    return {
        keys = keys,
        name = name,
        geometry = { x = x, y = y, width = width, height = height },
    }
end
local placements = {
    placement(super .. ' + LEFT', 'left', 0, 0, 0.5, 1),
    placement(super .. ' + RIGHT', 'right', 0.5, 0, 0.5, 1),
    placement(super_alt .. ' + UP', 'top', 0, 0, 1, 0.5),
    placement(super_alt .. ' + DOWN', 'bottom', 0, 0.5, 1, 0.5),
    placement(super_ctrl .. ' + 1', 'top-left', 0, 0, 0.5, 0.5),
    placement(super_ctrl .. ' + 2', 'top-right', 0.5, 0, 0.5, 0.5),
    placement(super_ctrl .. ' + 3', 'bottom-left', 0, 0.5, 0.5, 0.5),
    placement(super_ctrl .. ' + 4', 'bottom-right', 0.5, 0.5, 0.5, 0.5),
    placement(super_ctrl .. ' + 5', 'center', 0.25, 0.25, 0.5, 0.5),
    placement(super_ctrl .. ' + 6', 'rectangle', 0.125, 0.2, 0.75, 0.6),
    placement(super_ctrl .. ' + 7', 'dialog', 0.33, 0.3, 0.35, 0.25),
}
for _, item in ipairs(placements) do
    bind(item.keys, window_actions.place(item.geometry), 'Place window ' .. item.name)
end

-- Window resizing
local step = 60
local function edge_resize(keys, description, x, y, width, height)
    return {
        keys = keys,
        description = description,
        delta = { width = width, height = height, x = x, y = y },
    }
end
local edge_resizes = {
    edge_resize(super .. ' + H', 'Grow window left', -step, 0, step, 0),
    edge_resize(super .. ' + L', 'Grow window right', 0, 0, step, 0),
    edge_resize(super .. ' + K', 'Grow window up', 0, -step, 0, step),
    edge_resize(super .. ' + J', 'Grow window down', 0, 0, 0, step),
    edge_resize(super_alt .. ' + H', 'Shrink window left', step, 0, -step, 0),
    edge_resize(super_alt .. ' + L', 'Shrink window right', 0, 0, -step, 0),
    edge_resize(super_alt .. ' + K', 'Shrink window up', 0, step, 0, -step),
    edge_resize(super_alt .. ' + J', 'Shrink window down', 0, 0, 0, -step),
}
for _, resize in ipairs(edge_resizes) do
    bind(
        resize.keys,
        window_actions.resize(resize.delta),
        resize.description,
        { repeating = true }
    )
end

-- Workspaces
bind(
    super .. ' + N',
    window_actions.switch_workspace(hl.dsp.focus({ workspace = 'm+1' })),
    'Next workspace'
)
bind(
    super .. ' + P',
    window_actions.switch_workspace(hl.dsp.focus({ workspace = 'm-1' })),
    'Previous workspace'
)

for workspace = 1, 9 do
    local name = tostring(workspace)
    bind(
        super .. ' + ' .. name,
        window_actions.switch_workspace(hl.dsp.focus({ workspace = name })),
        'Workspace ' .. name
    )
    bind(
        super_shift .. ' + ' .. name,
        hl.dsp.window.move({ workspace = name, follow = true }),
        'Move window to workspace ' .. name
    )
end

-- Monitors
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
        window_actions.move_to_monitor('window', direction[2]),
        'Move window to monitor ' .. direction[3]
    )
    bind(
        super_shift .. ' + ' .. direction[1],
        window_actions.move_to_monitor('workspace', direction[2]),
        'Move workspace to monitor ' .. direction[3]
    )
end
bind(super .. ' + Return', monitor_modes.primary, 'Use laptop display')
bind(super_ctrl .. ' + Return', monitor_modes.multi, 'Use all displays')
bind(super_shift .. ' + Return', monitor_modes.mirror, 'Mirror laptop display')

-- Window marks
exec(super_ctrl .. ' + J', scripts .. 'focus_window last', 'Focus previous window')

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
    exec(mark[2], scripts .. 'focus_window tag:' .. tag, 'Focus marked window ' .. index)
end

-- Launchers and menus
exec(alt .. ' + TAB', scripts .. 'window_switcher', 'Window switcher')
exec(super .. ' + W', scripts .. 'window_switcher current', 'Workspace window switcher')
exec(super .. ' + S', 'rofi -show drun', 'Application launcher')
launch(super .. ' + A', 'menu', 'Curated application launcher')
exec(super .. ' + Z', scripts .. 'password_menu', 'Password menu')
exec(super .. ' + V', scripts .. 'clipboard_menu', 'Clipboard history')
exec(super .. ' + slash', scripts .. 'binding_menu', 'Keybinding cheatsheet')

-- Applications
exec(super .. ' + X', 'kitty', 'Fallback terminal')

local applications = {
    -- Assigned workspaces
    { super_ctrl .. ' + I', 'brave', 'Brave' },
    { super_ctrl .. ' + A', 'calendar', 'Calendar' },
    { super_ctrl .. ' + comma', 'clickup', 'ClickUp' },
    { super_ctrl .. ' + E', 'edge', 'Edge' },
    { super_ctrl .. ' + G', 'gmail', 'Gmail' },
    { super_ctrl .. ' + O', 'meet', 'Google Meet' },
    { super_ctrl .. ' + D', 'onlyoffice', 'OnlyOffice' },
    { super_ctrl .. ' + L', 'slack', 'Slack' },
    { super_ctrl .. ' + M', 'spotify', 'Spotify' },
    { super_ctrl .. ' + S', 'teams', 'Teams' },
    { super_ctrl .. ' + C', 'terminal', 'Terminal' },
    { super_ctrl .. ' + U', 'transmission', 'Transmission' },
    { super_ctrl .. ' + Z', 'zoom', 'Zoom' },

    -- Current workspace
    { super_ctrl .. ' + B', 'bluetooth', 'Bluetooth' },
    { super_ctrl .. ' + F', 'files', 'File manager' },
    { super_ctrl .. ' + V', 'images', 'Image viewer' },
    { super_ctrl .. ' + N', 'numbers', 'IPython' },
    { super_ctrl .. ' + P', 'zathura', 'PDF viewer' },
    { super_ctrl .. ' + H', 'htop', 'Process monitor' },
    { super_ctrl .. ' + Q', 'quickterm', 'Quick terminal' },
    { super_ctrl .. ' + W', 'wifi', 'Wi-Fi' },
}
for _, application in ipairs(applications) do
    launch(application[1], application[2], application[3])
end

-- Screenshots and recordings
exec('Print', 'hyprshot -m active -m output', 'Monitor screenshot')
exec(
    super_shift .. ' + C',
    scripts .. 'screenshot_selection',
    'Window or region screenshot'
)
exec(super_shift .. ' + 0', 'hyprshot -m active -m window', 'Window screenshot')
exec(super_shift .. ' + G', scripts .. 'screen_record gif', 'Toggle GIF recording')
exec(super_alt .. ' + G', scripts .. 'screen_record video', 'Toggle video recording')

-- Audio and media
exec('XF86AudioRaiseVolume', volume_up, 'Raise volume', { repeating = true })
exec(super_shift .. ' + EQUAL', volume_up, 'Raise volume')
exec('XF86AudioLowerVolume', volume_down, 'Lower volume', { repeating = true })
exec(super_shift .. ' + MINUS', volume_down, 'Lower volume')
exec('XF86AudioMute', volume_mute, 'Mute audio', { locked = true })
exec(super_shift .. ' + M', volume_mute, 'Mute audio')
launch(super_shift .. ' + V', 'audio', 'Audio controls')

exec(super_shift .. ' + P', player_command .. ' play-pause', 'Play or pause')
exec(super_shift .. ' + J', player_command .. ' next', 'Next track')
exec(super_shift .. ' + K', player_command .. ' previous', 'Previous track')
exec(super_shift .. ' + T', scripts .. 'spotify_track', 'Show current track')

-- Dictation (hold to talk; the text is typed into the focused window)
exec('F10', 'voxtype record start', 'Start dictation')
exec('F10', 'voxtype record stop', 'Stop dictation', { release = true })

-- Hardware and desktop utilities
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
exec(
    super .. ' + B',
    'pkill -SIGUSR2 waybar && notify-send -i view-list -t 2000 '
        .. '-h string:x-dunst-stack-tag:waybar-reload "Waybar reloaded"',
    'Reload Waybar'
)
exec(super_shift .. ' + B', scripts .. 'empty_trash', 'Empty trash')
launch(super_alt .. ' + B', 'trash', 'Show trash')
exec(super_shift .. ' + E', scripts .. 'eject_media', 'Eject media drives')
exec(super_ctrl .. ' + Y', 'hyprpicker -a', 'Copy picked color')
exec(ctrl_alt .. ' + Delete', scripts .. 'process_killer', 'Kill process')

-- Notifications
exec(ctrl_alt .. ' + SPACE', 'makoctl dismiss', 'Dismiss notification')
exec(ctrl_shift .. ' + SPACE', 'makoctl dismiss --all', 'Dismiss all notifications')
exec('CTRL + grave', 'makoctl restore', 'Restore notification')
exec(
    ctrl_shift .. ' + J',
    'makoctl menu -- rofi -dmenu -p notification',
    'Notification actions'
)
