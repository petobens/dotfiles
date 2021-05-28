#!/bin/bash

# Pre lock (pause music and notifications)
if [ "$1" != 'suspend' ]; then
    SPOTIFY_STATUS=$(playerctl -p spotify,spotifyd status)
    if [[ $SPOTIFY_STATUS == "Playing" ]]; then
        playerctl -p spotify,spotifyd pause
    fi
    killall -SIGUSR1 dunst
fi

# Actual locking (use `--blur 15` instead of the `c` option to blur images;
# note however that it is terrible slow)
B='24272EFF' # inside color
T='ABB2BFFF' # text
W='E06C75FF' # wrong
K='528BFFFF' # key press
i3lock \
    --insidever-color=$B \
    --ringver-color=$K \
    --verif-color=$K \
    --verif-text="Validating" \
    --lock-text="Locking" \
    --lockfailed-text="Lock failed!" \
    \
    --insidewrong-color=$B \
    --ringwrong-color=$W \
    --wrong-color=$W \
    --wrong-text="Wrong!" \
    --noinput-text="No input!" \
    \
    --inside-color=$B \
    --ring-color=$B \
    --line-color=$B \
    \
    --time-color=$T \
    --date-color=$T \
    --keyhl-color=$K \
    --bshl-color=$K \
    \
    --clock \
    --time-str="%H:%M:%S" \
    --date-str="%a %b %d" \
    --ring-width=3.0 \
    --radius=100 \
    \
    --color="24272eff" \
    --nofork

# Post lock
if [ "$1" != 'suspend' ]; then
    if [[ $SPOTIFY_STATUS == "Playing" ]]; then
        playerctl -p spotify,spotifyd play
    fi
    killall -SIGUSR2 dunst
fi
