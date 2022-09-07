#!/usr/bin/env python3
"""Control volume with keyboard."""
import sys

from i3_helpers import sh, sh_no_block


def control_volume(how, level):
    """Control volume level."""
    _change_vol(how, level)
    if how == 'mute':
        # Remove existing notification
        sh('xdotool key Control+Alt+space')
    else:
        _send_notification()
    return 0


def _change_vol(how, level):
    if how == 'mute':
        sh('wpctl set-mute @DEFAULT_SINK@ toggle')
    else:
        vol_cmd = 'wpctl set-volume @DEFAULT_AUDIO_SINK@ {level}%{how}'.format(
            how='+' if how == 'up' else '-', level=level
        )
        sh(vol_cmd)
    return 0


def _send_notification():
    vol, device = _get_vol_and_output_device()
    vol = max(0, min(vol, 100))
    bar = "─" * int(vol / 5)
    not_icon = 'audio-headphones' if 'bluez' in device else 'audio-speakers'
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


def _get_vol_and_output_device():
    curr_vol = sh('wpctl get-volume @DEFAULT_AUDIO_SINK@')
    curr_vol = int(float(curr_vol.decode('ascii').split(':')[-1].strip()) * 100)
    wpctl_out = [
        line.decode('ascii').split()
        for line in sh('wpctl inspect @DEFAULT_AUDIO_SINK@').splitlines()
    ]
    device = [e for e in wpctl_out if 'device.api' in e][0][-1].split('"')[1]
    return curr_vol, device


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--direction', '-d', required=True)
    parser.add_argument('--level', '-l', type=int, default=10)
    args = parser.parse_args()

    control_volume(args.direction, args.level)
    sys.exit(0)
