-- luacheck: globals App Entity Header Linemode Root Status Tabs cx th ui ya

-- Plugins
require('full-border'):setup({ type = ui.Border.THICK })
require('git'):setup()
require('folder-rules'):setup()
require('toggle-pane'):entry('max-current')

-- Layout
-- Show tabs above the current directory
function Root:layout()
    local chunks = ui.Layout()
        :direction(ui.Layout.VERTICAL)
        :constraints({
            ui.Constraint.Length(Tabs.height()),
            ui.Constraint.Length(1),
            ui.Constraint.Fill(1),
            ui.Constraint.Length(1),
        })
        :split(self._area)

    self._chunks = { chunks[2], chunks[1], chunks[3], chunks[4] }
end

-- Blend each tab's arrow into the following tab or the window background
function Tabs:redraw()
    if self.height() < 1 then
        return {}
    end

    local styles = self:style()
    local lines = {}
    local offset = 0
    local count = #cx.tabs
    local max = math.floor(math.max(0, self._area.w - count) / count)

    for i = 1, count do
        local style = i == cx.tabs.idx and styles.active or styles.inactive
        local next_style
        if i < count then
            next_style = i + 1 == cx.tabs.idx and styles.active or styles.inactive
        end
        local name = ui.truncate(string.format(' %d %s ', i, cx.tabs[i].name), {
            max = max,
        })
        local segment = ui.Line({
            ui.Span(name):style(style),
            ui.Span(th.tabs.sep_inner.close)
                :fg(style:bg())
                :bg(next_style and next_style:bg() or App.bg()),
        })
        self._offsets[i], offset = offset, offset + segment:width()
        lines[#lines + 1] = segment
    end

    return ui.Line(lines):area(self._area)
end

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
-- Use Vim-style one-letter mode labels
function Status:mode()
    local mode = tostring(self._tab.mode):sub(1, 1):upper()
    local style = self:style()

    return ui.Line({
        ui.Span(th.status.sep_left.open):fg(style.main:bg()):bg(App.bg()),
        ui.Span(' ' .. mode .. ' '):style(style.main),
        ui.Span(th.status.sep_left.close):fg(style.main:bg()):bg(style.alt:bg()),
    })
end

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
-- Keep numbers between the marker gutter and file icons
Entity:children_add(function(self)
    if not self._file.in_current then
        return ''
    end

    local current = cx.active.current.cursor + 1
    local number = self._file.is_hovered and current or math.abs(self._file.idx - current)
    local width = #tostring(#cx.active.current.files)
    local value = string.format('%' .. width .. 'd ', number)

    local color = self._file.is_hovered and '#abb2bf' or '#4b5263'
    return ui.Span(value):fg(color)
end, 1500)

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
