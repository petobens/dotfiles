#!/usr/bin/env python3
import re
import subprocess

from pathlib import Path

LOCATIONS = [Path.home(), '/var/lib/onedrive']
FILE_NAME = 'onedrive.log'
ACTIVE = ['Downloading', 'Creating', 'Syncing']
status = None

for l in LOCATIONS:
    log_file = Path(f"{l}/{FILE_NAME}")
    if log_file.is_file():
        break
else:
    raise FileNotFoundError()

last_line = subprocess.check_output(
    ['tail', '-1', log_file], universal_newlines=True
)

m = re.search('\.\d+\s(\w*)\s', last_line)
if m:
    status = m.groups()[0]
else:
    pass

if status in ACTIVE:
    print(" ")
else:
    print(" 裏")
