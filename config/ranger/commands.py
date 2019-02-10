"""Ranger custom commands."""
import os
import re
import subprocess
import sys
from functools import partial

from ranger.api.commands import Command
from ranger.ext.get_executables import get_executables


class fzf_select(Command):
    """Find a file or directory using fzf and fd.

    Add -d to select only dirs and/or -ngi to ignore gitignore.
    """

    def execute(self):
        """Execute the command."""
        fd_cmd = 'fd'
        if fd_cmd not in get_executables():
            self.fm.notify(f"Couldn't find {fd_cmd} on the PATH.", bad=True)
            return

        only_dirs = True if self.arg(1) == '-d' else False
        command = (
            f"{fd_cmd} --type {'d' if only_dirs else 'f'} --hidden --follow "
            '--exclude .git '
        )
        no_git_ignore = (
            True
            if self.arg(1) == '-d' and self.arg(2) or self.arg(1) == '-ngi'
            else False
        )
        if no_git_ignore:
            command += '--no-ignore-vcs '
        command += '| fzf +m'

        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.decode('utf-8').rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class fzf_z(Command):
    """Find a directory using fzf and z."""

    def execute(self):
        """Execute the command."""
        z_sh = None
        if sys.platform == 'darwin':
            z_sh = '/usr/local/etc/profile.d/z.sh'
        else:
            z_sh = '/home/pedro/.local/bin/z.sh'
        if not os.path.isfile(z_sh) or z_sh is None:
            return
        command = (
            f'. {z_sh} &&  '
            '_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse '
            '--inline-info +s --tac --query "${*##-* }" '
            '| sed "s/^[0-9,.]* *//"'
        )

        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            fzf_dir = os.path.abspath(stdout.decode('utf-8').rstrip('\n'))
            self.fm.cd(fzf_dir)


class show_files_in_finder(Command):
    """Present selected files in finder."""

    def execute(self):
        """Execute the command."""
        if sys.platform != 'darwin':
            return
        files = ",".join(
            [
                '"{0}" as POSIX file'.format(file.path)
                for file in self.fm.thistab.get_selection()
            ]
        )
        reveal_script = "tell application \"Finder\" to reveal {{{0}}}".format(files)
        activate_script = "tell application \"Finder\" to set frontmost to " "true"
        script = "osascript -e '{0}' -e '{1}'".format(reveal_script, activate_script)
        self.fm.notify(script)
        subprocess.check_output(
            ["osascript", "-e", reveal_script, "-e", activate_script]
        )


class trash_with_confirmation(Command):
    """Send to trash asking for confirmation first."""

    def execute(self):
        """Execute the command."""
        trash_cmd = 'trash-put'
        if trash_cmd not in get_executables():
            self.fm.notify(f"Couldn't find {trash_cmd} on the PATH.", bad=True)
            return

        files = [f.relative_path for f in self.fm.thistab.get_selection()]
        if not files:
            self.fm.notify("No file selected for deletion", bad=True)
            return
        self.fm.ui.console.ask(
            f"Confirm deletion of: {files} (y/N)",
            partial(self._question_callback, files),
            ('n', 'N', 'y', 'Y'),
        )

    def _question_callback(self, files, answer):
        if answer == 'y' or answer == 'Y':
            for f in files:
                file = re.escape(f)
                cmd = f'trash-put {file}'
                trash_cli = self.fm.execute_command(cmd, stdout=subprocess.PIPE)
                trash_cli.communicate()
