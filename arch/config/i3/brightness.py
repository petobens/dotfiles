#!/usr/bin/env python3
"""Control brightness with keyboard."""
import sys
from pathlib import Path

from i3_helpers import sh, sh_no_block

BRIGHTNESS_DIR = Path('/sys/class/backlight/intel_backlight')
if not BRIGHTNESS_DIR.is_dir():
    raise FileNotFoundError("Missing brightness directory!")


def control_brightness(how, level):
    """Control brightness level."""
    _change_brightness(how, level)
    _send_notification()
    return 0


def _change_brightness(how, level):
    cmd = f'xbacklight -{how} {level}'
    sh(cmd)


def _send_notification():
    brightness = _get_brightness()
    max_brightness = _get_brightness(maximum=True)
    bright_perc = int((brightness / max_brightness) * 100)
    bar = '─' * int(bright_perc / 5)

    not_cmd = [
        'dunstify',
        '-i',
        'display-brightness',
        '-t',
        '2000',
        '-r',
        '1753',
        '-u',
        'normal',
        f'   {bar}  {bright_perc}%',
    ]
    sh_no_block(not_cmd)


def _get_brightness(maximum=False):
    basename = '{}brightness'.format('' if not maximum else 'max_')
    brightness_file = BRIGHTNESS_DIR / basename
    with brightness_file.open() as f:
        brightness = f.read()
    return int(brightness)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--direction', '-d', required=True)
    parser.add_argument('--level', '-l', type=int, default=5)
    args = parser.parse_args()

    control_brightness(args.direction, args.level)
    sys.exit(0)
