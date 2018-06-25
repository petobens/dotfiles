import sys

from operator import attrgetter

import IPython.terminal.prompts as prompts

from pygments.token import (
    Comment, Error, Keyword, Literal, Name, Number, Operator, String, Text,
    Token
)
from prompt_toolkit.key_binding.vi_state import InputMode, ViState

c = get_config()  # noqa

# Options
c.TerminalInteractiveShell.true_color = True
c.TerminalInteractiveShell.editing_mode = 'vi'
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalIPythonApp.display_banner = False


# Change cursor shape depending on mode
# https://github.com/jonathanslenders/python-prompt-toolkit/issues/192
def set_input_mode(self, mode):
    shape = {InputMode.NAVIGATION: 2, InputMode.REPLACE: 4}.get(mode, 6)
    raw = u'\x1b[{} q'.format(shape)
    if hasattr(sys.stdout, '_cli'):
        out = sys.stdout._cli.output.write_raw
    else:
        out = sys.stdout.write
    out(raw)
    sys.stdout.flush()
    self._input_mode = mode


ViState._input_mode = InputMode.INSERT
ViState.input_mode = property(attrgetter('_input_mode'), set_input_mode)


class MyPrompt(prompts.Prompts):
    """Custom prompt with vi mode indicator"""

    def in_prompt_tokens(self, cli=None):
        mode = 'I' if cli.vi_state.input_mode == InputMode.INSERT else 'N'
        return [
            (prompts.Token.Prompt, f'({mode})['),
            (prompts.Token.PromptNum, str(self.shell.execution_count)),
            (prompts.Token.Prompt, ']>> '),
        ]

    def out_prompt_tokens(self):
        return []


c.TerminalInteractiveShell.prompts_class = MyPrompt

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

c.TerminalInteractiveShell.highlighting_style_overrides = {
    Text: syntax_fg,
    Error: red,
    Comment: comment_grey,
    Keyword: purple,
    Keyword.Constant: green,
    Keyword.Namespace: purple,
    Name.Namespace: syntax_fg,
    Name.Builtin: red,
    Name.Function: light_blue,
    Name.Class: light_blue,
    Name.Decorator: light_blue,
    Name.Exception: yellow,
    Name.Variable.Magic: red,  # dunder methods
    Number: dark_yellow,
    Operator: purple,
    Operator.Word: green,
    Literal: green,
    String: green,
    Token.Prompt: green,
    Token.PromptNum: f'{green} bold',
    Token.OutPrompt: blue,
    Token.OutPromptNum: f'{blue} bold',
    Token.Menu.Completions.Completion: f'bg:{pmenu} {syntax_fg}',
    Token.Menu.Completions.Completion.Current: f'bg:{light_blue} {black}',
    Token.MatchingBracket.Other: blue,
}
