#!/usr/bin/env python3
import sys
from subprocess import Popen

import gi
from gi.repository import Playerctl

gi.require_version('Playerctl', '1.0')


player = Playerctl.Player()
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
