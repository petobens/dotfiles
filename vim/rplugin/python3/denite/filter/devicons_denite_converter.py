"""Filter to prepend devicons to denite candidates."""
from os.path import isdir

from denite.base.filter import Base


class Filter(Base):
    """Prepend devicons to denite candidate files."""

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'denite_devicons_converter'

    def filter(self, context):
        """Parse candidates and prepend devicons."""
        for i, candidate in enumerate(context['candidates']):
            if i > 60:
                break

            if 'word' in candidate and 'action__path' in candidate:
                filename = candidate['action__path']
            elif 'bufnr' in candidate:
                bufname = self.vim.funcs.bufname(candidate['bufnr'])
                filename = self.vim.funcs.fnamemodify(bufname, ':p:t')

            icon = self.vim.funcs.WebDevIconsGetFileTypeSymbol(
                filename, isdir(filename)
            )

            # Customize output format if not done already
            if icon not in candidate.get('abbr', '')[:10]:
                candidate[
                    'abbr'
                ] = f" {icon} {candidate.get('abbr', candidate['word'])}"

        return context['candidates']
