#!/usr/bin/env python3
import sys

from time import sleep

import i3ipc

from resize import LAYOUT_DICT
from multimon_move import _get_resize_map


def adjust(i3, how, orient, size=30):
    layout = _get_layout(i3)

    for win_id, win_data in layout.items():
        if not win_data['focused']:
            continue
        focused_win_id = win_id
        focused_layout = win_data['layout']
        _grow_or_shrink(i3, how, orient, size)
        break

    if focused_layout in ('Full', 'Center', 'Rectangle',
                          'Semi Full') or len(layout) == 1:
        # These are pure floating windows (or unique one) so we don't make any
        # adjustments to other windows
        return

    # Now adjust adjacent windows sizes if needed
    adjustable_layouts = _get_adjustable_layouts(focused_layout, how, orient)
    for win_id, win_data in layout.items():
        if win_data['focused']:
            continue
        unfocused_layout = win_data['layout']
        if unfocused_layout in adjustable_layouts:
            i3.command(f'[con_id={win_id}] focus')
            while not i3.get_tree().find_focused().id == win_id:
                sleep(0.1)
            how, orient = adjustable_layouts[unfocused_layout]
            _grow_or_shrink(i3, how, orient, size)

    # Return focus to original windows
    i3.command(f'[con_id={focused_win_id}] focus')
    return


def _get_layout(i3):
    rmap = _get_resize_map(i3)
    for win_id, win_data in rmap.items():
        actual_layout = [round(float(i), 2) for i in win_data['how']]
        min_distance = 1e10
        for name, vals in LAYOUT_DICT.items():
            known_layout = [round(float(i), 2) for i in vals]
            curr_distance = round(
                sum([abs(i - j) for i, j in zip(actual_layout, known_layout)]),
                2
            )

            if curr_distance == 0:
                win_data['layout'] = name
                break

            # If there is no exact match then assume it's the closest one (i.e
            # shortest distance) to a known layout
            if curr_distance < min_distance:
                win_data['layout'] = name
                min_distance = curr_distance
    return rmap


def _grow_or_shrink(i3, how, orient, size):
    # Note: px are used for floating windows (ppt for tiling)
    cmd = f'resize {how} {orient} {size} px'
    i3.command(cmd)
    return


