# =============================================================================
#          File: command_history.py
#        Author: Pedro Ferrari
#       Created: 23 Feb 2017
# Last Modified: 24 Feb 2017
#   Description: Command history source for Denite
# =============================================================================
from .base import Base


class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'command_history'
        self.kind = 'command'

    def gather_candidates(self, context):
        hist_len = self.vim.eval("histnr('cmd')")
        history = list(
            filter(None, [
                self.vim.eval("histget('cmd', " + str(i) + ")")
                for i in range(1, hist_len + 1)
            ]))[::-1]
        return [{'action__command': ':' + i, 'word': i} for i in history]
