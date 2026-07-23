"""My ipython startup settings."""
# pylint:disable=W0108

from IPython import get_ipython
from prompt_toolkit.filters import emacs_insert_mode, vi_insert_mode
from prompt_toolkit.key_binding.bindings.named_commands import (
    backward_kill_word,
    backward_word,
    beginning_of_line,
    end_of_line,
    forward_word,
    unix_line_discard,
)
from prompt_toolkit.key_binding.key_processor import KeyPress
from prompt_toolkit.keys import Keys

r = get_ipython().pt_app.key_bindings


def vi_movement_mode(event):
    """Exit vi mode."""
    event.cli.key_processor.feed(KeyPress(Keys.Escape))


# Insert mode mappings (note that we also define some keybinds in startup file)
insert_mode = vi_insert_mode | emacs_insert_mode
r.add_binding('j', 'j', filter=vi_insert_mode, eager=True)(
    lambda ev: vi_movement_mode(ev)
)
r.add_binding(Keys.Escape, 'f', filter=insert_mode)(lambda ev: forward_word(ev))
r.add_binding(Keys.Escape, 'b', filter=insert_mode)(lambda ev: backward_word(ev))
r.add_binding(Keys.Escape, 'x', filter=insert_mode)(lambda ev: backward_kill_word(ev))
r.add_binding(Keys.ControlA, filter=insert_mode)(lambda ev: beginning_of_line(ev))
r.add_binding(Keys.ControlE, filter=insert_mode)(lambda ev: end_of_line(ev))
r.add_binding(Keys.ControlX, filter=insert_mode)(lambda ev: unix_line_discard(ev))

# Normal mode mappings
r.add_binding('H', filter=~insert_mode)(lambda ev: beginning_of_line(ev))
r.add_binding('L', filter=~insert_mode)(lambda ev: end_of_line(ev))
