#!/bin/sh

B='#24272EFF'  # inside color
T='#ABB2BFFF'  # text
W='#E06C75FF'  # wrong
K='#528BFFFF'  # key press

i3lock \
    --insidevercolor=$B      \
    --ringvercolor=$K        \
    --verifcolor=$K          \
    --veriftext="Validating" \
    \
    --insidewrongcolor=$B    \
    --ringwrongcolor=$W      \
    --wrongcolor=$W          \
    --wrongtext="Try again"  \
    \
    --insidecolor=$B         \
    --ringcolor=$B           \
    --linecolor=$B           \
    \
    --timecolor=$T           \
    --datecolor=$T           \
    --keyhlcolor=$K          \
    --bshlcolor=$K           \
    \
    --blur 15                \
    --clock                  \
    --timestr="%H:%M:%S"     \
    --datestr="%a %b %d"     \
    --ring-width=3.0         \

