local home = os.getenv('HOME')
local scripts = home .. '/.config/hypr/scripts/'

local function exec(keys, command, description, flags)
    flags = flags or {}
    flags.description = description
    hl.bind(keys, hl.dsp.exec_cmd(command), flags)
end

exec('SUPER + CTRL + R', 'hyprctl reload', 'Reload Hyprland')
hl.bind(
    'SUPER + E',
    hl.dsp.window.fullscreen({ action = 'toggle' }),
    { description = 'Toggle fullscreen' }
)
hl.bind('SUPER + Q', hl.dsp.window.close({}), { description = 'Close window' })
exec('SUPER + SHIFT + W', scripts .. 'close_workspace', 'Close workspace windows')
exec('SUPER + SHIFT + Q', scripts .. 'session_menu', 'Session menu')
exec('SUPER + SHIFT + S', scripts .. 'session_menu', 'Session menu')
exec('SUPER + SHIFT + R', scripts .. 'session_menu', 'Session menu')
exec('SUPER + SHIFT + L', 'loginctl lock-session', 'Lock session')
hl.bind(
    'SUPER + mouse:272',
    hl.dsp.window.drag(),
    { mouse = true, description = 'Move window' }
)
hl.bind(
    'SUPER + mouse:273',
    hl.dsp.window.resize(),
    { mouse = true, description = 'Resize window' }
)

-- Place floating windows in predictable screen regions
local placements = {
    ['SUPER + UP'] = 'full',
    ['SUPER + LEFT'] = 'left',
    ['SUPER + RIGHT'] = 'right',
    ['SUPER + ALT + UP'] = 'top',
    ['SUPER + ALT + DOWN'] = 'bottom',
    ['SUPER + CTRL + 1'] = 'top-left',
    ['SUPER + CTRL + 2'] = 'top-right',
    ['SUPER + CTRL + 3'] = 'bottom-left',
    ['SUPER + CTRL + 4'] = 'bottom-right',
    ['SUPER + CTRL + 5'] = 'center',
    ['SUPER + CTRL + 6'] = 'rectangle',
    ['SUPER + CTRL + 7'] = 'dialog',
    ['SUPER + CTRL + 8'] = 'semi-full',
}
for keys, placement in pairs(placements) do
    exec(keys, scripts .. 'place_window ' .. placement, 'Place window ' .. placement)
end
hl.bind(
    'SUPER + H',
    hl.dsp.window.resize({ x = -60, y = 0, relative = true }),
    { repeating = true }
)
hl.bind(
    'SUPER + J',
    hl.dsp.window.resize({ x = 0, y = 60, relative = true }),
    { repeating = true }
)
hl.bind(
    'SUPER + K',
    hl.dsp.window.resize({ x = 0, y = -60, relative = true }),
    { repeating = true }
)
hl.bind(
    'SUPER + L',
    hl.dsp.window.resize({ x = 60, y = 0, relative = true }),
    { repeating = true }
)

