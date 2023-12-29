#!/usr/bin/env bash

# Based on:
# - https://forum.manjaro.org/t/rofi-based-application-launcher-menu-with-categories/43113/7
# - https://github.com/Chrysostomus/rofi-scripts/blob/master/bin/rofimenu

font_size="$1"
yoffset="$2"
char_width="$3ch"

THEME="\
    window {
    location: northwest;
    anchor: northwest;
    width: $char_width;
    y-offset: $yoffset;
    x-offset: 0;
}
mainbox {
    children: [ listview ];
}
listview {
    fixed-height: false;
    dynamic: true;
}"

menulist=" About This Arch
 App Launcher  (Super+a)
 Reboot        (Super+Ctrl+r)
⏻ Shut Down     (Super+Ctrl+s)"

# TODO: Highlight option under mouse
# See: https://github.com/DaveDavenport/rofi/issues/600
category=$(echo -e "$menulist" |
    rofi -dmenu \
        -no-custom \
        -select "$category" \
        -font "Noto Sans Mono $font_size" \
        -theme-str "$THEME" |
    awk '{print $2}')

if [ -z "$category" ]; then
    exit
fi

case "$category" in
    App)
        sub_cmd="rofi-font-aware-apps"
        ;;
    Reboot)
        sub_cmd="reboot-dialog"
        ;;
    Shut)
        sub_cmd="poweroff-dialog"
        ;;
    About)
        sub_cmd="about-arch"
        ;;
esac
eval "$HOME"/.config/i3/font_aware_launcher.py "$sub_cmd"

sleep 0.1 # pause to avoid instant menu closing with mouse
exit 0
