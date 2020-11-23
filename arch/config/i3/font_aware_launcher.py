#!/usr/bin/env python3
"""Launch programs adjusting fonts if necessary."""
import os
import sys
from time import sleep

import i3ipc

from i3_helpers import sh, sh_no_block
from multimon_move import get_output_width


def run_app(app, subcmd, workspace_name=None):
    """Run application adjusting font size if necessary."""
    i3 = i3ipc.Connection()
    ws = None
    if workspace_name is not None:
        ws = _get_workspace(i3, workspace_name)
    output_width, other_output_width, outputs = get_output_width(i3, ws)
    is_hidpi = output_width > 1920
    other_is_hidpi = other_output_width > 1920
    nr_monitors = len(outputs)

    gdk = ''
    qt = ''
    if is_hidpi:
        gdk += 'GDK_SCALE=2 '
        if nr_monitors == 1 or other_is_hidpi:
            # If everything is hidpi also scale icons
            gdk += 'GDK_DPI_SCALE=0.5 '
        if nr_monitors > 1 and not other_is_hidpi:
            # Only scale if we have a mix of hd and hidpi monitors
            qt += 'QT_SCALE_FACTOR=2 '

    if app == 'rofi':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        if subcmd is None:
            raise ValueError('Missing rofi subcommand!')
        rofi_fsize = 11
        rofi_yoffset = -110
        rofi_icon_size = 1.8
        if is_hidpi & (nr_monitors > 1) and not other_is_hidpi:
            rofi_fsize *= 2
            rofi_yoffset = int(rofi_yoffset * 1.5)
            rofi_icon_size = 2.0
        if subcmd == 'apps':
            rofi_base = [
                'rofi',
                '-font',
                f"Noto Sans Mono {rofi_fsize}",
                '-yoffset',
                f'{rofi_yoffset}',
                '-theme-str',
                f"element-icon {{ size: {rofi_icon_size}ch; }}",  # we use double quotes due to spaces # noqa
            ]
            rofi_cmd = rofi_base + [
                '-combi-modi',
                'drun,run',
                '-show',
                'combi',
                '-modi',
                'combi',
                '-display-combi',
                'runner',
            ]
            sh_no_block(rofi_cmd)
        else:
            rofi_base = (
                f"rofi -font 'Noto Sans Mono {rofi_fsize}' -yoffset {rofi_yoffset}"
            )
            rofi_base += f" -theme-str 'element-icon {{ size: {rofi_icon_size}ch; }}'"
            if subcmd == 'pass':
                rofi_cmd = (
                    f"gopass ls --flat | {rofi_base} -dmenu -p gopass | "
                    "xargs --no-run-if-empty gopass show -c"
                )
            elif subcmd == 'tab':
                rofi_cmd = f'$HOME/.config/i3/recency_switcher.py --menu="{rofi_base}"'
            elif subcmd == 'ws-win':
                rofi_cmd = (
                    '$HOME/.config/i3/recency_switcher.py --active-ws '
                    f'--menu="{rofi_base} -p ws-window"'
                )
            elif subcmd == 'font-aware-apps':
                rofi_cmd = f'$HOME/.config/i3/font_aware_menu.py --menu="{rofi_base}"'
            elif subcmd == 'arch-init':
                yoffset = 25
                if is_hidpi:
                    yoffset *= 2
                rofi_cmd = f"$HOME/.config/polybar/arch_dmenu.sh {rofi_fsize} {yoffset}"
            sh_no_block([rofi_cmd], shell=True)

    elif app == 'connman':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(
            ['raiseorlaunch', '-c', 'Connman-gtk', '-f', '-e', f'"{gdk}connman-gtk"']
        )
    elif app == 'zathura':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(
            ['raiseorlaunch', '-c', 'Zathura', '-C', '-f', '-e', f'"{gdk}zathura"']
        )
    elif app == 'gnome-font':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
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
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(['raiseorlaunch', '-c', 'gcolor3', '-f', '-e', f'"{gdk}gcolor3"'])
    elif app == 'pavucontrol':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(
            ['raiseorlaunch', '-c', 'pavucontrol', '-f', '-e', f'"{gdk}pavucontrol"']
        )
    elif app == 'power-manager':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
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
        #  Opens in ws 4 which chould be or not a hidpi screen (depends on the number of
        # connected monitors)
        cmd = [
            'raiseorlaunch',
            '-c',
            'Transmission-gtk',
            '-f',
            '-e',
            f'"{gdk}transmission-gtk"',
        ]
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'peek':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(['raiseorlaunch', '-c', 'Peek', '-f', '-e', f'"{gdk}peek"'])
    elif app == 'scanner':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(
            ['raiseorlaunch', '-c', 'Simple-scan', '-f', '-e', f'"{gdk}simple-scan"']
        )
    elif app == 'thunderbird':
        # Opens in ws 3 which is always in a hidpi screen
        gdk += 'GDK_SCALE=2 '
        cmd = [
            'raiseorlaunch',
            '-c',
            'Thunderbird',
            '-f',
            '-e',
            f'"{gdk}thunderbird"',
        ]
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'gtk_dialog':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
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
            gtk_dialog,
            env={**os.environ, **gtk_env},
        )

    elif app == 'vimiv':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        sh_no_block(['raiseorlaunch', '-c', 'vimiv', '-C', '-f', '-e', f'"{qt}vimiv"'])

    elif app == 'brave':
        # Might open in hidpi screen or not but there is no way to adjust fonts before
        # actually opening the application so we adjust zoom after the apps opens
        if subcmd is None:
            raise ValueError('Missing brave subcommand!')

        brave_cmd = f'raiseorlaunch -c Brave -m {subcmd} -e "brave'
        if is_hidpi and nr_monitors > 1 and not other_is_hidpi:
            brave_cmd += ' --force-device-scale-factor=2'
        if subcmd != 'browser':
            brave_cmd += f' --new-window --app=https://{subcmd}.google.com{{extra}}'
        brave_cmd += '"'
        if workspace_name is not None:
            brave_cmd += f' -W {workspace_name}'

        if subcmd == 'calendar':
            brave_cmd = brave_cmd.format(extra='/calendar/b/0/r')
        elif subcmd == 'hangouts':
            brave_cmd = brave_cmd.format(extra='/?authuser=1')
        elif subcmd == 'meet':
            brave_cmd = brave_cmd.format(extra='')
        sh_no_block([brave_cmd], shell=True)
        if subcmd not in i3.get_marks():  # run this only on first open
            sleep(2.5)
            # Ensure we have proper scaling
            sh('xdotool key Super+0')
            # If we have 1 external monitor then all brave windows live on the
            # primary monitory which is hidpi. If we have 2 or more then the main brave
            # window will live in a (potentially) non hidpi screen and be
            # scaled using the `--force-device..` flag so we need to rescale this window
            # in a hidpi screen using the zoom keybinding
            if is_hidpi and nr_monitors > 2 and not other_is_hidpi:
                sh('xdotool key Super+u')

    elif app == 'alacritty':
        # Opens in current ws which might be a hidpi screen or not (i.e no fixed ws)
        if subcmd is None:
            raise ValueError('Missing alacritty subcommand!')
        alacritty_scale = 1
        if is_hidpi:
            alacritty_scale = 2

        alacritty_cmd = f'WINIT_X11_SCALE_FACTOR={alacritty_scale} alacritty -t '
        if subcmd == 'onedrive':
            alacritty_cmd += (
                '"OneDrive" -e /usr/bin/bash -c "journalctl --user-unit onedrive -f"'
            )
        elif subcmd == 'bluetooth':
            alacritty_cmd += '"bluetooth-fzf" -d 100 30 -e /usr/bin/bash -ci "bt;exit"'
        elif subcmd == 'docker':
            alacritty_cmd += (
                '"docker-info" -d 150 30 -e /usr/bin/bash -c "docker info | less +F"'
            )
        if subcmd == 'about-arch':
            alacritty_cmd += (
                '"About Arch" -e /usr/bin/bash -i -c "neofetch; read -p \'\'"'
            )

        elif subcmd == 'htop':
            alacritty_cmd = (
                f"raiseorlaunch -t 'htop' -f -e '{alacritty_cmd} htop -e htop'"
            )
        elif subcmd == 'numbers':
            alacritty_cmd = f"raiseorlaunch -t 'numbers' -f -e '{alacritty_cmd} numbers -e ipython3'"  # noqa
        elif subcmd == 'ranger':
            alacritty_cmd = f'raiseorlaunch -t "ranger" -f -e \'{alacritty_cmd} ranger -e /usr/bin/bash -c "ranger $(tmux display -p \"#{{pane_current_path}}\")"\''  # noqa
        elif subcmd == 'trash':
            alacritty_cmd = f'raiseorlaunch -t "Trash Can" -f -e \'{alacritty_cmd} "Trash Can" -e /usr/bin/bash -c "trash-list | less"\''  # noqa
        elif subcmd == 'quickterm':
            alacritty_cmd = f'raiseorlaunch -t "QuickTerm" -f -e \'{alacritty_cmd} "QuickTerm" -e /usr/bin/bash -l -c "cd $(tmux display -p \"#{{pane_current_path}}\") && exec /usr/bin/bash -i"\''  # noqa
        elif subcmd == 'prockiller':
            alacritty_cmd = f'raiseorlaunch -t "ProcKiller" -f -e \'{alacritty_cmd} "ProcKiller" -e /usr/bin/bash -l -c "exec /usr/bin/bash -i"\''  # noqa
        sh_no_block([alacritty_cmd], shell=True)

        if subcmd == 'prockiller':
            sleep(0.8)
            sh('xdotool type kill')
            sh('xdotool key space+Tab')

    elif app == 'firefox':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'firefox', '-m', 'ffox']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'slack':
        # Opens in hidpi screen
        cmd = 'raiseorlaunch -c Slack -l 30 -e "slack --force-device-scale-factor=2"'
        if workspace_name is not None:
            cmd += f' -W {workspace_name}'
        sh_no_block([cmd], shell=True)
    elif app == 'teams':
        # Opens in hidpi screen
        cmd = 'raiseorlaunch -c Teams -l 30 -e "teams --force-device-scale-factor=2"'
        if workspace_name is not None:
            cmd += f' -W {workspace_name}'
        sh_no_block([cmd], shell=True)
    elif app == 'zoom':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'Zoom', '-l', '30']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'spotify':
        # Opens in hidpi screen
        cmd = (
            'raiseorlaunch -c Spotify -l 30 -e "spotify --force-device-scale-factor=2"'
        )
        if workspace_name is not None:
            cmd += f' -W {workspace_name}'
        sh_no_block([cmd], shell=True)
    elif app == 'planmaker':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'pm', '-l', '30', '-e', '"freeoffice-planmaker"']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'textmaker':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'pm', '-l', '30', '-e', '"freeoffice-textmaker"']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'presentations':
        # Opens in ws which might be a hidpi screen or not
        cmd = [
            'raiseorlaunch',
            '-c',
            'pm',
            '-l',
            '30',
            '-e',
            '"freeoffice-presentations"',
        ]
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'kitty':
        # Opens in hidpi screen or not
        cmd = 'raiseorlaunch -c kitty -m terminal -e \'kitty /usr/bin/bash -l -c "/usr/bin/bash -i -c tm"\''
        if workspace_name is not None:
            cmd += f' -W {workspace_name}'
        sh_no_block([cmd], shell=True)
    elif app == 'discord':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'discord', '-l', '30']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'kodi':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'kodi']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'globalprotect-vpn':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'gpclient', '-f', '-e', f'"{qt}gpclient"']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)
    elif app == 'obs':
        # Opens in ws which might be a hidpi screen or not
        cmd = ['raiseorlaunch', '-c', 'obs', '-f', '-e', f'"{qt}obs"']
        if workspace_name is not None:
            cmd += ['-W', f'{workspace_name}']
        sh_no_block(cmd)


def _get_workspace(i3, name):
    workspace = next((i for i in i3.get_workspaces() if i.name == name), None)
    if workspace is None:
        i3.command(f'workspace {name}')
        sleep(0.1)
        workspace = next((i for i in i3.get_workspaces() if i.name == name), None)
    return workspace


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('application')
    parser.add_argument('subcommand', nargs='?', default=None)
    parser.add_argument('--workspace', '-W', required=False, type=str, default=None)
    parsed_args = parser.parse_args()

    run_app(parsed_args.application, parsed_args.subcommand, parsed_args.workspace)
    sys.exit(0)
