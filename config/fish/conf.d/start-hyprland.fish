# Start the graphical session only from the primary login console
if status is-login; and test (tty) = /dev/tty1; and test -z "$WAYLAND_DISPLAY"
    exec start-hyprland
end
