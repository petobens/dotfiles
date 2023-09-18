#!/usr/bin/env python3
"""Launch programs adjusting fonts if necessary."""
import os
from time import sleep

import i3ipc
from i3_helpers import sh, sh_no_block
from multimon_move import get_output_width

APPS = {
    'about-arch': {
        'type': 'tui',
        'args': {
            'title': 'About Arch',
            'cmd': "neofetch; read -p ''",
            'use_rol': False,
            'interactive_bash': True,
        },
    },
    'bluetooth': {
        'type': 'tui',
        'args': {
            'title': 'bluetooth-fzf',
            'cmd': 'bt;exit',
            'use_rol': False,
            'interactive_bash': True,
            'dimensions': (100, 30),
        },
    },
    'brave': {
        'type': 'electron',
        'args': {'class_name': 'Brave', 'mark': 'brave', 'post_cmd': True},
    },
    'calendar': {
        'type': 'electron',
        'args': {
            'class_name': 'Brave',
            'mark': 'calendar',
            'subcmd': 'calendar',
            'post_cmd': True,
        },
    },
    'clickup': {
        'type': 'electron',
        'args': {
            'class_name': 'Brave',
            'mark': 'clickup',
            'subcmd': 'clickup',
            'post_cmd': True,
        },
    },
    'color-picker': {'type': 'gtk', 'args': {'class_name': 'Gcolor3'}},
    'connman': {'type': 'gtk', 'args': {'class_name': 'Connman-gtk'}},
    'docker': {
        'type': 'tui',
        'args': {
            'title': 'docker-info',
            'cmd': 'docker info | less +F',
            'use_rol': False,
            'dimensions': (150, 30),
        },
    },
    'edge': {
        'type': 'electron',
        'args': {
            'class_name': 'Microsoft-edge-dev',
            'mark': 'edge',
            'post_cmd': True,
        },
    },
    'firefox': {'type': 'rol', 'args': {'class_name': 'firefox', 'mark': 'ffox'}},
    'globalprotect-vpn': {'type': 'qt', 'args': {'class_name': 'gpclient'}},
    'gnome-font': {'type': 'gtk', 'args': {'class_name': 'Gnome-font-viewer'}},
    'htop': {'type': 'tui', 'args': {'title': 'htop', 'cmd': 'htop'}},
    'kitty': {
        'type': 'rol_custom',
        'args': {
            'class_name': 'kitty',
            'mark': 'terminal',
            'cmd': 'kitty',
        },
    },
    'kodi': {'type': 'rol', 'args': {'class_name': 'kodi'}},
    'mailspring': {
        'type': 'electron',
        'args': {'class_name': 'Mailspring', 'event_delay': 30},
    },
    'meet': {
        'type': 'electron',
        'args': {
            'class_name': 'Brave',
            'mark': 'meet',
            'subcmd': 'meet',
            'post_cmd': True,
        },
    },
    'numbers': {'type': 'tui', 'args': {'title': 'numbers', 'cmd': 'ipython3'}},
    'obs': {'type': 'qt', 'args': {'class_name': 'obs'}},
    'onedrive': {
        'type': 'tui',
        'args': {
            'title': 'OneDrive',
            'cmd': 'journalctl --user-unit onedrive -f',
            'use_rol': False,
        },
    },
    'pavucontrol': {'type': 'gtk', 'args': {'class_name': 'Pavucontrol'}},
    'peek': {'type': 'gtk', 'args': {'class_name': 'Peek'}},
    'planmaker': {
        'type': 'rol_custom',
        'args': {'class_name': 'pm', 'cmd': 'freeoffice-planmaker', 'event_delay': 30},
    },
    'power-manager': {
        'type': 'gtk',
        'args': {'class_name': 'Xfce4-power-manager-settings'},
    },
    'poweroff-dialog': {
        'type': 'gtk',
        'args': {
            'is_dialog': True,
            'class_name': 'Power Management',
            'title': 'Do you want to poweroff?',
            'cmd': 'systemctl poweroff',
        },
    },
    'presentations': {
        'type': 'rol_custom',
        'args': {
            'class_name': 'pr',
            'cmd': 'freeoffice-presentations',
            'event_delay': 30,
        },
    },
    'prockiller': {
        'type': 'tui',
        'args': {
            'title': 'ProcKiller',
            'cmd': '/usr/bin/bash -l -c "exec /usr/bin/bash -i"',
            'post_cmd': True,
        },
    },
    'quickterm': {
        'type': 'tui',
        'args': {
            'title': 'QuickTerm',
            'cmd': '/usr/bin/bash -l -c "cd $(tmux display -p \"#{pane_current_path}\") && exec /usr/bin/bash -i"',  # noqa
        },
    },
    'quit-dialog': {
        'type': 'gtk',
        'args': {
            'is_dialog': True,
            'class_name': 'App Management',
            'title': 'Do you want to quit all apps?',
            'shell': True,
            'cmd': '$HOME/.config/i3/custom_kill.py -w all',
        },
    },
    'ranger': {
        'type': 'tui',
        'args': {
            'title': 'ranger',
            'cmd': '/usr/bin/bash -c "ranger {path}"',
        },
    },
    'reboot-dialog': {
        'type': 'gtk',
        'args': {
            'is_dialog': True,
            'class_name': 'Power Management',
            'title': 'Do you want to reboot?',
            'cmd': 'systemctl reboot',
        },
    },
    'rofi-arch-init': {'type': 'rofi', 'args': {'class_name': 'rofi-arch-init'}},
    'rofi-font-aware-apps': {
        'type': 'rofi',
        'args': {'class_name': 'rofi-font-aware-apps'},
    },
    'rofi-pass': {'type': 'rofi', 'args': {'class_name': 'rofi-pass'}},
    'rofi-runner': {'type': 'rofi', 'args': {'class_name': 'rofi-runner'}},
    'rofi-tab': {'type': 'rofi', 'args': {'class_name': 'rofi-tab'}},
    'rofi-ws-win': {'type': 'rofi', 'args': {'class_name': 'rofi-ws-win'}},
    'scanner': {'type': 'gtk', 'args': {'class_name': 'Simple-scan'}},
    'slack': {'type': 'electron', 'args': {'class_name': 'Slack', 'event_delay': 30}},
    'spotify': {
        'type': 'electron',
        'args': {'class_name': 'Spotify', 'event_delay': 30},
    },
    'teams': {
        'type': 'electron',
        'args': {
            'class_name': 'Brave',
            'mark': 'teams',
            'subcmd': 'teams',
            'post_cmd': True,
        },
    },
    'textmaker': {
        'type': 'rol_custom',
        'args': {'class_name': 'tm', 'cmd': 'freeoffice-textmaker', 'event_delay': 30},
    },
    'transmission': {'type': 'gtk', 'args': {'class_name': 'Transmission-gtk'}},
    'trash': {
        'type': 'tui',
        'args': {'title': 'Trash Can', 'cmd': '/usr/bin/bash -c "trash-list | less"'},
    },
    'trash-dialog': {
        'type': 'gtk',
        'args': {
            'is_dialog': True,
            'class_name': 'Trash Management',
            'title': 'Do you want to empty the trash?',
            'shell': True,
            'cmd': (
                "trash-empty -f && pkill -INT -f trash-list && "
                "xdotool key Super_L+Control+b && "
                "dunstify -t 2500 -i trashindicator 'Trash Can emptied!'"
            ),
        },
    },
    'usb-dialog': {
        'type': 'gtk',
        'args': {
            'is_dialog': True,
            'class_name': 'Media Management',
            'title': 'Do you want to eject media drive?',
            'cmd': 'udiskie-umount -a',
        },
    },
    'vimiv': {'type': 'qt', 'args': {'class_name': 'vimiv', 'cycle': True}},
    'vscode': {'type': 'electron', 'args': {'class_name': 'Code', 'event_delay': 30}},
    'zathura': {'type': 'gtk', 'args': {'class_name': 'Zathura', 'cycle': True}},
    'zoom': {'type': 'rol', 'args': {'class_name': 'Zoom', 'event_delay': 30}},
}


