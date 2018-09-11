#!/usr/bin/env python3
import sys
import subprocess


def _sh(cmd, *args, **kwargs):
    res, err = _sh_no_block(
        cmd, *args, stdout=subprocess.PIPE, **kwargs
    ).communicate()
    return res


def _sh_no_block(cmd, *args, **kwargs):
    if isinstance(cmd, str):
        cmd = cmd.split()
    return subprocess.Popen(cmd, *args, **kwargs)


def get_vol_and_output_device():
    pactl_out = [
        line.decode('ascii').split()
        for line in _sh('pactl list sinks').splitlines()
    ]
    vol_list = [e for e in pactl_out if 'Volume:' in e[0]][0]
    curr_vol = next(i for i in vol_list if i.endswith('%')).split('%')[0]

    out_list = [e for e in pactl_out
                if 'Active' in e[0] and 'Port:' in e[1]][0]
    device = out_list[-1].split('-')[-1]
    return int(curr_vol), device


def _change_vol(how):
    if how == 'mute':
        cmd = 'pactl set-sink-mute @DEFAULT_SINK@ toggle'
    elif how == 'up':
        cmd = 'pactl set-sink-mute @DEFAULT_SINK@ false'
    elif how == 'down':
        cmd = 'pactl set-sink-volume @DEFAULT_SINK@ -10%'

    _sh(cmd)
    if how == 'up':
        _sh('pactl set-sink-volume @DEFAULT_SINK@ +10%')
    return 0


def _send_notification():
    vol, device = get_vol_and_output_device()
    vol = max(0, min(vol, 100))
    bar = "─" * int(vol / 5)

    not_icon = 'audio-speakers' if device == 'speaker' else 'audio-headphones'
    not_cmd = [
        'dunstify', '-i', not_icon, '-t', '3000', '-r', '1743', '-u', 'normal',
        f'   {bar}  {vol}%'
    ]
    _sh(not_cmd)


def control_volume(how):
    _change_vol(how)
    if how != 'mute':
        _send_notification()
    return 0


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('how')
    args = parser.parse_args()
    how = args.how

    control_volume(how)
    sys.exit(0)
