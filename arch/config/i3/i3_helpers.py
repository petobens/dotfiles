"""i3 common helper functions."""

import subprocess


def sh(cmd, *args, **kwargs):
    """Run sh command."""
    res, _ = sh_no_block(cmd, *args, stdout=subprocess.PIPE, **kwargs).communicate()
    return res


def sh_no_block(cmd, *args, **kwargs):
    """Run sh command without blocking output."""
    if isinstance(cmd, str):
        cmd = cmd.split()
    return subprocess.Popen(cmd, *args, **kwargs)
