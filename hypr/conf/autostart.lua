-- luacheck: globals hl

local desktop_environment = 'WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'
local scripts = os.getenv('HOME') .. '/.config/hypr/scripts/'

hl.on('hyprland.start', function()
    -- Session environment
    hl.exec_cmd('dbus-update-activation-environment --systemd ' .. desktop_environment)
    hl.exec_cmd('systemctl --user import-environment ' .. desktop_environment)

    -- Desktop services
    hl.exec_cmd('waybar')
    hl.exec_cmd('mako')

    -- Initial display state
    hl.exec_cmd('brightnessctl set 30%')
    hl.exec_cmd('hyprpaper')

    -- Session services
    hl.exec_cmd('hypridle')
    hl.exec_cmd('systemctl --user start hyprpolkitagent')
    hl.exec_cmd('voxtype')

    -- Clipboard history and persistence after the source window closes
    hl.exec_cmd('wl-clip-persist --clipboard regular')
    hl.exec_cmd('wl-paste --type text --watch ' .. scripts .. 'clipboard_store')
    hl.exec_cmd('wl-paste --type image --watch ' .. scripts .. 'clipboard_store')

    -- Hardware integration
    hl.exec_cmd('udiskie --tray')
    hl.exec_cmd(scripts .. 'battery_monitor')
end)
