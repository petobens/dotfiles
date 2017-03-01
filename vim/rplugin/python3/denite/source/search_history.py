# =============================================================================
#          File: search.py
#        Author: Pedro Ferrari
#       Created: 04 Feb 2017
# Last Modified: 01 Mar 2017
#   Description: Search history file for Denite
# =============================================================================
from .base import Base


class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'search_history'
        self.kind = 'command'

    def gather_candidates(self, context):
        hist_len = self.vim.eval("histnr('search')")
        history = list(
            filter(None, [
                self.vim.eval("histget('search', " + str(i) + ")")
                for i in range(1, hist_len + 1)
            ]))[::-1]
        self.vim.command('set hlsearch')
        return [{'action__command': '/' + i, 'word': i} for i in history]
