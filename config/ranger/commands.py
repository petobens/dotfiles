import os
import subprocess
import sys
from functools import partial

from ranger.api.commands import Command
from ranger.ext.get_executables import get_executables


class fzf_select(Command):
    """
    :fzf_select

    Find a file or directory using fzf and fd.

    With a prefix argument select only directories.
    """

    def execute(self):
        fd_cmd = 'fd'
        if fd_cmd not in get_executables():
            self.fm.notify(f"Couldn't find {fd_cmd} on the PATH.", bad=True)
            return

        only_dirs = True if self.arg(1) else False
        command = (
            f"{fd_cmd}{' --type d' if only_dirs else ''} --hidden --follow "
            "--exclude .git | fzf +m"
        )

        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.decode('utf-8').rstrip('\n'))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class fzf_z(Command):
    """
    :fzf_z

    Find a directory using fzf and z.
    """

    def execute(self):
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
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_dir = os.path.abspath(stdout.decode('utf-8').rstrip('\n'))
            self.fm.cd(fzf_dir)


class show_files_in_finder(Command):
    """
    :show_files_in_finder

    Present selected files in finder
    """

    def execute(self):
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
    def execute(self):
        fd_cmd = 'trash-put'
        if fd_cmd not in get_executables():
            self.fm.notify(f"Couldn't find {fd_cmd} on the PATH.", bad=True)
            return

        if self.rest(1):
            self.fm.notify(f"Arg: {self.rest(1)}", bad=True)
            file = self.rest(1)
        else:
            self.fm.notify("No file selected for deletion", bad=True)
            return
        self.fm.ui.console.ask(
            f"Confirm deletion of: {file} (y/N)",
            partial(self._question_callback, file),
            ('n', 'N', 'y', 'Y'),
        )

    def _question_callback(self, file, answer):
        if answer == 'y' or answer == 'Y':
            cmd = f'trash-put {file}'
            trash_cli = self.fm.execute_command(cmd, stdout=subprocess.PIPE)
            stdout, stderr = trash_cli.communicate()
