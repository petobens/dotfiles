# =============================================================================
#          File: commands.py
#        Author: Pedro Ferrari
#       Created: 06 May 2017
# Last Modified: 06 May 2017
#   Description: My ranger commands
# =============================================================================
import os
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


class show_files_in_finder(Command):
    """
    :show_files_in_finder

    Present selected files in finder
    """

    def execute(self):
        files = ",".join([
            '"{0}" as POSIX file'.format(file.path)
            for file in self.fm.thistab.get_selection()
        ])
        reveal_script = "tell application \"Finder\" to reveal {{{0}}}".format(
            files)
        activate_script = "tell application \"Finder\" to set frontmost to " \
            "true"
        script = "osascript -e '{0}' -e '{1}'".format(reveal_script,
                                                      activate_script)
        self.fm.notify(script)
        subprocess.check_output(
            ["osascript", "-e", reveal_script, "-e", activate_script])
