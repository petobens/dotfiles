#!/usr/bin/env python3
import os
import subprocess

from time import sleep


def sh_no_block(cmd, *args, **kwargs):
    if isinstance(cmd, str):
        cmd = cmd.split()
    return subprocess.Popen(cmd, *args, **kwargs)


def sh(cmd, *args, **kwargs):
    res, err = sh_no_block(
        cmd, *args, stdout=subprocess.PIPE, **kwargs
    ).communicate()
    return res


# Terminate already running bar instances
sh('killall -q polybar')

# Wait until the processes have been shut down
while sh(f'pgrep -u {os.getuid()} -x polybar'):
    sleep(0.2)

# Launch the main bar in each monitor but try to set the systray always in
# primary one (overrides polybar's first come first serve rule. See:
# https://github.com/jaagr/polybar/issues/1070)
xrandr = [line.decode('ascii').split() for line in sh('xrandr').splitlines()]
for line in xrandr:
    if 'connected' in line:
        monitor = line[0]
        try:
            env = os.environ.copy()
            env['MONITOR'] = monitor
            env['TRAY_POS'] = 'right' if 'primary' in line else ''
            sh_no_block('polybar --reload main', env=env)
        except Exception as e:
            env = os.environ.copy()
            env['MONITOR'] = monitor
            sh_no_block('polybar --reload main', env=env)
