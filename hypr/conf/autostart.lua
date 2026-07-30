-- luacheck: globals hl

local desktop_environment = 'WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'

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

    -- Hardware integration
    hl.exec_cmd('blueman-applet')
    hl.exec_cmd('udiskie --tray')
end)
