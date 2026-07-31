-- luacheck: globals Linemode ya

require('full-border'):setup()
require('git'):setup()
require('folder-rules'):setup()
require('toggle-pane'):entry('max-current')

local home = os.getenv('HOME')

require('bookmarks'):setup({
    bookmarks = {
        d = home .. '/Downloads',
        g = home .. '/git-repos',
        m = home .. '/OneDrive/mutt',
        n = '/mnt/nfs',
        o = home .. '/OneDrive',
        p = home .. '/Pictures',
        s = home .. '/Pictures/Screenshots',
        t = home .. '/Desktop',
        u = '/run/media',
        v = home .. '/git-repos/private/dotfiles/nvim',
        w = home .. '/git-repos/work',
    },
    path = (os.getenv('XDG_STATE_HOME') or home .. '/.local/state') .. '/yazi/bookmarks',
})

function Linemode:size_and_mtime()
    local time = math.floor(self._file.cha.mtime or 0)
    if time == 0 then
        time = ''
    elseif os.date('%Y', time) == os.date('%Y') then
        time = os.date('%b %d %H:%M', time)
    else
        time = os.date('%b %d  %Y', time)
    end

    local size = self._file:size()
    return string.format('%s %s', size and ya.readable_size(size) or '-', time)
end