class Screen:
    """Get screens context using i3."""

    HD_WIDTH = 1920

    def __init__(self):
        self.is_hidpi = None
        self.other_is_hidpi = None
        self.nr_monitors = None
        self.i3 = i3ipc.Connection()

    def get_monitors_context(self, ws_name):
        """Actually compute monitor context."""
        ws = None
        if ws_name is not None:
            ws = self._get_workspace(self.i3, ws_name)
        output_width, other_output_width, outputs = get_output_width(self.i3, ws)
        self.is_hidpi = output_width > self.HD_WIDTH
        self.other_is_hidpi = other_output_width > self.HD_WIDTH
        self.nr_monitors = len(outputs)
        return

    @property
    def gdk_env(self):
        """Set GDK environmental variables conditional on monitor context."""
        gdk = ''
        if self.is_hidpi:
            gdk += 'GDK_SCALE=2 '
            if self.nr_monitors == 1 or self.other_is_hidpi:
                # If everything is hidpi also scale icons
                gdk += 'GDK_DPI_SCALE=0.5 '
        return gdk

    @property
    def qt_env(self):
        """Set QT environmental variables conditional on monitor context."""
        qt = ''
        if self.is_hidpi and self.nr_monitors > 1 and not self.other_is_hidpi:  # type: ignore
            # Only scale if we have a mix of hd and hidpi monitors
            qt += 'QT_SCALE_FACTOR=2 '
        return qt

    @staticmethod
    def _get_workspace(i3, name):
        workspace = next((i for i in i3.get_workspaces() if i.name == name), None)
        if workspace is None:
            # If the workspace doesn't exist create and switch to it
            i3.command(f'workspace {name}')
            sleep(0.01)
            workspace = next((i for i in i3.get_workspaces() if i.name == name), None)
        return workspace


