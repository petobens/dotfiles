#!/usr/bin/env python3

"""Font Aware Menu with Rofi."""

from subprocess import check_output

from font_aware_launcher import run_app

# TODO: Should we open in a specific workspace?
APPS = {
    'Alacritty': {
        'cmd': 'quickterm',
        'icon': 'Alacritty',
        'desc': 'Terminal',
    },
    'Brave': {
        'cmd': 'brave',
        'icon': 'brave',
        'desc': 'Web Browser',
    },
    'Calculator': {
        'cmd': 'numbers',
        'icon': 'calc',
        'desc': 'IPython Based Calculator',
    },
    'Calendar': {
        'cmd': 'calendar',
        'icon': 'google-agenda',
        'desc': 'Google Calendar',
    },
    'Clickup': {
        'cmd': 'clickup',
        'icon': 'tracker',
        'desc': 'Project Management App',
    },
    'Color Picker': {'cmd': 'color-picker', 'icon': 'gcolor3'},
    'Connman Settings': {
        'cmd': 'connman',
        'icon': 'wifi-radar',
        'desc': 'Network Settings',
    },
    'Document Scanner': {'cmd': 'scanner', 'icon': 'org.gnome.SimpleScan'},
    'Microsoft Edge': {
        'cmd': 'edge',
        'icon': 'microsoft-edge',
        'desc': 'Microsoft Edge Web Browser',
    },
    'Firefox': {'cmd': 'firefox', 'icon': 'firefox', 'desc': 'Web Browser'},
    'Fonts': {'cmd': 'gnome-font', 'icon': 'org.gnome.font-viewer'},
    'GlobalProtect VPN': {'cmd': 'globalprotect-vpn', 'icon': 'network-vpn'},
    'Htop': {
        'cmd': 'htop',
        'icon': 'htop',
        'desc': 'Process Viewer',
    },
    'Kitty': {'cmd': 'kitty', 'icon': 'kitty', 'desc': 'Terminal Emulator'},
    'Kodi': {'cmd': 'kodi', 'icon': 'kodi', 'desc': 'Media Center'},
    'Mailspring': {'cmd': 'mailspring', 'icon': 'mailspring', 'desc': 'Mail Client'},
    'Meet': {'cmd': 'meet', 'icon': 'google-meet', 'desc': 'Google Meet'},
    'Microsoft Teams': {'cmd': 'teams', 'icon': 'teams'},
    'OBS Studio': {
        'cmd': 'obs',
        'icon': 'obs',
        'desc': 'Streaming/Recording Software',
        'ws': 4,
    },
    'OnlyOffice': {
        'cmd': 'onlyoffice',
        'icon': 'onlyoffice-desktopeditors',
        'desc': 'Office Suite',
    },
    'Peek': {'cmd': 'peek', 'icon': 'peek', 'desc': 'Animated GIF Recorder'},
    'Power Manager': {'cmd': 'power-manager', 'icon': 'xfce4-power-manager-settings'},
    'PulseAudio Volume Control': {
        'cmd': 'pavucontrol',
        'icon': 'pavucontrol',
        'desc': 'Audio Control',
    },
    'Ranger': {
        'cmd': 'ranger',
        'icon': 'xfce-filemanager',
        'desc': 'File Manager',
    },
    'Slack': {'cmd': 'slack', 'icon': 'slack', 'desc': 'Internet Messaging'},
    'Spotify': {'cmd': 'spotify', 'icon': 'spotify', 'desc': 'Music Player'},
    'Task Manager': {
        'cmd': 'prockiller',
        'icon': 'view-process-all',
        'desc': 'FZF Based Process Killer',
    },
    'Transmission': {
        'cmd': 'transmission',
        'icon': 'transmission',
        'desc': 'BitTorrent Client',
    },
    'Trash': {
        'cmd': 'trash',
        'icon': 'user-trash',
        'desc': 'Show Trash',
    },
    'vimiv': {'cmd': 'vimiv', 'icon': 'image-viewer', 'desc': 'Image Viewer'},
    'Visual Studio Code': {'cmd': 'vscode', 'icon': 'code', 'desc': 'Text Editor'},
    'Zathura': {'cmd': 'zathura', 'icon': 'zathura', 'desc': 'PDF Viewer'},
    'Zoom': {'cmd': 'zoom', 'icon': 'Zoom'},
}


def font_aware_menu(cmd_menu):
    """Font aware menu."""
    candidates = ''
    for app_name, info in APPS.items():
        icon_str = rf'\0icon\x1f{info.get("icon")}'
        candidate = f'{app_name}'
        description = info.get('desc')
        if description:
            candidate += (
                f"<span color='#5f636f' size='small'> <i>({description})</i></span>"
            )
        candidates += rf"{candidate}{icon_str}\n"

    menu_cmd = rf'echo -e "{candidates[:-2]}" | '  # strips trailing newline
    menu_cmd += rf'{cmd_menu} -dmenu -p apps -i -markup-rows'
    selected = check_output(menu_cmd, shell=True).decode().strip()
    selected = selected.split('<')[0].strip()  # Remove the description
    selected = APPS[selected]  # type: ignore
    run_app(selected.get('cmd'), selected.get('ws'))  # type: ignore


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--menu', default='rofi', help='The menu command to run.')
    args = parser.parse_args()
    font_aware_menu(args.menu)