hl.bind('SUPER + N', hl.dsp.focus({ workspace = 'm+1' }))
hl.bind('SUPER + P', hl.dsp.focus({ workspace = 'm-1' }))
hl.bind('ALT + grave', hl.dsp.focus({ monitor = '+1' }))
hl.bind('ALT + escape', hl.dsp.focus({ monitor = '-1' }))
hl.bind('SUPER + CTRL + RIGHT', hl.dsp.window.move({ monitor = '+1', follow = true }))
hl.bind('SUPER + CTRL + LEFT', hl.dsp.window.move({ monitor = '-1', follow = true }))
hl.bind('SUPER + SHIFT + RIGHT', hl.dsp.workspace.move({ monitor = '+1' }))
hl.bind('SUPER + SHIFT + LEFT', hl.dsp.workspace.move({ monitor = '-1' }))
hl.bind('SUPER + CTRL + J', function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Provide four reusable quick window marks
local marks = {
    { 'SUPER + ALT + M', 'SUPER + CTRL + K', 'markedwin1' },
    { 'SUPER + ALT + bracketleft', 'SUPER + CTRL + bracketleft', 'markedwin2' },
    { 'SUPER + ALT + bracketright', 'SUPER + CTRL + bracketright', 'markedwin3' },
    { 'SUPER + ALT + period', 'SUPER + CTRL + period', 'markedwin4' },
}
for _, mark in ipairs(marks) do
    local tag = mark[3]
    hl.bind(mark[1], function()
        hl.dispatch(hl.dsp.window.tag({ tag = '-' .. tag, window = 'tag:' .. tag }))
        hl.dispatch(hl.dsp.window.tag({ tag = '+' .. tag }))
    end, { description = 'Mark window' })
    hl.bind(
        mark[2],
        hl.dsp.focus({ window = 'tag:' .. tag }),
        { description = 'Focus marked window' }
    )
end

for workspace = 1, 9 do
    hl.bind('SUPER + ' .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
    hl.bind(
        'SUPER + SHIFT + ' .. workspace,
        hl.dsp.window.move({ workspace = tostring(workspace), follow = true })
    )
end

exec('ALT + TAB', scripts .. 'window_switcher', 'Window switcher')
exec('SUPER + W', scripts .. 'window_switcher', 'Window switcher')
exec('SUPER + S', 'rofi -show drun', 'Application launcher')
exec('SUPER + A', 'rofi -show drun', 'Application launcher')
exec('SUPER + Z', scripts .. 'password_menu', 'Password menu')
exec('SUPER + CTRL + Y', 'hyprpicker -a', 'Copy picked color')
exec('SUPER + X', 'ghostty', 'Terminal')
exec('SUPER + CTRL + C', scripts .. 'app terminal', 'Terminal')
exec('SUPER + CTRL + F', 'ghostty -e yazi', 'File manager')
exec('SUPER + CTRL + P', 'zathura', 'PDF viewer')
exec('SUPER + CTRL + V', 'imv ~/Pictures', 'Image viewer')
exec('SUPER + CTRL + W', 'ghostty -e impala', 'Wi-Fi')
exec('SUPER + CTRL + Q', 'ghostty', 'Quick terminal')
exec('SUPER + CTRL + N', 'ghostty -e ipython', 'IPython')
exec('SUPER + CTRL + H', 'ghostty -e htop', 'Process monitor')
exec('SUPER + CTRL + B', 'blueman-manager', 'Bluetooth')
exec('CTRL + ALT + Delete', 'ghostty -e htop', 'Process manager')

local apps = {
    { 'SUPER + CTRL + I', 'brave', 'Brave' },
    { 'SUPER + CTRL + A', 'calendar', 'Calendar' },
    { 'SUPER + CTRL + comma', 'clickup', 'ClickUp' },
    { 'SUPER + CTRL + E', 'edge', 'Edge' },
    { 'SUPER + CTRL + L', 'slack', 'Slack' },
    { 'SUPER + CTRL + S', 'teams', 'Teams' },
    { 'SUPER + CTRL + Z', 'zoom', 'Zoom' },
    { 'SUPER + CTRL + O', 'meet', 'Google Meet' },
    { 'SUPER + CTRL + G', 'gmail', 'Gmail' },
    { 'SUPER + CTRL + M', 'spotify', 'Spotify' },
    { 'SUPER + CTRL + U', 'transmission', 'Transmission' },
    { 'SUPER + CTRL + D', 'onlyoffice', 'OnlyOffice' },
}
for _, app in ipairs(apps) do
    exec(app[1], scripts .. 'app ' .. app[2], app[3])
end

exec('Print', scripts .. 'screenshot full', 'Full screenshot')
exec('SUPER + SHIFT + C', scripts .. 'screenshot selection', 'Selection screenshot')
exec('SUPER + SHIFT + 0', scripts .. 'screenshot active', 'Window screenshot')
exec(
    'XF86AudioRaiseVolume',
    'wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+',
    'Raise volume',
    { repeating = true }
)
exec(
    'XF86AudioLowerVolume',
    'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-',
    'Lower volume',
    { repeating = true }
)
exec(
    'XF86AudioMute',
    'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle',
    'Mute audio',
    { locked = true }
)
exec(
    'XF86MonBrightnessUp',
    'brightnessctl set 5%+',
    'Raise brightness',
    { repeating = true }
)
exec(
    'XF86MonBrightnessDown',
    'brightnessctl set 5%-',
    'Lower brightness',
    { repeating = true }
)
exec(
    'SUPER + SHIFT + PLUS',
    'wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+',
    'Raise volume'
)
exec('SUPER + SHIFT + MINUS', 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-', 'Lower volume')
exec('SUPER + SHIFT + M', 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle', 'Mute audio')
exec('SUPER + SHIFT + V', 'hyprpwcenter', 'Audio controls')
exec('SUPER + SHIFT + P', 'playerctl --player=spotify play-pause', 'Play or pause')
exec('SUPER + SHIFT + J', 'playerctl --player=spotify next', 'Next track')
exec('SUPER + SHIFT + K', 'playerctl --player=spotify previous', 'Previous track')
exec(
    'SUPER + SHIFT + T',
    [[sh -c 'playerctl --player=spotify metadata --format "{{artist}} — {{title}}" ]]
        .. [[| xargs -r notify-send Spotify']],
    'Show current track'
)
exec('SUPER + ALT + RIGHT', 'brightnessctl set 5%+', 'Raise brightness')
exec('SUPER + ALT + LEFT', 'brightnessctl set 5%-', 'Lower brightness')
exec('SUPER + B', 'pkill -SIGUSR1 waybar', 'Toggle Waybar')
exec('CTRL + ALT + SPACE', 'makoctl dismiss', 'Dismiss notification')
exec('CTRL + SHIFT + SPACE', 'makoctl dismiss --all', 'Dismiss all notifications')
exec('CTRL + grave', 'makoctl restore', 'Restore notification')
exec(
    'CTRL + SHIFT + J',
    'makoctl menu -- rofi -dmenu -p notification',
    'Notification actions'
)
