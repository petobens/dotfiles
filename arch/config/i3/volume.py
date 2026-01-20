#!/usr/bin/env python3
"""Control volume with keyboard."""

import re
import sys

from i3_helpers import sh, sh_no_block


def control_volume(how: str, level: int) -> int:
    """Control volume level."""
    _change_vol(how, level)
    if how == 'mute':
        # Remove existing notification
        sh('xdotool key Control+Alt+space')
    else:
        _send_notification()
    return 0


def _change_vol(how: str, level: int) -> int:
    mute_cmd = 'wpctl set-mute @DEFAULT_SINK@ {}'.format(
        'toggle' if how == 'mute' else 0
    )
    vol_cmd = 'wpctl set-volume @DEFAULT_AUDIO_SINK@ {level}%{how}'.format(
        how='+' if how == 'up' else '-', level=level
    )
    sh(mute_cmd)
    sh(vol_cmd)
    return 0


def _send_notification() -> None:
    vol, device = _get_vol_and_output_device()
    vol = max(0, min(vol, 100))
    bar = '─' * int(vol / 5)
    device_lc = device.lower()
    not_icon = (
        'audio-headphones'
        if any(k in device_lc for k in ('bluez', 'headphone', 'headset'))
        else 'audio-speakers'
    )
    not_cmd = [
        'dunstify',
        '-i',
        not_icon,
        '-t',
        '2000',
        '-r',
        '1743',
        '-u',
        'normal',
        f'   {bar}  {vol}%',
    ]
    sh_no_block(not_cmd)


def _get_vol_and_output_device() -> tuple[int, str]:
    curr_vol = sh('wpctl get-volume @DEFAULT_AUDIO_SINK@')
    curr_vol = int(
        float(curr_vol.decode('utf-8', errors='replace').split(':')[-1].strip()) * 100
    )
    wpctl_out = [
        line.decode('utf-8', errors='replace').split()
        for line in sh('wpctl inspect @DEFAULT_AUDIO_SINK@').splitlines()
    ]
    device_line = next((e for e in wpctl_out if 'node.name' in e), None)
    if device_line is None:
        device_line = next((e for e in wpctl_out if 'device.api' in e), None)
    if not device_line:
        return curr_vol, ''
    m = re.search(r'"([^"]+)"', " ".join(device_line))
    first_quoted = m.group(1) if m else ''
    return curr_vol, first_quoted


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--direction', '-d', required=True)
    parser.add_argument('--level', '-l', type=int, default=10)
    args = parser.parse_args()

    control_volume(args.direction, args.level)
    sys.exit(0)
