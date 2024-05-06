#!/usr/bin/env python3
"""Resize windows easily."""

import sys

import i3ipc

LAYOUT_DICT = {
    'Full': (0, 0, 1, 1),
    'Left': (0, 0, 0.5, 1),
    'Right': (0.5, 0, 0.5, 1),
    'Top': (0, 0, 1, 0.5),
    'Bottom': (0, 0.5, 1, 0.5),
    'Top Left': (0, 0, 0.5, 0.5),
    'Top Right': (0.5, 0, 0.5, 0.5),
    'Bottom Left': (0, 0.5, 0.5, 0.5),
    'Bottom Right': (0.5, 0.5, 0.5, 0.5),
    'Center': (0.25, 0.25, 0.5, 0.5),
    'Rectangle': (0.125, 0.2, 0.75, 0.6),
    'Dialog': (0.33, 0.3, 0.35, 0.25),
    # This is hack to resize windows in screens that can't correctly parse window sizes
    'Semi Full': (0.01, 0, 0.985, 0.99),
}


def resize_win(i3, x, y, w, h):
    """Resize focused window."""
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
    cmd = (
        f"fullscreen disable, floating enable, "
        f"move position {x} {y}, resize set {w} {h}"
    )
    i3.command(cmd)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('how')
    args = parser.parse_args()
    how = args.how

    i3_conn = i3ipc.Connection()
    resize_win(i3_conn, *LAYOUT_DICT[how])
    sys.exit(0)
