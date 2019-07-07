"""Converter to prepend devicons to denite candidates."""
from pathlib import Path

from denite.base.filter import Base

DEFAULT_ICON = ''
DIR_ICON = ''
FILENAMES = {
    '.bash_profile': '',
    '.bashrc': '',
    '.gitignore': '',
    '.vimrc': '',
    'dockerfile': '',
    'license': '',
}
EXTENSIONS = {
    '.bash': '',
    '.bat': '',
    '.c': '',
    '.cc': '',
    '.clj': '',
    '.conf': '',
    '.cp': '',
    '.cpp': '',
    '.css': '',
    '.d': '',
    '.dart': '',
    '.db': '',
    '.diff': '',
    '.dump': '',
    '.fish': '',
    '.gif': '',
    '.go': '',
    '.h': '',
    '.hpp': '',
    '.hs': '',
    '.html': '',
    '.ini': '',
    '.java': '',
    '.jpeg': '',
    '.jpg': '',
    '.js': '',
    '.json': '',
    '.jsx': '',
    '.lua': '',
    '.markdown': '',
    '.md': '',
    '.pdf': '',
    '.php': '',
    '.png': '',
    '.py': '',
    '.pyc': '',
    '.pyd': '',
    '.pyo': '',
    '.r': 'ﳒ',
    '.R': 'ﳒ',
    '.rb': '',
    '.rmd': '',
    '.rs': '',
    '.scala': '',
    '.sh': '',
    '.sql': '',
    '.tex': '',
    '.ts': '',
    '.txt': '',
    '.vim': '',
    '.vue': '﵂',
    '.yaml': '',
    '.yml': '',
    '.zsh': '',
}


class Filter(Base):
    """Prepend devicons to denite candidate files."""

    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'converter/devicons'

    def _get_icon(self, filename):
        filename = Path(filename)
        if filename.is_dir():
            return DIR_ICON

        basefile = filename.stem.lower()
        extension = filename.suffix
        if basefile in FILENAMES:
            return FILENAMES[basefile]
        elif extension in EXTENSIONS:
            return EXTENSIONS[extension]
        else:
            return DEFAULT_ICON

    def filter(self, context):
        """Parse candidates and prepend devicons."""
        for i, candidate in enumerate(context['candidates']):
            if i > 25:
                break

            if 'word' in candidate and 'action__path' in candidate:
                filename = candidate['action__path']
                icon = self._get_icon(filename)
                if icon not in candidate.get('abbr', '')[:10]:
                    candidate[
                        'abbr'
                    ] = f" {icon} {candidate.get('abbr', candidate['word'])}"

        return context['candidates']
