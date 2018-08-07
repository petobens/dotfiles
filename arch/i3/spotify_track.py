#!/usr/bin/env python3
import json

from subprocess import Popen

import gi

gi.require_version('Playerctl', '1.0')

from gi.repository import GLib, Playerctl

player = Playerctl.Player()
title = player.get_title()
artist = player.get_artist()
album = player.get_album()

Popen(
    [
        'dunstify', '-a', 'spotify', title, f'{artist}\n{album}', '-i',
        'Spotify'
    ]
)
