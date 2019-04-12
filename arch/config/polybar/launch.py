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
    xrandr = [line.decode('ascii').split() for line in _sh('xrandr').splitlines()]
    for line in xrandr:
        if 'connected' in line:
            monitor = line[0]
            env = os.environ.copy()
            env['MONITOR'] = monitor
            # Hack to avoid i3 workspaces are not shown on polybar when using mirroring
            # See: https://github.com/jaagr/polybar/issues/1191
            env['POLYBAR_I3_PIN'] = 'false' if monitors == 'mirror' else 'true'
            if monitors == 'xrandr':
                env['TRAY_POS'] = 'right' if 'primary' in line else ''
            elif monitors == 'mirror':
                env['TRAY_POS'] = 'right'

            _sh_no_block('polybar --reload main', env=env)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--monitors', '-m', nargs='?', default='xrandr')
    parse_args = parser.parse_args()

    launch_polybar(parse_args.monitors)
    sys.exit(0)
