#!/usr/bin/env python3
"""Show number of windows in active workspace on Polybar."""

# Loosely based on https://github.com/meelkor/polybar-i3-windows

from i3ipc import Connection, Event


def ws_win_number(i3_conn, e):  # pylint:disable=unused-argument
    """Compute number of windows in active i3 workspace."""
    # TODO: Can we show active windows per monitor workspace instead of active ws?
    curr_workspace = next(i for i in i3_conn.get_workspaces() if i.focused)
    windows = [
        win
        for ws in i3_conn.get_tree().workspaces()
        for win in ws.leaves()
        if ws.name == curr_workspace.name
    ]
    nr_windows = len(windows)
    label = f"%{{T6}} %{{T-}}%{{T7}}{nr_windows}%{{T-}}"
    action_label = f"%{{A1:/home/pedro/.config/i3/font_aware_launcher.py rofi ws-win &:}}{label}%{{A}}"  # noqa
    print(action_label, flush=True)


if __name__ == '__main__':
    i3 = Connection()
    ws_win_number(i3, None)  # to populate polybar on first run
    i3.on(Event.WINDOW_FOCUS, ws_win_number)
    # We need the next events to be able to handle the case where there are no windows
    # in the workspace (and hence a zero should be shown)
    i3.on(Event.WORKSPACE_FOCUS, ws_win_number)
    i3.on(Event.WINDOW, ws_win_number)
    i3.main()