class ROLApp:
    """Wrapper around raiseorlaunch command."""

    def __init__(
        self,
        class_name=None,
        shell=False,
        ws=None,
        cycle=False,
        leave_fullscreen=True,
        event_delay=2,
        mark=None,
        title=None,
        cmd=None,
        subcmd=None,
        post_cmd=False,
    ):
        # raiseorlaunch flags
        self.class_name = class_name
        self.shell = shell
        self.ws = ws
        self.cycle = cycle
        self.leave_fullscreen = leave_fullscreen
        self.event_delay = event_delay
        self.mark = mark
        self.title = title
        self.cmd = cmd if cmd is not None else class_name.lower()
        self.subcmd = subcmd
        self.post_cmd = post_cmd
        self.cmd_args = {}
        # xrandr/i3 context
        self.screen = Screen()

    def launch(self):
        """Launch app adjusting fonts if monitory context demands it."""
        self.screen.get_monitors_context(self.ws)
        cmd = self._build_cmd()
        if self.shell:
            cmd = [cmd]
        print(cmd)
        sh_no_block(cmd, shell=self.shell, **self.cmd_args)
        if self.post_cmd:
            self._run_post_cmd()

    def _build_cmd(self):
        return self._raiseorlauch_cmd()

    def _run_post_cmd(self):
        pass

    def _raiseorlauch_cmd(self):
        cmd = ['raiseorlaunch']
        if self.class_name is not None:
            cmd += ['-c', self.class_name]
        if self.ws is not None:
            cmd += ['-W', f'{self.ws}']
        if self.cycle:
            cmd += ['-C']
        if self.leave_fullscreen:
            cmd += ['-f']
        if self.mark is not None:
            cmd += ['-m', self.mark]
        if self.title is not None:
            cmd += ['-t', f"'{self.title}'"]
        if self.event_delay != 2:  # default value
            cmd += ['-l', f'{self.event_delay}']
        if self.shell:
            cmd = ' '.join(cmd)  # type: ignore
        return cmd


class ROLCustomApp(ROLApp):
    """Use raiseorlaunch but specify executable to run."""

    def _build_cmd(self):
        cmd = self._raiseorlauch_cmd()
        if self.class_name == 'kitty':
            if (
                self.screen.is_hidpi
                and self.screen.nr_monitors > 1  # type: ignore
                and not self.screen.other_is_hidpi
            ):
                self.cmd += ' -o font_size=22'
            self.cmd += ' /usr/bin/bash -l -c "/usr/bin/bash -i -c tm"'
        cmd += ['-e', f'{self.cmd}']
        return cmd


