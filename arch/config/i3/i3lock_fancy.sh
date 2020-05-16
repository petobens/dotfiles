#!/bin/bash

# Pre lock (pause music and notifications)
if [ "$1" != 'suspend' ]; then
    SPOTIFY_STATUS=$(playerctl -p spotify status)
    if [[ $SPOTIFY_STATUS == "Playing" ]]; then
        playerctl -p spotify pause
    fi
    killall -SIGUSR1 dunst
fi

# Actual locking (use `--blur 15` instead of the `c` option to blur images;
# note however that it is terrible slow)
B='24272EFF'  # inside color
T='ABB2BFFF'  # text
W='E06C75FF'  # wrong
K='528BFFFF'  # key press
i3lock \
    --insidevercolor=$B              \
    --ringvercolor=$K                \
    --verifcolor=$K                  \
    --veriftext="Validating"         \
    --locktext="Locking"             \
    --lockfailedtext="Lock failed!"  \
    \
    --insidewrongcolor=$B            \
    --ringwrongcolor=$W              \
    --wrongcolor=$W                  \
    --wrongtext="Wrong!"             \
    --noinputtext="No input!"        \
    \
    --insidecolor=$B                 \
    --ringcolor=$B                   \
    --linecolor=$B                   \
    \
    --timecolor=$T                   \
    --datecolor=$T                   \
    --keyhlcolor=$K                  \
    --bshlcolor=$K                   \
    \
    --clock                          \
    --timestr="%H:%M:%S"             \
    --datestr="%a %b %d"             \
    --ring-width=3.0                 \
    --radius=100                     \
    \
    --color="24272eff"               \
    --nofork


# Post lock
if [ "$1" != 'suspend' ]; then
    if [[ $SPOTIFY_STATUS == "Playing" ]]; then
        playerctl -p spotify play
    fi
    killall -SIGUSR2 dunst
fi
