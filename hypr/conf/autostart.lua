-- luacheck: globals hl

hl.on('hyprland.start', function()
    -- Export the session before starting services that use desktop portals
    hl.exec_cmd(
        'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'
    )
    hl.exec_cmd('systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP')
    hl.exec_cmd('waybar')
    hl.exec_cmd('mako')
    hl.exec_cmd('brightnessctl set 30%')
    hl.exec_cmd([[sh -c '[ -f "$HOME/Pictures/wallpaper.png" ] && hyprpaper']])
    hl.exec_cmd('hypridle')
    hl.exec_cmd('systemctl --user start hyprpolkitagent')
    hl.exec_cmd('systemctl --user start gnome-keyring-daemon.socket')
    hl.exec_cmd('blueman-applet')
    -- Mount removable drives and expose them through a tray icon
    hl.exec_cmd('udiskie --tray')
end)
