"""Parent directory source for Denite."""
from pathlib import Path

from denite.source.base import Base


class Source(Base):
    """Gather parent directories of the cwd."""

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'parent_dirs'
        self.kind = 'directory'
        self.default_action = 'narrow'

    def gather_candidates(self, context):  # pylint:disable=W0613
        """Gather parent directories."""
        path = Path(self.vim.call('getcwd'))
        parents = [str(path)]
        while str(path) != '/':
            path = path.parent
            parents.append(str(path))
        candidates = [{'word': d, 'action__path': d} for d in parents]
        return candidates
