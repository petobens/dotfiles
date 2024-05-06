#!/usr/bin/env python3
"""Show OneDrive status in Polybar."""

import re
import subprocess

status = None
last_line = subprocess.check_output(
    'journalctl --user-unit onedrive  -n 5 | tail -n 1',
    shell=True,
    universal_newlines=True,
)
m = re.search(r'\d+\]:\s(\w*)\s', last_line)
if m:
    status = m.groups()[0]
else:
    pass

if status in ['Downloading']:
    print(" 󰁅")
elif status in ['Uploading']:
    print(" 󰁝")
elif status in ['Creating', 'Deleting', 'Syncing', 'Moving']:
    print(" %{T6}%{T-}")
elif status in ['Initializing', 'OneDrive', 'Sync']:
    print("")
else:
    print("%{F#e06c75}%{F-}")