class GTKApp(ROLApp):
    """Launch GTK apps."""

    def __init__(self, is_dialog=False, **kwargs):
        super().__init__(**kwargs)
        self.is_dialog = is_dialog

    def _build_cmd(self):
        if not self.is_dialog:
            cmd = self._raiseorlauch_cmd()
            # Note: if change sccale for transmission-gtk everything looks huge
            env_var = (
                self.screen.gdk_env.replace('_SCALE=2', '_SCALE=1')
                if self.cmd == 'transmission-gtk'
                else self.screen.gdk_env
            )
            cmd += ['-e', f'"{env_var}{self.cmd}"']
        else:
            gtk_env = dict([i.split('=') for i in self.screen.gdk_env.split()])  # type: ignore
            self.cmd_args = {'env': {**os.environ, **gtk_env}}
            cmd = [
                'gtk_dialog',
                '-t',
                f"{self.class_name}",
                '-m',
                f"{self.title}",
                '-a',
                self.cmd,
            ]
            if self.shell:
                cmd += ['--shell']
                self.shell = False
        return cmd


class QTApp(ROLApp):
    """Launch QT apps."""

    def _build_cmd(self):
        cmd = self._raiseorlauch_cmd()
        cmd += ['-e', f'"{self.screen.qt_env}{self.cmd}"']
        return cmd


class TUIApp(ROLApp):
    """Launch TUI apps."""

    def __init__(self, use_rol=True, interactive_bash=False, dimensions=(), **kwargs):
        super().__init__(shell=True, **kwargs)
        self.use_rol = use_rol
        self.interactive_bash = interactive_bash
        self.dimensions = dimensions

    def _build_cmd(self):
        alacritty_scale = 2 if self.screen.is_hidpi else 1
        alacritty_cmd = (
            f'PINENTRY_USER_DATA={self.screen.qt_env} WINIT_X11_SCALE_FACTOR={alacritty_scale} '
            f'alacritty -t "{self.title}"'
        )
        if self.use_rol:
            cmd = self._raiseorlauch_cmd()
            cmd += f" -e '{alacritty_cmd} -e {self.cmd}'"
        else:
            cmd = alacritty_cmd
            if self.dimensions:
                cols, lines = self.dimensions
                cmd += f' --option window.dimensions.columns={cols} --option window.dimensions.lines={lines}'  # noqa
            cmd += ' -e /usr/bin/bash -c '
            if self.interactive_bash:
                cmd += '-i '
            cmd += f'"{self.cmd}"'

        if self.title == 'ranger':
            # FIXME: https://github.com/open-dynaMIX/raiseorlaunch/issues/66#issuecomment-1399110913
            ranger_path = (
                sh('tmux display -p "#{?pane_path,#{pane_path},#{pane_current_path}}"')
                .decode('ascii')
                .strip()
                .split('"')[1]
            )
            cmd = cmd.format(path=ranger_path)

        return cmd

    def _run_post_cmd(self):
        if self.title == 'ProcKiller':
            sleep(0.8)
            sh('xdotool type kill')
            sh('xdotool key space+Tab')


class RofiApp(ROLApp):
    """Launch Rofi apps."""

    def __init__(self, **kwargs):
        super().__init__(shell=True, **kwargs)
        self.font_size = 11
        self.yoffset = -10
        self.icon_size = 1.8

    def _build_cmd(self):
        if (
            self.screen.is_hidpi
            and (self.screen.nr_monitors > 1)  # type: ignore
            and not self.screen.other_is_hidpi
        ):
            self.font_size *= 2
            self.yoffset = int(self.yoffset * 1.5)
            self.icon_size = 2.0
        base_cmd = (
            f"rofi -font 'noto sans mono {self.font_size}' -yoffset {self.yoffset} "
            f"-theme-str 'element-icon {{ size: {self.icon_size}ch; }}'"
        )

        if self.class_name == 'rofi-runner':
            cmd = (
                f"{base_cmd} -combi-modi drun,run -show combi "
                "-modi combi -display-combi runner"
            )
        elif self.class_name == 'rofi-pass':
            cmd = (
                f"gopass ls --flat | {base_cmd} -dmenu -p gopass | "
                f"PINENTRY_USER_DATA={self.screen.qt_env} xargs --no-run-if-empty gopass show -c"  # noqa
            )
        elif self.class_name == 'rofi-tab':
            cmd = f'$HOME/.config/i3/recency_switcher.py --menu="{base_cmd}"'
        elif self.class_name == 'rofi-ws-win':
            cmd = (
                '$HOME/.config/i3/recency_switcher.py --active-ws '
                f'--menu="{base_cmd} -p ws-window"'
            )
        elif self.class_name == 'rofi-font-aware-apps':
            cmd = f'$HOME/.config/i3/font_aware_menu.py --menu="{base_cmd}"'
        elif self.class_name == 'rofi-arch-init':
            yoffset = 25
            width = 35
            if self.screen.is_hidpi:
                yoffset *= 2
                width -= 1
            cmd = f"$HOME/.config/polybar/arch_dmenu.sh {self.font_size} {yoffset} {width}"
        return cmd


