#!/usr/bin/env python3
import sys

from time import sleep

import i3ipc

from resize import resize_win


def move_and_resize(i3, direction=None, move_win=True, workspace=None):
    resize_map = _get_resize_map(i3)

    if direction is not None:
        if move_win:
            cmd = f'move container to output {direction}, ' \
                  f'focus output {direction}'
        else:
            cmd = f'move workspace to output {direction}'
    if workspace is not None:
        cmd = f'move container to workspace {workspace}, workspace {workspace}'
    i3.command(cmd)

    for win_id, win_data in resize_map.items():
        if cmd.startswith('move container'):
            if not win_data['focused']:
                continue
        else:
            i3.command(f'[con_id={win_id}] focus')
            while not i3.get_tree().find_focused().id == win_id:
                sleep(0.1)
        x, y, w, h = win_data['how']
        resize_win(i3, x, y, w, h)


def _get_resize_map(i3):
    res_map = {}
    tree = i3.get_tree()
    focused_win = tree.find_focused()
    ws = focused_win.workspace()
    for w in ws.leaves():
        res_map[w.id] = {
            'win': w,
            'focused': w.focused,
            'how': _find_how_to_resize(i3, w),
        }
    return res_map


def _find_how_to_resize(i3, win=None):
    if win is None:
        win = i3.get_tree().find_focused()
    win_h = win.rect.height
    win_w = win.rect.width
    win_x = win.rect.x
    win_y = win.rect.y

    ws = win.workspace()
    max_h = ws.rect.height
    max_w = ws.rect.width
    max_x = ws.rect.x
    max_y = ws.rect.y

    w = round(win_w / max_w, 2)
    h = round(win_h / max_h, 2)
    x = round((win_x + 1 - max_x) / max_w, 2)
    if x > 1:
        # If win_x is wrongly reported then the factor will > 1; in these
        # cases the actual x value should be 0
        x = 0
    y = round((win_y - max_y) / max_h, 2)

    return x, y, w, h


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--direction', '-d')
    parser.add_argument('--move-win', dest='move_win', action='store_true')
    parser.add_argument('--move-ws', dest='move_win', action='store_false')
    parser.set_defaults(move_win=True)
    parser.add_argument('--workspace', '-w')
    args = parser.parse_args()

    i3 = i3ipc.Connection()
    move_and_resize(
        i3,
        direction=args.direction,
        move_win=args.move_win,
        workspace=args.workspace
    )
    sys.exit(0)
