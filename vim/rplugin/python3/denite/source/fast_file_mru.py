"""Slightly faster version of neomru source."""

from pathlib import Path

from denite.base.source import Base


class Source(Base):
    """Gather files from neomru a bit faster than default version."""

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'fast_file_mru'
        self.kind = 'file'

    def gather_candidates(self, context):  # pylint:disable=W0613
        """Gather files from neomru."""
        home_dir = str(Path.home())
        files = self.vim.call('neomru#_gather_file_candidates')
        files = [f.replace(home_dir, '~') for f in files]
        return [{'word': x, 'action__path': x} for x in files]
