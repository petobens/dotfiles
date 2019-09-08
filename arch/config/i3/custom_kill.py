#!/usr/bin/env python3
"""Custom killing of apps."""
import sys

import i3ipc
from i3_helpers import sh

CTRL_Q = ['Skype', 'Slack']
CUSTOM = ['Chromium', 'Brave-browser']


def _get_windows(i3, which='all'):
    tree = i3.get_tree()
    if which == 'focused':
        windows = [tree.find_focused()]
    elif which == 'all':
        windows = [win for ws in tree.workspaces() for win in ws.leaves()]
    return windows


def kill_custom(i3, which):
    """Kill apps differently according to their class."""
    windows = _get_windows(i3, which)
    for win in windows:
        i3.command(f'[con_id={win.id}] focus')
        win_class = win.window_class
        if win_class in CUSTOM:
            if win_class == 'Chromium' or win_class == 'Brave-browser':
                sh(f'xdotool key --window {win.window} comma+k+v')
                # If the window was not killed using xdotool then do kill it with i3
                remaining_window_classes = [
                    win.window_class for win in _get_windows(i3)
                ]
                if win_class in remaining_window_classes:
                    i3.command('kill')
        elif win_class in CTRL_Q:
            sh(f'xkill -id {win.window}')
        else:
            i3.command('kill')


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--which', '-w', default='focused')
    pars_args = parser.parse_args()

    i3_conn = i3ipc.Connection()
    kill_custom(i3_conn, which=pars_args.which)
    sys.exit(0)
