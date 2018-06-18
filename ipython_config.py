# See: https://github.com/wilywampa/vimconfig/blob/master/misc/python/ipython_config.py
from pygments.token import (
    Comment, Error, Keyword, Literal, Name, Number, Operator, String, Text,
    Token
)

c = get_config()  # noqa

c.TerminalInteractiveShell.true_color = True
c.TerminalInteractiveShell.editing_mode = 'vi'

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
    Token.OutPrompt: dark_red,
    Token.OutPromptNum: f'{dark_red} bold',
    Token.Menu.Completions.Completion: f'bg:{pmenu} {syntax_fg}',
    Token.Menu.Completions.Completion.Current: f'bg:{light_blue} {black}',
    Token.MatchingBracket.Other: blue,
}
