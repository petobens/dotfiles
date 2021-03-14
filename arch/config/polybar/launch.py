#!/usr/bin/env python3
"""Launch Polybar in multiple monitors."""
import os
import subprocess
import sys
from time import sleep


def _sh_no_block(cmd, *args, **kwargs):
    if isinstance(cmd, str):
        cmd = cmd.split()
    return subprocess.Popen(cmd, *args, **kwargs)


def _sh(cmd, *args, **kwargs):
    res, _ = _sh_no_block(cmd, *args, stdout=subprocess.PIPE, **kwargs).communicate()
    return res


def launch_polybar(monitors):
    """Launch polybar taking into account monitor setup."""
    # Terminate already running bar instances
    _sh('killall -q polybar')

    # Wait until the processes have been shut down
    while _sh(f'pgrep -u {os.getuid()} -x polybar'):
        sleep(0.2)

    # Launch the main bar in each monitor but try to set the systray always in
    # primary one (overrides polybar's first come first serve rule. See:
    # https://github.com/jaagr/polybar/issues/1070)
    active_monitors = [
        line.decode('ascii').split()
        for line in _sh('xrandr --listactivemonitors').splitlines()
    ]
    nr_monitors = int(active_monitors[0][-1])
    prim_w = int(active_monitors[1][2].split('/')[0])
    all_hidpi = prim_w > HD_WIDTH
    if nr_monitors > 1:
        sec_w = int(active_monitors[2][2].split('/')[0])
        all_hidpi = all_hidpi and sec_w > HD_WIDTH
        if nr_monitors > 2:
            third_w = int(active_monitors[3][2].split('/')[0])
            all_hidpi = all_hidpi and third_w > HD_WIDTH

    xrandr = [line.decode('ascii').split() for line in _sh('xrandr').splitlines()]
    for line in xrandr:
        if 'connected' in line:
            if monitors == 'mirror' and 'primary' not in line:
                # When mirroring it's enough to show the bar on the primary monitor
                continue
            monitor = line[0]
            width_index = 3 if 'primary' in line else 2
            try:
                width = int(line[width_index].split('x')[0])
            except ValueError:
                # If there is no resolution info then the monitor is connected but inactive
                continue
            env = os.environ.copy()
            env['MONITOR'] = monitor
            env['POLYHEIGHT'] = '55' if (width > HD_WIDTH) else '28'
            env['TRAY_SIZE'] = '32' if (width > HD_WIDTH) else '20'
            # If we have a mix of hd and hidpi monitors then we need to scale
            fontmap_index = 1
            if width > HD_WIDTH and not all_hidpi:
                fontmap_index = 2
            for i in range(7):
                env[f'POLYFONT{i}'] = FONT_MAP[i][0].format(*FONT_MAP[i][fontmap_index])
            env['TRAY_POS'] = 'right' if 'primary' in line else ''

            _sh_no_block('polybar --reload main', env=env)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--monitors', '-m', nargs='?', default='xrandr')
    parse_args = parser.parse_args()

    HD_WIDTH = 1920
    FONT_MAP = {
        0: ('Noto Sans:size={};3', ['11'], ['21']),
        1: ('Noto Sans:size={}:weight=bold;2', ['11'], ['21']),
        2: ('Noto Sans Mono:size={}:weight=bold;2', ['10'], ['20']),
        3: ('Symbols Nerd Font:size={};4', ['13'], ['26']),
        4: ('Symbols Nerd Font:size={};4', ['14'], ['28']),
        5: ('Symbols Nerd Font:size={};4', ['12'], ['24']),
        6: ('Noto Sans:size={}:weight=bold;{}', ['7', '-5'], ['14', '-10']),
    }

    launch_polybar(parse_args.monitors)
    sys.exit(0)
