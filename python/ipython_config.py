"""My ipython config."""

# pylint:disable=W0212

import sys

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


class MyPrompt(prompts.Prompts):
    """Custom prompt with vi mode indicator."""

    def in_prompt_tokens(self):
        """Return in prompt."""
        mode = 'I' if get_app().vi_state.input_mode == InputMode.INSERT else 'N'
        return [
            (prompts.Token.Prompt, f'({mode})['),
            (prompts.Token.PromptNum, str(self.shell.execution_count)),
            (prompts.Token.Prompt, ']>> '),
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

# See:
# https://github.com/prompt-toolkit/python-prompt-toolkit/blob/master/prompt_toolkit/styles/defaults.py # noqa
c.TerminalInteractiveShell.highlighting_style_overrides = {
    Text: syntax_fg,
    Error: red,
    Comment: comment_grey,
    Keyword: f'{purple} nobold',
    Keyword.Constant: green,
    Keyword.Namespace: purple,
    Name.Namespace: f'{syntax_fg} nobold',
    Name.Builtin: red,
    Name.Function: light_blue,
    Name.Class: f'{light_blue} nobold',
    Name.Decorator: light_blue,
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
    Token.Prompt: green,
    Token.PromptNum: f'{green} bold',
    Token.OutPrompt: blue,
    Token.OutPromptNum: f'{blue} bold',
    Token.MatchingBracket.Other: blue,
    'completion-menu': f'bg:{pmenu} {white}',
    'completion-menu.completion.current': f'bg:{light_blue} {black}',
    'completion-menu.completion': f'bg:{pmenu} {white}',
    'completion-menu.meta.completion.current': f'bg:{light_blue} {black}',
    'completion-menu.meta.completion': f'bg:{pmenu} {white}',
    'completion-menu.multi-column-meta': f'bg:{pmenu} {white}',
}


# Always import some modules
c.InteractiveShellApp.exec_lines = ['import numpy as np']
# And load extensions
c.InteractiveShellApp.extensions = ['ipython_ctrlr_fzf']

# Define some shortcuts
custom_keybinds = [
    # Note that c-f accepts the (f)ull/(f)orward suggestion
    {'command': 'IPython:auto_suggest.accept_token', 'new_keys': ['c-t']},
]
c.TerminalInteractiveShell.shortcuts = custom_keybinds
