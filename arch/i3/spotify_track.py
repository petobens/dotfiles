#!/usr/bin/env python3
from subprocess import Popen

import gi

gi.require_version('Playerctl', '1.0')

from gi.repository import Playerctl

player = Playerctl.Player()
title = player.get_title()
artist = player.get_artist()
album = player.get_album()

Popen(['dunstify', '-a', 'Spotify', title, f'{artist}\n{album}'])
