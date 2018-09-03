#!/usr/bin/env python3
import sys

import i3ipc


def resize_win(x, y, w, h):
    win = i3.get_tree().find_focused()
    ws = win.workspace()
    max_h = ws.rect.height
    max_w = ws.rect.width
    max_x = ws.rect.x
    max_y = ws.rect.y

    x = int(max_x + (max_w * x))
    # Fix for incorrect calculation when monitor extends right
    # TODO: Find a better way of doing this
    x -= 1
    y = int(max_y + (max_h * y))
    w = int(max_w * w)
    h = int(max_h * h)
    cmd = f"fullscreen disable, floating enable, " \
          f"move position {x} {y}, resize set {w} {h}"
    i3.command(cmd)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('how')
    args = parser.parse_args()
    how = args.how

    i3 = i3ipc.Connection()
    if how == 'Full':
        resize_win(0, 0, 1, 1)
    elif how == 'Left':
        resize_win(0, 0, 0.5, 1)
    elif how == 'Right':
        resize_win(0.5, 0, 0.5, 1)
    elif how == 'Top':
        resize_win(0, 0, 1, 0.5)
    elif how == 'Bottom':
        resize_win(0, 0.5, 1, 0.5)
    elif how == 'Top Left':
        resize_win(0, 0, 0.5, 0.5)
    elif how == 'Top Right':
        resize_win(0.5, 0, 0.5, 0.5)
    elif how == 'Bottom Left':
        resize_win(0, 0.5, 0.5, 0.5)
    elif how == 'Bottom Right':
        resize_win(0.5, 0.5, 0.5, 0.5)
    elif how == 'Center':
        resize_win(0.25, 0.25, 0.5, 0.5)
    elif how == 'Rectangle':
        resize_win(0.15, 0.15, 0.75, 0.6)
    sys.exit(0)
