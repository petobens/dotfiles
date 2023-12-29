#!/bin/bash

bl_file="/sys/class/leds/tpacpi::kbd_backlight/brightness"
current_level="$(cat $bl_file)"
case "$current_level" in
    0)
        new_level=1
        ;;
    1)
        new_level=2
        ;;
    2)
        new_level=0
        ;;
    **)
        true
        ;;
esac
echo $new_level > $bl_file
dunstify -i cs-keyboard 'Keyboard Backlight Change' "New Level: $new_level"
