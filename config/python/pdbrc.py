"""pdbpp config."""

import pdb

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

# Palette (onedarkish)
white = '#abb2bf'
comment_grey = '#5c6370'
light_blue = '#61afef'
blue = '#528bff'
purple = '#c678dd'
green = '#98c379'
red = '#e06c75'
dark_yellow = '#d19a66'
yellow = '#e5c07b'
syntax_fg = white


class OneDarkish(Style):
    """OneDarkish pygments style."""

    styles = {
        Text: syntax_fg,
        Error: red,
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
        Name.Variable.Magic: red,
        Number: dark_yellow,
        Operator: purple,
        Operator.Word: f'{purple} nobold',
        Literal: green,
        Literal.String.Doc: f'{green} noitalic',
        Literal.String.Interpol: f'{light_blue} nobold',
        Literal.String.Escape: f'{light_blue} nobold',
        String: green,
    }


class Config(pdb.DefaultConfig):  # type: ignore
    """Actual pdbpp config."""

    prompt = '(Pdb++)> '
    sticky_by_default = True

    highlight = True
    use_pygments = True
    filename_color = '38;2;229;192;123'
    line_number_color = '38;2;99;109;131'
    current_line_color = '48;2;40;44;52'
    pygments_formatter_class = "pygments.formatters.TerminalTrueColorFormatter"
    pygments_formatter_kwargs = {"style": OneDarkish}

    def setup(self, pdb):
        """Override PDB++ mappings."""
        pdb_class = pdb.__class__
        pdb_class.do_l = pdb_class.do_longlist
        pdb_class.do_ll = pdb_class.do_list
        pdb_class.do_st = pdb_class.do_sticky
        pdb_class.do_ev = pdb_class.do_edit
        pdb_class.do_ip = pdb_class.do_interact
        pdb_class.do_gf = pdb_class.do_frame
