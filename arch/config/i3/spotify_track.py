#!/usr/bin/env python3
"""Control Spotify with i3."""

import sys
from subprocess import Popen

import gi

if True:
    gi.require_version('Playerctl', '2.0')
    from gi.repository import Playerctl


try:
    player = Playerctl.Player.new('spotify')
except:  # noqa # pylint:disable=bare-except
    try:
        player = Playerctl.Player.new('spotifyd')
    except:  # noqa # pylint:disable=bare-except
        sys.exit(1)
title = player.get_title()
artist = player.get_artist()
album = player.get_album()

status = player.get_property('status')
playing = ''
if status.startswith('Playing'):
    playing = '▶'
elif status.startswith('Paused'):
    playing = '⏸'
elif status.startswith('Stopped'):
    playing = '⏹'

Popen(['dunstify', '-a', 'Spotify', f'{playing} {title}', f'{artist}\n{album}'])
sys.exit(0)
