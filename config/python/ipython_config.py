"""My ipython config."""

# pylint:disable=W0212

import subprocess
import sys
from pathlib import Path

import IPython
import IPython.terminal.prompts as prompts
import prompt_toolkit
from prompt_toolkit.application import get_app
from prompt_toolkit.application.current import get_app as get_current_app
from prompt_toolkit.key_binding.vi_state import InputMode, ViState
from prompt_toolkit.styles.pygments import pygments_token_to_classname
from prompt_toolkit.styles.style import Style
from pygments.token import (
    Comment,
    Error,
    Keyword,
    Literal,
    Name,
    Number,
    Operator,
    String,
    Text,
    Token,
)

c = get_config()  # type: ignore # noqa # pylint:disable=E0602

# Options
c.TerminalInteractiveShell.true_color = True
c.TerminalInteractiveShell.editing_mode = 'vi'
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalIPythonApp.display_banner = False


def get_input_mode(self):
    """Get input mode and reduce input flush timeout."""
    # https://github.com/prompt-toolkit/python-prompt-toolkit/issues/192#issuecomment-557800620
    app = get_current_app()
    app.ttimeoutlen = 0.01
    app.timeoutlen = 0.2
    return self._input_mode


def set_input_mode(self, mode):
    """Change cursor shape relative to vi mode.

    See: https://github.com/jonathanslenders/python-prompt-toolkit/issues/192
    """
    shape = {InputMode.NAVIGATION: 2, InputMode.REPLACE: 4}.get(mode, 6)
    raw = '\x1b[{} q'.format(shape)
    if hasattr(sys.stdout, '_cli'):
        out = sys.stdout._cli.output.write_raw  # type: ignore # pylint:disable=E1101
    else:
        out = sys.stdout.write
    out(raw)
    sys.stdout.flush()
    self._input_mode = mode


ViState._input_mode = InputMode.INSERT
ViState.input_mode = property(get_input_mode, set_input_mode)


def _get_branch():
    try:
        branch = '  ' + (
            subprocess.check_output(
                "git branch --show-current", shell=True, stderr=subprocess.DEVNULL
            )
            .decode("utf-8")
            .replace("\n", "")
        )

    except BaseException:
        branch = ''
    return branch


class MyPrompt(prompts.Prompts):
    """Custom prompt with vi mode indicator."""

    def in_prompt_tokens(self):
        """Return in prompt."""
        mode = 'I' if get_app().vi_state.input_mode == InputMode.INSERT else 'N'
        branch = _get_branch()

        inprompt = []
        inprompt.append(
            (Token.OutPrompt if mode == 'I' else Token.Generic.Prompt, f' {mode} ')
        )
        inprompt.append(
            (Token.Generic.Emph if mode == 'I' else Token.Generic.Strong, " ")
        )
        inprompt.append(
            (Token.Generic.Deleted, f" [{str(self.shell.execution_count)}] ")
        )
        inprompt.append((Token.OutPromptNum if branch else Token.Generic.Inserted, ""))
        if branch:
            inprompt.append((Token.Prompt, f"{branch} "))
            inprompt.append((Token.PromptNum, ""))
        inprompt.append((Token.Generic.Heading, f'  {Path().absolute().stem} '))
        inprompt.append(
            (
                (
                    Token.Generic.Subheading
                    if self.shell.last_execution_succeeded
                    else Token.Generic.Output
                ),
                " ",
            )
        )
        if not self.shell.last_execution_succeeded:
            inprompt.append((Token.Generic.Error, " "))
            inprompt.append((Token.Generic.Traceback, " "))
        return inprompt

    def continuation_prompt_tokens(self, width=None):
        """Return continuation prompt."""
        if width is None:
            width = self._width()
        return [
            (Token.Generic.EmphStrong, (' ' * (width - 2)) + '| '),
        ]

    def out_prompt_tokens(self):
        """Return out prompt."""
        return []


c.TerminalInteractiveShell.prompts_class = MyPrompt


# Fix completion highlighting as per https://github.com/ipython/ipython/issues/11526
def my_style_from_pygments_dict(pygments_dict):
    """Monkey patch prompt toolkit style function to fix completion colors."""
    pygments_style = []
    for token, style in pygments_dict.items():
        if isinstance(token, str):
            pygments_style.append((token, style))
        else:
            pygments_style.append((pygments_token_to_classname(token), style))
    return Style(pygments_style)


