#!/usr/bin/env python3
"""Launch programs adjusting fonts if necessary."""
import os
import sys
from time import sleep

import i3ipc
from i3_helpers import sh, sh_no_block


def run_app(app, subcmd):
    """Run application adjusting font size if necessary."""
    i3 = i3ipc.Connection()
    outputs = [i for i in i3.get_outputs() if i.active]
    nr_monitors = len(outputs)
    ws = i3.get_tree().find_focused().workspace()
    output_width = [o.rect.width for o in outputs if o.name == ws.ipc_data['output']][0]
    is_hidpi = output_width > 1920

    gdk = ''
    qt = ''
    if is_hidpi:
        gdk += 'GDK_SCALE=2 '
        if nr_monitors == 1:
            gdk += 'GDK_DPI_SCALE=0.5 '
        if nr_monitors > 1:
            qt += 'QT_SCALE_FACTOR=2 '

    if app == 'connman':
        # It might open in a hidpi screen or not
        sh_no_block(
            ['raiseorlaunch', '-c', 'Connman-gtk', '-f', '-e', f'"{gdk}connman-gtk"']
        )
    elif app == 'zathura':
        # It might open in a hidpi screen or not
        sh_no_block(
            ['raiseorlaunch', '-c', 'Zathura', '-C', '-f', '-e', f'"{gdk}zathura"']
        )
    elif app == 'gnome-font':
        # It might open in a hidpi screen or not
        sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'Gnome-font-viewer',
                '-f',
                '-e',
                f'"{gdk}gnome-font-viewer"',
            ]
        )
    elif app == 'color-picker':
        # It might open in a hidpi screen or not
        sh_no_block(['raiseorlaunch', '-c', 'gcolor3', '-f', '-e', f'"{gdk}gcolor3"'])
    elif app == 'pavucontrol':
        # It might open in a hidpi screen or not
        sh_no_block(
            ['raiseorlaunch', '-c', 'pavucontrol', '-f', '-e', f'"{gdk}pavucontrol"']
        )
    elif app == 'power-manager':
        # It might open in a hidpi screen or not
        sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'xfcer-power-manager-settings',
                '-f',
                '-e',
                f'"{gdk}xfce4-power-manager-settings"',
            ]
        )
    elif app == 'transmission':
        # It always opens in hidpi screen
        gdk += 'GDK_SCALE=2 '
        sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'Transmission-gtk',
                '-W',
                '3',
                '-f',
                '-e',
                f'"{gdk}transmission-gtk"',
            ]
        )
    elif app == 'peek':
        # It might open in a hidpi screen or not
        sh_no_block(['raiseorlaunch', '-c', 'Peek', '-f', '-e', f'"{gdk}peek"'])
    elif app == 'scanner':
        # It might open in a hidpi screen or not
        sh_no_block(
            ['raiseorlaunch', '-c', 'Simple-scan', '-f', '-e', f'"{gdk}simple-scan"']
        )
    elif app == 'thunderbird':
        # It always opens in hidpi screen
        gdk += 'GDK_SCALE=2 '
        sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'Thunderbird',
                '-W',
                '2',
                '-f',
                '-e',
                f'"{gdk}thunderbird"',
            ]
        )
    elif app == 'skype':
        # It always opens in hidpi screen
        gdk += 'GDK_SCALE=2 '
        sh_no_block(
            [
                'raiseorlaunch',
                '-c',
                'Skype',
                '-W',
                '2',
                '-f',
                '-e',
                f'"{gdk}skypeforlinux"',
            ]
        )
    elif app == 'gtk_dialog':
        if subcmd is None:
            raise ValueError('Missing type of dialog!')
        gtk_dialog = ['gtk_dialog', '-t']
        if subcmd == 'poweroff':
            gtk_dialog += [
                "Power Management",
                '-m',
                "Do you want to poweroff?",
                '-a',
                'systemctl poweroff',
            ]
        elif subcmd == 'reboot':
            gtk_dialog += [
                "Power Management",
                '-m',
                "Do you want to reboot?",
                '-a',
                'systemctl reboot',
            ]
        elif subcmd == 'quit':
            gtk_dialog += [
                "App Management",
                '-m',
                "Do you want to quit all apps?",
                '--shell',
                '-a',
                '$HOME/.config/i3/custom_kill.py -w all',
            ]
        elif subcmd == 'usb':
            gtk_dialog += [
                "Media Management",
                '-m',
                "Do you want to eject media drive?",
                '-a',
                'udiskie-umount -a',
            ]
        elif subcmd == 'trash':
            gtk_dialog += [
                "Trash Management",
                '-m',
                "Do you want to empty the trash?",
                '--shell',
                '-a',
                "trash-empty && pkill -INT -f trash-list && "
                "xdotool key Super_L+Control+b && "
                "dunstify -t 2500 -i trashindicator 'Trash Can emptied!'",
            ]
        gtk_env = dict([i.split('=') for i in gdk.split()])  # type: ignore
        sh_no_block(
            gtk_dialog, env={**os.environ, **gtk_env},
        )

    elif app == 'vimiv':
        # It might open in a hidpi screen or not
        sh_no_block(['raiseorlaunch', '-c', 'vimiv', '-C', '-f', '-e', f'"{qt}vimiv"'],)

    elif app == 'rofi':
        if subcmd is None:
            raise ValueError('Missing rofi subcommand!')
        rofi_fsize = 11
        rofi_yoffset = -150
        if is_hidpi & (nr_monitors > 1):
            rofi_fsize *= 2
            rofi_yoffset = int(rofi_yoffset * 1.5)
        rofi_base = f"rofi -font 'Noto Sans Mono {rofi_fsize}' -yoffset {rofi_yoffset}"

        if subcmd == 'apps':
            rofi_cmd = f'{rofi_base} -combi-modi drun,run -show combi'
        elif subcmd == 'pass':
            rofi_cmd = (
                f"gopass ls --flat | {rofi_base} -dmenu -p gopass | "
                "xargs --no-run-if-empty gopass show -c"
            )
        elif subcmd == 'tab':
            rofi_cmd = f'$HOME/.config/i3/recency_switcher.py --menu="{rofi_base}"'
        elif subcmd == 'arch-init':
            yoffset = 25
            if is_hidpi:
                yoffset *= 2
            rofi_cmd = f"$HOME/.config/polybar/arch_dmenu.sh {rofi_fsize} {yoffset}"
        sh_no_block([rofi_cmd], shell=True)

    elif app == 'alacritty':
        if subcmd is None:
            raise ValueError('Missing alacritty subcommand!')
        alacritty_scale = 1
        if is_hidpi:
            alacritty_scale = 2

        alacritty_cmd = f'WINIT_X11_SCALE_FACTOR={alacritty_scale} alacritty -t '
        if subcmd == 'onedrive':
            alacritty_cmd += '"OneDrive" -e sh -c "journalctl --user-unit onedrive -f"'
        elif subcmd == 'bluetooth':
            alacritty_cmd += '"bluetooth-fzf" -d 100 30 -e bash -ci "bt;exit"'
        elif subcmd == 'docker':
            alacritty_cmd += '"docker-info" -d 150 30 -e sh -c "docker info | less +F"'

        elif subcmd == 'htop':
            alacritty_cmd = (
                f"raiseorlaunch -t 'htop' -f -e '{alacritty_cmd} htop -e htop'"
            )
        elif subcmd == 'numbers':
            alacritty_cmd = f"raiseorlaunch -t 'numbers' -f -e '{alacritty_cmd} numbers -e ipython3'"  # noqa
        elif subcmd == 'ranger':
            alacritty_cmd = f'raiseorlaunch -t "ranger" -f -e \'{alacritty_cmd} ranger -e sh -c "ranger $(tmux display -p \"#{{pane_current_path}}\")"\''  # noqa
        elif subcmd == 'trash':
            alacritty_cmd = f'raiseorlaunch -t "Trash Can" -f -e \'{alacritty_cmd} "Trash Can" -e sh -c "trash-list | less"\''  # noqa
        elif subcmd == 'quickterm':
            alacritty_cmd = f'raiseorlaunch -t "QuickTerm" -f -e \'{alacritty_cmd} "QuickTerm" -e /usr/bin/bash -l -c "cd $(tmux display -p \"#{{pane_current_path}}\") && exec /usr/bin/bash -i"\''  # noqa
        elif subcmd == 'prockiller':
            alacritty_cmd = f'raiseorlaunch -t "ProcKiller" -f -e \'{alacritty_cmd} "ProcKiller" -e /usr/bin/bash -l -c "exec /usr/bin/bash -i"\''  # noqa
        sh_no_block([alacritty_cmd], shell=True)

        if subcmd == 'prockiller':
            sleep(0.8)
            sh('xdotool type kill')
            sh('xdotool key space+Tab')


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('application')
    parser.add_argument('subcommand', nargs='?', default=None)
    parse_args = parser.parse_args()

    run_app(parse_args.application, parse_args.subcommand)
    sys.exit(0)
