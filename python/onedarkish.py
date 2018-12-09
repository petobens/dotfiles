from pygments.style import Style
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
)

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


class OnedarkishStyle(Style):
    default_style = ''

    styles = {
        Text: syntax_fg,
        Error: red,
        Comment: comment_grey,
        Keyword: f'{purple} nobold',
        Keyword.Constant: green,
        Keyword.Namespace: purple,
        Name.Namespace: f'{syntax_fg} nobold',
        Name.Builtin: yellow,
        Name.Function: light_blue,
        Name.Class: f'{light_blue} nobold',
        Name.Decorator: light_blue,
        Name.Exception: yellow,
        Number: dark_yellow,
        Operator: purple,
        Operator.Word: f'{purple} nobold',
        Literal: green,
        Literal.String.Doc: f'{green} noitalic',
        Literal.String.Interpol: f'{light_blue} nobold',
        Literal.String.Escape: f'{light_blue} nobold',
        String: green,
    }
