#!/usr/bin/env python
from subprocess import Popen

import gi

gi.require_version('Gtk', '3.0')

from gi.repository import Gtk


def confirmation_dialog(action):
    assert action in ['poweroff', 'reboot']
    win = Gtk.Window()
    win.connect("destroy", Gtk.main_quit)

    dialog = Gtk.Dialog(
        parent=win,
        buttons=(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK,
            Gtk.ResponseType.OK
        )
    )
    dialog.set_property('title', 'Power Management')
    dialog.set_default_size(150, 100)
    label = Gtk.Label(f"Do you want to {action}?")
    box = dialog.get_content_area()
    box.add(label)
    dialog.show_all()

    res = dialog.run()
    if res == Gtk.ResponseType.OK:
        Popen(['systemctl', action])
    elif res == Gtk.ResponseType.CANCEL:
        pass
    dialog.destroy()
    quit()


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('action')
    args = parser.parse_args()

    confirmation_dialog(args.action)
    Gtk.main()
