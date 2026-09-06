#!/usr/bin/env python3
"""Track focused windows and grab QEMU input."""

import json
import os
import selectors
import socket
import subprocess
import tempfile
import threading

import i3ipc

SOCKET_DIR = '{}/i3_focus_watcher.{}{}'.format(
    tempfile.gettempdir(), os.geteuid(), os.getenv("DISPLAY")
)
SOCKET_FILE = '{}/socket'.format(SOCKET_DIR)
MAX_WIN_HISTORY = 20


class FocusWatcher:
    """Store i3 focused windows."""

    def __init__(self):
        self.i3 = i3ipc.Connection()
        self.i3.on(i3ipc.Event.WINDOW_FOCUS, self._on_window_focus)
        self.i3.on(i3ipc.Event.WINDOW_CLOSE, self._on_window_close)
        # Make a directory with permissions that restrict access to
        # the user only.
        os.makedirs(SOCKET_DIR, mode=0o700, exist_ok=True)
        self.listening_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        if os.path.exists(SOCKET_FILE):
            os.remove(SOCKET_FILE)
        self.listening_socket.bind(SOCKET_FILE)
        self.listening_socket.listen(1)
        self.window_list = []
        self.window_list_lock = threading.RLock()

    def _on_window_focus(self, i3conn, event):  # pylint:disable=unused-argument
        if event.container.window_class == "Qemu-system-x86_64":
            # Trigger grab-on-hover without moving the pointer after mouse focus
            window = str(event.container.window)
            pointer = subprocess.run(
                ["xdotool", "getmouselocation", "--shell"],
                capture_output=True,
                check=False,
                text=True,
            )
            if f"WINDOW={window}" not in pointer.stdout.splitlines():
                subprocess.run(
                    ["xdotool", "mousemove", "--window", window, "100", "100"],
                    check=False,
                )

        with self.window_list_lock:
            window_id = event.container.id
            if window_id in self.window_list:
                self.window_list.remove(window_id)
            self.window_list.insert(0, window_id)
            if len(self.window_list) > MAX_WIN_HISTORY:
                del self.window_list[MAX_WIN_HISTORY:]

    def _on_window_close(self, i3conn, event):  # pylint:disable=unused-argument
        with self.window_list_lock:
            window_id = event.container.id
            if window_id in self.window_list:
                self.window_list.remove(window_id)

    def _launch_server(self):
        selector = selectors.DefaultSelector()

        def accept(sock):
            conn, _ = sock.accept()
            info = []
            with self.window_list_lock:
                tree = self.i3.get_tree()
                for window_id in self.window_list:
                    con = tree.find_by_id(window_id)
                    if con:
                        info.append(
                            {
                                "id": con.id,
                                "workspace": con.workspace().name,
                                "window": con.window,
                                "window_class": con.window_class,
                                "window_title": con.window_title,
                                "focused": con.focused,
                            }
                        )
                conn.send(json.dumps(info).encode())
                conn.close()

        selector.register(self.listening_socket, selectors.EVENT_READ, accept)

        while True:
            for key, _ in selector.select():
                callback = key.data
                callback(key.fileobj)

    def run(self):
        """Run socket."""
        t_server = threading.Thread(target=self._launch_server, daemon=True)
        t_server.start()
        self.i3.main()


if __name__ == '__main__':
    focus_watcher = FocusWatcher()
    focus_watcher.run()
