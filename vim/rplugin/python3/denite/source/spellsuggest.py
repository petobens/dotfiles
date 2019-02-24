"""Show and replace spelling mistakes with Denite."""
from denite.kind.command import Kind as Command
from denite.source.base import Base


class Source(Base):
    """Denite source that gathers spell suggestions."""

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'spell_suggest'
        self.kind = Kind(vim)

    def gather_candidates(self, context):  # pylint:disable=W0613
        """Gather spell suggestions."""
        mispelled_word = self.vim.call('expand', '<cword>')
        spell_suggestions = self.vim.call('spellsuggest', mispelled_word)
        candidates = [
            {'word': w, 'index': i + 1} for i, w in enumerate(spell_suggestions)
        ]
        return candidates


class Kind(Command):
    """Denite kind that defines actions for spell_suggest source."""

    def __init__(self, vim):
        super().__init__(vim)
        self.vim = vim
        self.default_action = 'replace_misspelled'

    def action_replace_misspelled(self, context):
        """Replace misspelled word under the cursor with correctly spelled one."""
        index = context['targets'][0]['index']
        self.vim.command(f'silent normal! {index}z=')

    def action_replace_misspelled_all(self, context):
        """Replace all occurrences of misspelled word under the cursor."""
        index = context['targets'][0]['index']
        self.vim.command(f'silent normal! {index}z=')
        try:
            self.vim.command('spellrepall')
        except Exception:
            # spellrepall throws E753 when there are no more words to replace
            pass
