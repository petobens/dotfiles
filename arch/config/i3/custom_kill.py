#!/usr/bin/env python3
"""Custom killing of apps."""
import sys

import i3ipc
from i3_helpers import sh

CTRL_Q = ['Skype', 'Slack']
CUSTOM = ['Chromium']


def kill_custom(i3, which):
    """Kill apps differently according to their class."""
    tree = i3.get_tree()
    if which == 'focused':
        windows = [tree.find_focused()]
    elif which == 'all':
        windows = [win for ws in tree.workspaces() for win in ws.leaves()]

    for win in windows:
        i3.command(f'[con_id={win.id}] focus')
        win_class = win.window_class
        if win_class in CUSTOM:
            if win_class == 'Chromium':
                sh(f'xdotool key --window {win.window} comma+k+v')
        elif win_class in CTRL_Q:
            sh(f'xdotool key --window {win.window} Control+q')
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
