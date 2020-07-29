#!/usr/bin/env python3
"""Move containers and workspaces between monitors (i.e outputs)."""

import sys
from time import sleep

import i3ipc

from i3_helpers import sh
from resize import resize_win


def move_and_resize(i3, direction=None, move_win=True, workspace=None):
    """Move windows and container between monitors resizing/rescaling appropiately."""
    resize_map = _get_resize_map(i3)

    cmd = 'fullscreen disable, '
    if direction is not None:
        cmd += (
            f'move {"container" if move_win else "workspace"} to '
            f'output {direction}, focus output {direction}'
        )
    if workspace is not None:
        cmd += f'move container to workspace {workspace}, workspace {workspace}'
    i3.command(cmd)
    sleep(0.2)

    new_output_width, _ = get_output_width(i3)

    for win_id, win_data in resize_map.items():
        if cmd.startswith('move container'):
            if not win_data['focused']:
                continue
        else:
            i3.command(f'[con_id={win_id}] focus')
            while not i3.get_tree().find_focused().id == win_id:
                sleep(0.1)

        is_fullscreen = True if win_data['fullscreen'] == 1 else False
        if is_fullscreen:
            i3.command('fullscreen enable')
        else:
            x, y, w, h = win_data['how']
            resize_win(i3, x, y, w, h)

        new_output_width, _ = get_output_width(i3)
        win_output_width = win_data['output_width']
        win_class = win_data['class']
        if (win_output_width != new_output_width) and (
            win_class in ('kitty', 'Alacritty', 'Brave-browser', 'firefox')
        ):
            # Note: firefox meta key not working
            zoom_dir = 'u' if new_output_width > win_output_width else 'd'
            sh(f'xdotool key Super+{zoom_dir}')
    return


def _get_resize_map(i3):
    res_map = {}
    ws = i3.get_tree().find_focused().workspace()
    output_width, _ = get_output_width(i3, ws)
    for w in ws.leaves():
        res_map[w.id] = {
            'win': w,
            'focused': w.focused,
            'how': _find_how_to_resize(i3, w),
            'fullscreen': w.fullscreen_mode,
            'class': w.window_class,
            'output_width': output_width,
        }
    return res_map


def get_output_width(i3, ws=None):
    """Get current workspace output width (and list of outputs)."""
    if ws is None:
        ws = i3.get_tree().find_focused().workspace()
    outputs = [i for i in i3.get_outputs() if i.active]
    current_output_width = next(
        o.rect.width for o in outputs if o.name == ws.ipc_data['output']
    )
    return current_output_width, outputs


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

    i3_conn = i3ipc.Connection()
    move_and_resize(
        i3_conn,
        direction=args.direction,
        move_win=args.move_win,
        workspace=args.workspace,
    )
    sys.exit(0)
