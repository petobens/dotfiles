import os
import sys
import subprocess

from ranger.api.commands import Command


class fzf_select(Command):
    """
    :fzf_select

    Find a file using fzf.

    With a prefix argument select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        if self.quantifier:
            # match only directories
            command = "find -L . \( -path '*/\.*' -o -fstype 'dev' -o " \
                "-fstype 'proc' \) -prune -o -type d -print 2> /dev/null | " \
                "sed 1d | cut -b3- | fzf +m"

        else:
            # match files and directories
            command = "find -L . \( -path '*/\.*' -o -fstype 'dev' -o " \
                "-fstype 'proc' \) -prune -o -print 2> /dev/null | sed 1d | " \
                "cut -b3- | fzf +m"

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
            z_sh = '/usr/share/z/z.sh'
        if not os.path.isfile(z_sh) or z_sh is None:
            return
        command = f'. {z_sh} &&  ' \
            '_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse ' \
            '--inline-info +s --tac --query "${*##-* }" ' \
            '| sed "s/^[0-9,.]* *//"'

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
        files = ",".join(
            [
                '"{0}" as POSIX file'.format(file.path)
                for file in self.fm.thistab.get_selection()
            ]
        )
        reveal_script = "tell application \"Finder\" to reveal {{{0}}}".format(
            files
        )
        activate_script = "tell application \"Finder\" to set frontmost to " \
            "true"
        script = "osascript -e '{0}' -e '{1}'".format(
            reveal_script, activate_script
        )
        self.fm.notify(script)
        subprocess.check_output(
            ["osascript", "-e", reveal_script, "-e", activate_script]
        )