prompt_toolkit.styles.pygments.style_from_pygments_dict = my_style_from_pygments_dict
IPython.terminal.interactiveshell.style_from_pygments_dict = my_style_from_pygments_dict


# Palette (onedarkish)
white = '#abb2bf'
mono_2 = '#828997'
comment_grey = '#5c6370'
mono_4 = '#4b5263'
cyan = '#56b6c2'
light_blue = '#61afef'
blue = '#528bff'
purple = '#c678dd'
green = '#98c379'
red = '#e06c75'
dark_red = '#be5046'
dark_yellow = '#d19a66'
yellow = '#e5c07b'
black = '#24272e'
cursor_grey = '#282c34'
gutter_fg_grey = '#636d83'
special_grey = '#3b4048'
visual_grey = '#3e4452'
pmenu = '#333841'
syntax_fg = white
syntax_fold_bg = comment_grey
count_bg = '#d0d0d0'
count_fg = '#303030'

# See:
# https://github.com/prompt-toolkit/python-prompt-toolkit/blob/master/src/prompt_toolkit/styles/defaults.py # noqa
c.TerminalInteractiveShell.highlighting_style_overrides = {
    Text: syntax_fg,
    Error: f'{red} bold',
    Comment: comment_grey,
    Keyword: f'{purple} nobold',
    Keyword.Constant: green,
    Keyword.Namespace: purple,
    Name.Namespace: f'{red} nobold',
    Name.Builtin: yellow,
    Name.Function: light_blue,
    Name.Class: f'{yellow} nobold',
    Name.Decorator: blue,
    Name.Exception: yellow,
    Name.Variable.Magic: red,  # dunder methods
    Number: dark_yellow,
    Operator: purple,
    Operator.Word: f'{purple} nobold',
    Literal: green,
    Literal.String.Doc: f'{green} noitalic',
    Literal.String.Interpol: f'{light_blue} nobold',
    Literal.String.Escape: f'{light_blue} nobold',
    String: green,
    Token.MatchingBracket.Other: blue,
    # Prompt stuff (we abuse the token class for this)
    Token.OutPrompt: f'bg:{light_blue} {black} bold',  # insert mode
    Token.Generic.Prompt: f'bg:{green} {black} bold',  # normal mode
    Token.Generic.Emph: f'bg:{count_bg} {light_blue}',  # insert righ separator
    Token.Generic.Strong: f'bg:{count_bg} {green}',  # normal right separator
    Token.Generic.Deleted: f'bg:{count_bg} {count_fg} bold',  # execution count
    Token.OutPromptNum: f'bg:{special_grey} {count_bg}',  # execution right separator w/branch
    Token.Generic.Inserted: f'bg:{cursor_grey} {count_bg}',  # execution right separator no branch
    Token.Prompt: f'bg:{special_grey} {white}',  # branch
    Token.PromptNum: f'bg:{cursor_grey} {special_grey}',  # branch right separator
    Token.Generic.Heading: f'bg:{cursor_grey} {mono_2}',  # filepath
    Token.Generic.Subheading: f'bg:{black} {cursor_grey}',  # file (non-error) separator
    Token.Generic.Output: f'bg:{red} {cursor_grey}',  # error separator
    Token.Generic.Error: f'bg:{red} {black}',  # error
    Token.Generic.Traceback: f'bg:{black} {red}',  # error final
    Token.Generic.EmphStrong: f'bg:{black} {special_grey}',  # continuation prompt
    # Completion
    'completion-menu': f'bg:{pmenu} {white}',
    'completion-menu.completion.current': f'bg:{light_blue} {black}',
    'completion-menu.completion': f'bg:{pmenu} {white}',
    'completion-menu.meta.completion.current': f'bg:{light_blue} {black}',
    'completion-menu.meta.completion': f'bg:{pmenu} {white}',
    'completion-menu.multi-column-meta': f'bg:{pmenu} {white}',
}


# Run this code upon starting the shell
c.InteractiveShellApp.exec_lines = """
import numpy as np

def load_extension_silently(extension):
    from IPython import get_ipython

    ip = get_ipython()
    try:
        ip.extension_manager.load_extension(extension)
    except ImportError:
        pass

load_extension_silently('ipython_ctrlr_fzf')
"""


# Define some shortcuts
custom_keybinds = [
    # Note that c-f accepts the (f)ull/(f)orward suggestion
    {'command': 'IPython:auto_suggest.accept_token', 'new_keys': ['c-t']},
]
c.TerminalInteractiveShell.shortcuts = custom_keybinds
