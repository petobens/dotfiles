local require = require('lualine_require').require
local Buffer = require('lualine.components.buffertab.buffer')
local M = require('lualine.component'):extend()

_G.LualineBuffertab = { idx2bufnr = {} }

local default_options = {
    filetype_names = {},
    filetype_ignore = {
        aerial = true,
        codecompanion = true,
        codecompanion_input = true,
        dbout = true,
        dbui = true,
        help = true,
        neotest = true,
        ['nvim-pack'] = true,
        NvimTree = true,
        OverseerList = true,
        pager = true,
        qf = true,
        query = true,
        TelescopePrompt = true,
        typsttoc = true,
    },
}

local superscript_nrs = {
    [1] = '¹',
    [2] = '²',
    [3] = '³',
    [4] = '⁴',
    [5] = '⁵',
    [6] = '⁶',
    [7] = '⁷',
    [8] = '⁸',
    [9] = '⁹',
    [10] = '¹⁰',
    [11] = '¹¹',
    [12] = '¹²',
    [13] = '¹³',
    [14] = '¹⁴',
    [15] = '¹⁵',
}

function M:init(options)
    M.super.init(self, options)
    self.options = vim.tbl_deep_extend('keep', self.options or {}, default_options)
end

function M:update_status()
    local buffers = {}
    local current_bufnr = vim.api.nvim_get_current_buf()
    local current
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.bo[bufnr].buflisted
            and vim.bo[bufnr].buftype ~= 'quickfix'
            and vim.bo[bufnr].filetype ~= 'fugitive'
            and not self.options.filetype_ignore[vim.bo[bufnr].filetype]
        then
            buffers[#buffers + 1] = Buffer({ bufnr = bufnr, options = self.options })
            if bufnr == current_bufnr then
                current = #buffers
            end
        end
    end

    -- Include the current unlisted buffer unless it belongs to a utility window
    if not current then
        local buffer = Buffer({ bufnr = current_bufnr, options = self.options })
        if
            not self.options.filetype_ignore[buffer.filetype]
            and buffer.buftype ~= 'nofile'
            and not vim.startswith(buffer.name, 'TelescopePreview')
        then
            buffers[#buffers + 1] = buffer
            current = #buffers
        end
    end

    local mapping = {}
    _G.LualineBuffertab.idx2bufnr = mapping
    if #buffers == 0 then
        return ''
    end
    mapping[0] = buffers[1].bufnr
    mapping[-1] = buffers[#buffers].bufnr

    local name_counts = {}
    for _, buffer in ipairs(buffers) do
        name_counts[buffer.name] = (name_counts[buffer.name] or 0) + 1
    end
    local visible = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        visible[vim.api.nvim_win_get_buf(win)] = true
    end
    -- Cumulative widths let us measure each candidate range without rendering it again
    local widths, position_widths = { [0] = 0 }, { [0] = 0 }
    for i, buffer in ipairs(buffers) do
        if buffer.file ~= '' and name_counts[buffer.name] > 1 then
            buffer.name = string.format(
                '…/%s/%s',
                vim.fs.basename(vim.fs.dirname(buffer.file)),
                vim.fs.basename(buffer.file)
            )
        end
        buffer.first = i == 1
        buffer.current = i == current
        buffer.visible = visible[buffer.bufnr] == true
        local previous = buffers[i - 1]
        if previous then
            buffer.prev_visible = previous.visible
            buffer.prev_modified = previous.modified
            buffer.aftercurrent = previous.current
        end
        local _, width = buffer:render('')
        widths[i] = widths[i - 1] + width
        position_widths[i] = position_widths[i - 1]
            + vim.api.nvim_strwidth(superscript_nrs[i] or '')
    end

    local max_length = self.options.max_length or 0
    if type(max_length) == 'function' then
        max_length = max_length(self)
    end
    if max_length == 0 then
        max_length = math.floor(2 * vim.o.columns / 3)
    end

    local function fits(first, last)
        local width = widths[last] - widths[first - 1] + position_widths[last - first + 1]
        if first > 1 then
            local _, ellipsis_width = buffers[first - 1]:render(nil, true)
            width = width + ellipsis_width
        end
        if last < #buffers then
            local _, ellipsis_width = buffers[last + 1]:render()
            width = width + ellipsis_width
        end
        return width <= max_length
    end

    -- Grow around the current buffer, alternating left and right
    local first, last = current or 1, current or 1
    while first > 1 or last < #buffers do
        if first > 1 then
            if not fits(first - 1, last) then
                break
            end
            first = first - 1
        end
        if last < #buffers then
            if not fits(first, last + 1) then
                break
            end
            last = last + 1
        end
    end

    local data = {}
    if first > 1 then
        data[#data + 1] = buffers[first - 1]:render(nil, true)
    end
    for i = first, last do
        local position = i - first + 1
        data[#data + 1] = buffers[i]:render(superscript_nrs[position] or '')
        mapping[position] = buffers[i].bufnr
    end
    if last < #buffers then
        data[#data + 1] = buffers[last + 1]:render()
    end

    -- Truncate buffer names before lualine's right-hand label
    return '%<' .. table.concat(data)
end

function _G.LualineBuffertab.switch_buf(bufnr)
    vim.api.nvim_set_current_buf(bufnr)
end

function _G.LualineBuffertab.select_buf(position)
    local bufnr = _G.LualineBuffertab.idx2bufnr[position]
    if bufnr then
        vim.api.nvim_set_current_buf(bufnr)
    end
end

return M