class ElectronApp(ROLApp):
    """Launch Electron apps."""

    def __init__(self, **kwargs):
        super().__init__(shell=True, **kwargs)

    def _build_cmd(self):
        cmd = self._raiseorlauch_cmd()
        # Note: we set gdk env variables so that gtk dialogs spawned by these
        # apps have correct font size
        cmd += f' -e "{self.screen.gdk_env}{self.class_name.lower()}'
        if (self.screen.is_hidpi and not self.screen.other_is_hidpi) or (
            self.screen.is_hidpi
            and self.screen.other_is_hidpi
            and self.class_name == 'Spotify'
        ):
            cmd += ' --force-device-scale-factor=2'

        if self.class_name == 'Brave':
            if not self.subcmd:
                cmd += ' --enable-features=VaapiVideoDecodeLinuxGL'
            else:
                cmd += ' --new-window --app=https://{url}'
                if self.subcmd == 'calendar':
                    cmd = cmd.format(url=f'{self.subcmd}.google.com/calendar/b/0/r')
                elif self.subcmd == 'meet':
                    cmd = cmd.format(url=f'{self.subcmd}.google.com')
                elif self.subcmd == 'clickup':
                    cmd = cmd.format(url=f'app.{self.subcmd}.com')
                elif self.subcmd == 'teams':
                    cmd = cmd.format(url=f'{self.subcmd}.live.com')

        cmd += '"'
        return cmd

    def _run_post_cmd(self):
        if (
            self.class_name == 'Brave' and self.mark not in self.screen.i3.get_marks()
        ):  # run this only on first open
            # Wait for focus
            sleep(1)

            # Hack to ensure calendar and clickup apps open corresponding workspace when
            # we have multiple monitors
            # FIXME: Find a general way to fix this
            if (
                self.subcmd == 'calendar' or self.subcmd == 'clickup'
            ) and self.screen.nr_monitors > 1:
                # We need extra waiting time
                sleep(1.5)
                self.screen.i3.command(
                    f'move container to workspace {self.ws}, workspace {self.ws}'
                )
                sh('xdotool key Super+Up')  # maximize

            # Ensure we have proper scaling
            sh('xdotool key Super+0')
            # If we have multiple monitors (i.e not only the primary laptop screen) the
            # brave window will live in a (potentially) non hidpi screen and be
            # scaled using the `--force-device..` flag so we need to rescale this window
            # in a hidpi screen using the zoom keybinding
            if (
                self.screen.is_hidpi
                and self.screen.nr_monitors > 1  # type: ignore
                and not self.screen.other_is_hidpi
            ):
                sh('xdotool key Super+u')


def run_app(application, workspace=None):
    """Run application adjusting font size if necessary."""
    APP_TYPES = {
        'electron': ElectronApp,
        'gtk': GTKApp,
        'qt': QTApp,
        'rofi': RofiApp,
        'rol': ROLApp,
        'rol_custom': ROLCustomApp,
        'tui': TUIApp,
    }
    app = APPS[application]
    app = APP_TYPES[app['type']](**app['args'])  # type: ignore
    if workspace is not None:
        app.ws = workspace  # type: ignore
    return app.launch()  # type: ignore


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('application')
    parser.add_argument('--workspace', '-W', required=False, type=str, default=None)
    parsed_args = parser.parse_args()

    run_app(parsed_args.application, parsed_args.workspace)
