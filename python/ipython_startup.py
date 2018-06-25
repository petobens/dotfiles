from IPython import get_ipython
from prompt_toolkit.keys import Keys
from prompt_toolkit.filters import EmacsInsertMode, ViInsertMode
from prompt_toolkit.key_binding.vi_state import InputMode
from prompt_toolkit.key_binding.bindings.named_commands import (
    backward_word, beginning_of_line, end_of_line, forward_word
)

ip = get_ipython()
r = get_ipython().pt_cli.application.key_bindings_registry


# https://github.com/jonathanslenders/python-prompt-toolkit/issues/425
def vi_movement_mode(event):
    buffer = event.current_buffer
    vi_state = event.cli.vi_state
    vi_state.reset(InputMode.NAVIGATION)
    if bool(buffer.selection_state):
        buffer.exit_selection()


# Insert mode mappings
vi_insert_mode = ViInsertMode()
insert_mode = vi_insert_mode | EmacsInsertMode()
r.add_binding(
    'j', 'j', filter=vi_insert_mode, eager=True
)(lambda ev: vi_movement_mode(ev))
r.add_binding(
    Keys.Escape, 'f', filter=insert_mode
)(lambda ev: forward_word(ev))
r.add_binding(
    Keys.Escape, 'b', filter=insert_mode
)(lambda ev: backward_word(ev))
r.add_binding(
    Keys.ControlA, filter=insert_mode
)(lambda ev: beginning_of_line(ev))
r.add_binding(Keys.ControlE, filter=insert_mode)(lambda ev: end_of_line(ev))

# Normal mode mappings
r.add_binding('H', filter=~insert_mode)(lambda ev: beginning_of_line(ev))
r.add_binding('L', filter=~insert_mode)(lambda ev: end_of_line(ev))