def _get_adjustable_layouts(focused_layout, how, orient):
    if 'Left' in focused_layout:
        focused_position = 'Left'
    elif 'Right' in focused_layout:
        focused_position = 'Right'
    elif focused_layout == 'Top':
        focused_position = 'Top'
    elif focused_layout == 'Bottom':
        focused_position = 'Bottom'

    adjustable_layouts = {}

    if focused_position == 'Left':
        if how == 'grow' and orient == 'right':
            adjustable_layouts['Right'] = ('shrink', 'left')
            adjustable_layouts['Top Right'] = ('shrink', 'left')
            adjustable_layouts['Bottom Right'] = ('shrink', 'left')
            adjustable_layouts['Top Left'] = ('grow', 'right')
            adjustable_layouts['Bottom Left'] = ('grow', 'right')
        if how == 'shrink' and orient == 'right':
            adjustable_layouts['Right'] = ('grow', 'left')
            adjustable_layouts['Top Right'] = ('grow', 'left')
            adjustable_layouts['Bottom Right'] = ('grow', 'left')
            adjustable_layouts['Top Left'] = ('shrink', 'right')
            adjustable_layouts['Bottom Left'] = ('shrink', 'right')
        if how == 'grow' and orient == 'down':
            adjustable_layouts['Top Right'] = ('grow', 'down')
            adjustable_layouts['Bottom'] = ('shrink', 'up')
            adjustable_layouts['Bottom Left'] = ('shrink', 'up')
            adjustable_layouts['Bottom Right'] = ('shrink', 'up')
        if how == 'shrink' and orient == 'down':
            adjustable_layouts['Top Right'] = ('shrink', 'down')
            adjustable_layouts['Bottom'] = ('grow', 'up')
            adjustable_layouts['Bottom Left'] = ('grow', 'up')
            adjustable_layouts['Bottom Right'] = ('grow', 'up')
        if how == 'grow' and orient == 'up':
            adjustable_layouts['Bottom Right'] = ('grow', 'up')
            adjustable_layouts['Top'] = ('shrink', 'down')
            adjustable_layouts['Top Left'] = ('shrink', 'down')
            adjustable_layouts['Top Right'] = ('shrink', 'down')
        if how == 'shrink' and orient == 'up':
            adjustable_layouts['Bottom Right'] = ('shrink', 'up')
            adjustable_layouts['Top'] = ('grow', 'down')
            adjustable_layouts['Top Left'] = ('grow', 'down')
            adjustable_layouts['Top Right'] = ('grow', 'down')

    if focused_position == 'Right':
        if how == 'grow' and orient == 'left':
            adjustable_layouts['Left'] = ('shrink', 'right')
            adjustable_layouts['Top Left'] = ('shrink', 'right')
            adjustable_layouts['Bottom Left'] = ('shrink', 'right')
            adjustable_layouts['Top Right'] = ('grow', 'left')
            adjustable_layouts['Bottom Right'] = ('grow', 'left')
        if how == 'shrink' and orient == 'left':
            adjustable_layouts['Left'] = ('grow', 'right')
            adjustable_layouts['Top Left'] = ('grow', 'right')
            adjustable_layouts['Bottom Left'] = ('grow', 'right')
            adjustable_layouts['Top Right'] = ('shrink', 'left')
            adjustable_layouts['Bottom Right'] = ('shrink', 'left')
        if how == 'grow' and orient == 'down':
            adjustable_layouts['Top Left'] = ('grow', 'down')
            adjustable_layouts['Bottom'] = ('shrink', 'up')
            adjustable_layouts['Bottom Left'] = ('shrink', 'up')
            adjustable_layouts['Bottom Right'] = ('shrink', 'up')
        if how == 'shrink' and orient == 'down':
            adjustable_layouts['Top Left'] = ('shrink', 'down')
            adjustable_layouts['Bottom'] = ('grow', 'up')
            adjustable_layouts['Bottom Left'] = ('grow', 'up')
            adjustable_layouts['Bottom Right'] = ('grow', 'up')
        if how == 'grow' and orient == 'up':
            adjustable_layouts['Bottom Left'] = ('grow', 'up')
            adjustable_layouts['Top'] = ('shrink', 'down')
            adjustable_layouts['Top Left'] = ('shrink', 'down')
            adjustable_layouts['Top Right'] = ('shrink', 'down')
        if how == 'shrink' and orient == 'up':
            adjustable_layouts['Bottom Left'] = ('shrink', 'up')
            adjustable_layouts['Top'] = ('grow', 'down')
            adjustable_layouts['Top Left'] = ('grown', 'down')
            adjustable_layouts['Top Right'] = ('grown', 'down')

    if focused_position == 'Top':
        if how == 'grow' and orient == 'down':
            adjustable_layouts['Bottom'] = ('shrink', 'up')
            adjustable_layouts['Bottom Left'] = ('shrink', 'up')
            adjustable_layouts['Bottom Right'] = ('shrink', 'up')
        if how == 'shrink' and orient == 'down':
            adjustable_layouts['Bottom'] = ('grow', 'up')
            adjustable_layouts['Bottom Left'] = ('grow', 'up')
            adjustable_layouts['Bottom Right'] = ('grow', 'up')

    if focused_position == 'Bottom':
        if how == 'grow' and orient == 'up':
            adjustable_layouts['Top'] = ('shrink', 'down')
            adjustable_layouts['Top Left'] = ('shrink', 'down')
            adjustable_layouts['Top Right'] = ('shrink', 'down')
        if how == 'shrink' and orient == 'up':
            adjustable_layouts['Top'] = ('grow', 'down')
            adjustable_layouts['Top Left'] = ('grow', 'down')
            adjustable_layouts['Top Right'] = ('grow', 'down')

    return adjustable_layouts


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--action', '-a')
    parser.add_argument('--orient', '-o')
    parser.add_argument('--size', '-s', type=int, default=30)
    args = parser.parse_args()

    i3 = i3ipc.Connection()
    adjust(i3, args.action, args.orient, args.size)
    sys.exit(0)
