-- luacheck: globals App Header Linemode Status th ui ya

-- Plugins
require('full-border'):setup({ type = ui.Border.THICK })
require('git'):setup()
require('folder-rules'):setup()
require('toggle-pane'):entry('max-current')

-- Header
-- Keep the folder icon visible when long paths are truncated
function Header:cwd()
    local max = self._area.w - self._right_width - 3
    if max <= 0 then
        return ''
    end

    local path = ya.readable_path(tostring(self._current.cwd)) .. self:flags()
    return ui.Span('  ' .. ui.truncate(path, { max = max, rtl = true }))
        :style(th.mgr.cwd)
end

-- Status line
-- Keep the position neutral instead of repeating the current mode color
function Status:position()
    local cursor = self._current.cursor
    local length = #self._current.files
    local alt = self:style().alt
    local style = ui.Style():fg('#303030'):bg('#d0d0d0'):bold()

    return ui.Line({
        ui.Span(th.status.sep_right.open):fg(style:bg()):bg(alt:bg()),
        ui.Span(string.format(' %2d/%-2d ', math.min(cursor + 1, length), length))
            :style(style),
        ui.Span(th.status.sep_right.close):fg(style:bg()):bg(App.bg()),
    })
end

-- File list
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

-- Bookmarks
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
        u = '/run/media/' .. os.getenv('USER'),
        v = home .. '/git-repos/private/dotfiles/nvim',
        w = home .. '/git-repos/work',
    },
    path = (os.getenv('XDG_STATE_HOME') or home .. '/.local/state') .. '/yazi/bookmarks',
})
