#!/bin/bash

killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do
    sleep 1;
done
for m in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$m polybar --reload main &
done
