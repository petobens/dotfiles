#!/bin/bash

# Add `monitor primary` if we want to show always in the same monitor
rofi \
    -show window  \
    -no-fixed-num-lines \
    -kb-accept-entry "!Alt-Tab,Return"\
    -kb-row-down "Alt+Tab,Ctrl-n" \
    -kb-row-up "Shift_L+Left_Tab,Ctrl-p"&
xdotool keyup Tab
xdotool keydown Tab
