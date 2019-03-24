"""Parent directory source for Denite."""
from pathlib import Path

from denite.base.source import Base
from denite.util import abspath


class Source(Base):
    """Gather parent directories of the cwd or input directory."""

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'parent_dirs'
        self.kind = 'directory'
        self.default_action = 'narrow'

    def gather_candidates(self, context):
        """Gather parent directories."""
        base_path = self.vim.call('getcwd')
        if context['args']:
            base_path = abspath(self.vim, context['args'][0])
        path = Path(base_path)

        parents = [str(path)]
        while str(path) != '/':
            path = path.parent
            parents.append(str(path))
        candidates = [{'word': d, 'action__path': d} for d in parents]
        return candidates
