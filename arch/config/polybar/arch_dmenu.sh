#!/usr/bin/env bash

# Based on:
# - https://forum.manjaro.org/t/rofi-based-application-launcher-menu-with-categories/43113/7
# - https://github.com/Chrysostomus/rofi-scripts/blob/master/bin/rofimenu
# TODO: Fix padding
# TODO: Fix launcher not launching

THEME="\
    window {
    location: northwest;
    anchor: northwest;
    y-offset: 1em;
    width: 18ch;
    x-offset: 0;
}
mainbox {
    children: [ listview ];
}
listview {
    fixed-height: false;
    dynamic: true;
    padding: 0px 0px 0px;
}"

menulist=" Launcher
 Reboot
襤 Shutdown
 About"

category=$(echo -e "$menulist" | \
        rofi -dmenu \
        -no-custom \
        -select "$category" \
        -font "Noto Sans Mono 11" \
        -theme-str "$THEME" \
    | awk '{print $2}')

if [ -z "$category" ] ; then
    exit
fi

if [ "$category" = "Launcher" ] ; then
    rofi -combi-modi drun,run -show combi
elif [ "$category" = "Reboot" ] ; then
    xdotool key Super_L+Shift+r
elif [ "$category" = "Shutdown" ] ; then
    xdotool key Super_L+Shift+s
elif [ "$category" = "About" ] ; then
    WINIT_HIDPI_FACTOR=2.66 alacritty -t "About Arch" -e /usr/bin/bash -i -c "neofetch;bash"
fi

sleep 0.1 # pause to avoid instant menu closing with mouse
exit 0
