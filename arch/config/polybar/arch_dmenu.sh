#!/usr/bin/env bash

# Based on:
# - https://forum.manjaro.org/t/rofi-based-application-launcher-menu-with-categories/43113/7
# - https://github.com/Chrysostomus/rofi-scripts/blob/master/bin/rofimenu

THEME="\
    window {
    location: northwest;
    anchor: northwest;
    width: 34ch;
    y-offset: $2;
    x-offset: 0;
}
mainbox {
    children: [ listview ];
}
listview {
    fixed-height: false;
    dynamic: true;
}"

menulist=" About This Arch
 App Launcher  (Super+s)
 Reboot        (Super+Ctrl+r)
襤 Shut Down     (Super+Ctrl+s)"

# TODO: Highlight option under mouse
# See: https://github.com/DaveDavenport/rofi/issues/600
category=$(echo -e "$menulist" |
    rofi -dmenu \
        -no-custom \
        -select "$category" \
        -font "Noto Sans Mono $1" \
        -theme-str "$THEME" |
    awk '{print $2}')

if [ -z "$category" ]; then
    exit
fi

case "$category" in
    App)
        sub_cmd="rofi apps"
        ;;
    Reboot)
        sub_cmd="gtk_dialog reboot"
        ;;
    Shut)
        sub_cmd="gtk_dialog poweroof"
        ;;
    About)
        sub_cmd="alacritty about-arch"
        ;;
esac
eval "$HOME"/.config/i3/font_aware_launcher.py "$sub_cmd"

sleep 0.1 # pause to avoid instant menu closing with mouse
exit 0
