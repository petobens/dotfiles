"""Launch pgcli with OneDarkish colors and custom Vi bindings."""

from pgcli import main
from pgcli.key_bindings import pgcli_bindings
from prompt_toolkit.filters import has_completions, has_selection, vi_insert_mode
from prompt_toolkit.key_binding import KeyBindings, KeyPressEvent
from prompt_toolkit.key_binding.vi_state import InputMode


def configure_prompt(pgcli: main.PGCli) -> KeyBindings:
    """Apply syntax colors and add completion and Vi shortcuts."""
    # Table-output styling is already built and does not accept pygments keys
    pgcli.cli_style.update(pgcli.config['syntax_colors'])
    bindings = pgcli_bindings(pgcli)

    @bindings.add('c-n', filter=has_completions & ~has_selection)
    def next_completion(event: KeyPressEvent) -> None:
        event.current_buffer.complete_next(count=event.arg)

    @bindings.add('c-p', filter=has_completions & ~has_selection)
    def previous_completion(event: KeyPressEvent) -> None:
        event.current_buffer.complete_previous(count=event.arg)

    @bindings.add('j', 'j', filter=vi_insert_mode)
    def normal_mode(event: KeyPressEvent) -> None:
        event.current_buffer.complete_state = None
        event.current_buffer.cursor_left()
        event.app.vi_state.input_mode = InputMode.NAVIGATION

    @bindings.add('c-o', filter=vi_insert_mode)
    def execute_query(event: KeyPressEvent) -> None:
        event.current_buffer.validate_and_handle()

    return bindings


if __name__ == '__main__':
    main.pgcli_bindings = configure_prompt
    main.cli()
