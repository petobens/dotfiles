local require = require('lualine_require').require
local Buffer = require('lualine.components.buffertab.buffer')

local M = require('lualine.component'):extend()

local default_options = {
    filetype_names = {
        packer = 'Packer',
    },
    filetype_ignore = '\\c\\vtelescope|nvimtree',
}

function M:init(options)
    M.super.init(self, options)
    self.options = vim.tbl_deep_extend('keep', self.options or {}, default_options)
end

function M:update_status()
    local data = {}
    local buffers = {}
    for b = 1, vim.fn.bufnr('$') do
        if
            vim.fn.buflisted(b) ~= 0
            and vim.api.nvim_buf_get_option(b, 'buftype') ~= 'quickfix'
        then
            buffers[#buffers + 1] = Buffer({
                bufnr = b,
                options = self.options,
            })
        end
    end
    local current_bufnr = vim.api.nvim_get_current_buf()
    local current = -2
    -- Mark the first, last, current, visible, prev_visible and aftercurrent
    -- buffers for rendering
    if buffers[1] then
        buffers[1].first = true
    end
    if buffers[#buffers] then
        buffers[#buffers].last = true
    end
    local visible_buffers = vim.fn.tabpagebuflist()
    for i, buffer in ipairs(buffers) do
        if buffer.bufnr == current_bufnr then
            buffer.current = true
            current = i
        end
        if vim.fn.index(visible_buffers, buffer.bufnr) > -1 then
            buffer.visible = true
        else
            buffer.visible = false
        end
        if buffer.first ~= true then
            local prev_buffer = buffers[i - 1]
            if vim.fn.index(visible_buffers, prev_buffer.bufnr) > -1 then
                buffer.prev_visible = true
            else
                buffer.prev_visible = false
            end
        end
    end
    if buffers[current + 1] then
        buffers[current + 1].aftercurrent = true
    end

    local max_length = self.options.max_length
    if type(max_length) == 'function' then
        max_length = max_length(self)
    end

    if max_length == 0 then
        max_length = math.floor(2 * vim.o.columns / 3)
    end
    local total_length
    for i, buffer in pairs(buffers) do
        if buffer.current then
            current = i
        end
    end
    -- start drawing from current buffer and draw left and right of it until
    -- all buffers are drawn or max_length has been reached.
    if current == -2 then
        local b = Buffer({
            bufnr = vim.api.nvim_get_current_buf(),
            options = self.options,
        })
        if
            -- If current buffer was not listed and it's not blacklisted then
            -- add to the the list
            vim.fn.match(b.filetype, self.options.filetype_ignore) < 0
        then
            b.current = true
            b.last = true
            if #buffers > 0 then
                buffers[#buffers].last = nil
            end
            buffers[#buffers + 1] = b
            current = #buffers
        else
            current = 1 -- arbitrary existent buffer
        end
    end
    local current_buffer = buffers[current]
    data[#data + 1] = current_buffer:render()
    total_length = current_buffer.len
    local i = 0
    local before, after
    while true do
        i = i + 1
        before = buffers[current - i]
        after = buffers[current + i]
        local rendered_before, rendered_after
        if before == nil and after == nil then
            break
        end
        -- draw left most undrawn buffer if fits in max_length
        if before then
            rendered_before = before:render()
            total_length = total_length + before.len
            if total_length > max_length then
                break
            end
            table.insert(data, 1, rendered_before)
        end
        -- draw right most undrawn buffer if fits in max_length
        if after then
            rendered_after = after:render()
            total_length = total_length + after.len
            if total_length > max_length then
                break
            end
            data[#data + 1] = rendered_after
        end
    end
    -- draw elipsis (...) on relevent sides if all buffers don't fit in max_length
    if total_length > max_length then
        if before ~= nil then
            before.ellipse = true
            before.first = true
            table.insert(data, 1, before:render())
        end
        if after ~= nil then
            after.ellipse = true
            after.last = true
            data[#data + 1] = after:render()
        end
    end

    return table.concat(data)
end

function M:draw()
    self.status = ''
    self.applied_separator = ''

    if self.options.cond ~= nil and self.options.cond() ~= true then
        return self.status
    end
    local status = self:update_status()
    if type(status) == 'string' and #status > 0 then
        self.status = status
        self:apply_section_separators()
        self:apply_separator()
    end
    return self.status
end

vim.cmd([[
  function! LualineSwitchBuffer(bufnr, mouseclicks, mousebutton, modifiers)
    execute ":buffer " . a:bufnr
  endfunction
]])

return M
