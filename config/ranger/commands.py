"""Ranger custom commands."""

import os
import re
import subprocess
import sys
from functools import partial
from pathlib import Path

from ranger.api.commands import Command
from ranger.ext.get_executables import get_executables

FZF_DEFAULT_OPTS = """\
--height=30 --inline-info --prompt="❯ " \
--bind=ctrl-space:toggle+up,ctrl-d:half-page-down,ctrl-u:half-page-up \
--bind=alt-v:toggle-preview,alt-j:preview-down,alt-k:preview-up \
--color=bg+:#282c34,bg:#24272e,fg:#abb2bf,fg+:#abb2bf,hl:#528bff,hl+:#528bff \
--color=prompt:#61afef,header:#566370,info:#5c6370,pointer:#c678dd \
--color=marker:#98c379,spinner:#e06c75,border:#282c34 \
"""


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
            f"--exclude .git {'--color=always ' if not only_dirs else ''}"
        )
        no_git_ignore = (
            True
            if self.arg(1) == '-d' and self.arg(2) or self.arg(1) == '-ngi'
            else False
        )
        if no_git_ignore:
            command += '--no-ignore-vcs '
        preview_cmd = 'bat --line-range :200 {2}'

        if self.arg(1) == '-d':
            preview_cmd = (
                'lsd -F --tree --depth 2 --color=always --icon=always {2} | head -200'
            )
        fzf_cmd = f"FZF_DEFAULT_OPTS='{FZF_DEFAULT_OPTS}' fzf"
        command += (
            f"| devicon-lookup {'--color' if not only_dirs else ''} | "
            f"{fzf_cmd} {'--ansi' if not only_dirs else ''} --preview '{preview_cmd}' +m"
        )

        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            out = stdout.decode('utf-8').rstrip('\n')[2:]  # due to devicons
            fzf_file = os.path.abspath(out)
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class fzf_parents(Command):
    """Show parent dirs with fzf."""

    def execute(self):
        """Execute the command."""
        selection = [str(f) for f in self.fm.thistab.get_selection()][0]
        path = Path(selection).parent
        parents = [str(path)]
        while str(path) != '/':
            path = path.parent
            parents.append(str(path))
        parents = '\\n'.join(parents)  # type: ignore

        preview_cmd = (
            'lsd -F --tree --depth 2 --color=always --icon=always {2} | head -200'
        )
        fzf_cmd = f"FZF_DEFAULT_OPTS='{FZF_DEFAULT_OPTS}' fzf"
        command = (
            f"printf '{parents}' | devicon-lookup | {fzf_cmd} --preview '{preview_cmd}'"
        )
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            out = stdout.decode('utf-8').rstrip('\n')[2:]  # due todevicons
            fzf_dir = os.path.abspath(out)
            self.fm.cd(fzf_dir)


class fzf_zoxide(Command):
    """Find a directory using fzf and zoxide."""

    def execute(self):
        """Execute the command."""
        command = 'zoxide query --list --score 2>&1'
        preview_cmd = (
            'lsd -F --tree --depth 2 --color=always --icon=always {3} | head -200'
        )
        fzf_cmd = f"FZF_DEFAULT_OPTS='{FZF_DEFAULT_OPTS}' fzf"
        command += f" | devicon-lookup -r '\\d +(.*)$' -s | {fzf_cmd} --no-sort --preview='{preview_cmd}'"

        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            fzf_dir = os.path.abspath(
                stdout.decode('utf-8').rstrip('\n').split(' ')[-1]
            )
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
        activate_script = "tell application \"Finder\" to set frontmost to true"
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
