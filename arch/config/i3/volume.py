#!/usr/bin/env python3
"""Control volume with keyboard."""
import sys

from i3_helpers import sh, sh_no_block


def control_volume(how, level):
    """Control volume level."""
    _change_vol(how, level)
    if how == 'mute':
        # Remove existing notification
        sh('xdotool key Control+space')
    else:
        _send_notification()
    return 0


def _change_vol(how, level):
    mute_cmd = 'pactl set-sink-mute @DEFAULT_SINK@ '
    if how == 'mute':
        mute_cmd += 'toggle'
    else:
        mute_cmd += 'false'
    sh(mute_cmd)

    if how != 'mute':
        vol_cmd = 'pactl set-sink-volume @DEFAULT_SINK@ {how}{level}%'.format(
            how='+' if how == 'up' else '-', level=level
        )
        sh(vol_cmd)
    return 0


def _send_notification():
    vol, device = _get_vol_and_output_device()
    vol = max(0, min(vol, 100))
    bar = "─" * int(vol / 5)

    not_icon = 'audio-speakers' if device == 'speaker' else 'audio-headphones'
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
    pactl_out = [
        line.decode('ascii').split() for line in sh('pactl list sinks').splitlines()
    ]
    vol_list = [e for e in pactl_out if 'Volume:' in e[0]][0]
    curr_vol = next(i for i in vol_list if i.endswith('%')).split('%')[0]

    out_list = [e for e in pactl_out if 'Active' in e[0] and 'Port:' in e[1]][0]
    device = out_list[-1].split('-')[-1]
    return int(curr_vol), device


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--direction', '-d', required=True)
    parser.add_argument('--level', '-l', type=int, default=10)
    args = parser.parse_args()

    control_volume(args.direction, args.level)
    sys.exit(0)
