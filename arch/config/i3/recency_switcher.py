#!/usr/bin/env python3
"""i3 recency window switcher."""

import json
import socket
from argparse import ArgumentParser
from subprocess import check_output

import i3ipc
from focus_watcher import SOCKET_FILE

ICON_MAP = {
    'alacritty': 'Alacritty',
    'connman-gtk': 'wifi-radar',
    'gnome-font-viewer': 'org.gnome.font-viewer',
    'kodi': 'kodi',
    'pm': 'freeoffice-planmaker',
    'pr': 'freeoffice-presentations',
    'simple-scan': 'org.gnome.SimpleScan',
    'tm': 'freeoffice-textmaker',
    'vimiv': 'image-viewer',
    'zoom': 'Zoom',
}


class Sockets:
    """Socket wrapper."""

    def __init__(self, socket_file):
        self._socket_file = socket_file
        self._client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

    def get_containers_history(self):
        """Connect to socket and get open windows info."""
        self._client.connect(self._socket_file)
        history_json = self._client.recv(4096).decode()
        self._client.close()
        return json.loads(history_json)


class Menu:
    """Show window menu for easy window focusing."""

    def __init__(self, i3, menu, menu_args):
        self._i3 = i3
        self._menu = menu
        self._menu_args = menu_args

    def menu_focus(self, containers_info):
        """Generate menu and switch focus to selected candidate."""
        candidates, candidates_without_icon, focused_index = self._build_menu_str(
            containers_info
        )
        infos_by_candidate = dict(zip(candidates_without_icon, containers_info))
        selected_candidate = self._show_menu(candidates, focused_index)
        selected_win = infos_by_candidate[selected_candidate]['id']
        self._i3.command(f"[con_id={selected_win}] focus")

    def _show_menu(self, candidates, focused_index):
        menu_cmd = rf'echo -e "{candidates}" | '
        menu_cmd += rf'{self._menu} {self._menu_args} -a {focused_index}'
        return check_output(menu_cmd, shell=True).decode().strip()  # type: ignore

    def _build_menu_str(self, containers_info):
        candidates = ''
        candidates_without_icon = []
        rows = {}
        for i, w in enumerate(containers_info):
            if w['focused']:
                focused_index = i
            rows[w['window']] = [
                w['workspace'],
                w['window_class'] if w['window_class'] is not None else '',
                w['window_title'],
            ]
        widths = [max(map(len, col)) for col in zip(*rows.values())]

        repetitions = {}  # type: ignore
        for _, row in rows.items():
            row_str = "   ".join((val.ljust(width) for val, width in zip(row, widths)))
            repetitions[row_str] = (
                repetitions[row_str] + 1 if row_str in repetitions else 1
            )
            if repetitions[row_str] > 1:
                row_str = f'{row_str.rstrip()} ({repetitions[row_str]})'
            icon_str = self._get_window_icon(row[1], row[2])
            candidates += rf"{row_str}{icon_str}\n"
            candidates_without_icon.append(rf"{row_str.rstrip()}")
        return candidates[:-2], candidates_without_icon, focused_index

    def _get_window_icon(self, win_class, win_title):
        icon_name = None
        if win_class == 'Brave-browser':
            if 'Calendar' in win_title:
                icon_name = 'google-agenda'
            elif 'Meet' in win_title:
                icon_name = 'google-meet'
            elif '(Board)' in win_title:
                # TODO: Find a better way of getting clickup app
                icon_name = 'tracker'
        elif win_class == 'Alacritty':
            if 'numbers' in win_title:
                icon_name = 'calc'
            elif 'htop' in win_title:
                icon_name = 'htop'
            elif 'ranger' in win_title:
                icon_name = 'xfce-filemanager'
            elif 'Trash' in win_title:
                icon_name = 'user-trash'
            elif 'ProcKiller' in win_title:
                icon_name = 'view-process-all'
        if icon_name is None:
            win_class_lower = win_class.lower()
            icon_name = ICON_MAP.get(win_class_lower, win_class_lower)
        return rf'\0icon\x1f{icon_name}'


if __name__ == '__main__':
    parser = ArgumentParser(description="Recency window switcher")
    parser.add_argument('--menu', default='rofi', help='The menu command to run.')
    parser.add_argument(
        '--switch',
        dest='switch',
        action='store_true',
        help='Switch to the previous window',
        default=False,
    )
    parser.add_argument(
        '--active-ws',
        dest='active_ws',
        action='store_true',
        help='Only show windows in active workspace.',
        default=False,
    )
    args = parser.parse_args()

    sockets = Sockets(SOCKET_FILE)
    containers_history = sockets.get_containers_history()

    i3_conn = i3ipc.Connection()

    if args.switch:
        i3_conn.command(f"[con_id={containers_history[1]['id']}] focus")
    else:
        selected_row = 1
        if args.active_ws:
            selected_row = 0
            ws = i3_conn.get_tree().find_focused().workspace()
            containers_history = [
                i for i in containers_history if i['workspace'] == ws.name
            ]
        dmenu_cmd = (
            f"-dmenu -p window -i -selected-row {selected_row} "
            "-kb-accept-entry '!Alt-Tab,Return' -kb-row-down 'Alt+Tab,Ctrl-n' "
            "-kb-row-up 'Ctrl-p,Shift+ISO_Left_Tab'"
        )
        rofi_menu = Menu(i3_conn, args.menu, dmenu_cmd)
        rofi_menu.menu_focus(containers_history)
