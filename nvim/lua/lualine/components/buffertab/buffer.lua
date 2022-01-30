local Buffer = require('lualine.utils.class'):extend()

---Intialize a new buffer from opts
---@param opts table
function Buffer:init(opts)
    assert(opts.bufnr, 'Cannot create Buffer without bufnr')
    self.bufnr = opts.bufnr
    self.options = opts.options
    self:get_props()
end

---Setup icons modified status and properties for buffer
function Buffer:get_props()
    self.file = vim.api.nvim_buf_get_name(self.bufnr)
    self.buftype = vim.api.nvim_buf_get_option(self.bufnr, 'buftype')
    self.filetype = vim.api.nvim_buf_get_option(self.bufnr, 'filetype')
    self.modified = vim.api.nvim_buf_get_option(self.bufnr, 'modified')

    self.icon = ''
    if self.options.icons_enabled then
        local dev
        local get_icon = require('nvim-web-devicons').get_icon
        if self.filetype == 'TelescopePrompt' then
            dev, _ = get_icon('telescope')
        elseif self.filetype == 'fugitive' then
            dev, _ = get_icon('git')
        elseif self.filetype == 'vimwiki' then
            dev, _ = get_icon('markdown')
        elseif self.buftype == 'terminal' then
            dev, _ = get_icon('zsh')
        elseif vim.fn.isdirectory(self.file) == 1 then
            dev, _ = '', nil
        else
            dev, _ = get_icon(self.file, vim.fn.expand('#' .. self.bufnr .. ':e'))
        end
        if dev then
            self.icon = dev .. ' '
        end
    end
end

--- Highlight buffer state according to visible/modified status
function Buffer:hl_buffer_state()
    local hl_group = ''
    if self.current then
        if self.modified then
            hl_group = 'modified'
        else
            hl_group = 'selected'
        end
    else
        if self.modified then
            hl_group = 'modified_unselected'
        elseif self.visible then
            hl_group = 'visible'
        else
            hl_group = 'hidden'
        end
    end
    hl_group = 'lualine_' .. hl_group .. '_tabline'
    return '%#' .. hl_group .. '#'
end

---Return rendered buffer
---@return string
function Buffer:render()
    local name = self:name()
    if self.options.fmt then
        name = self.options.fmt(name or '')
    end

    if self.ellipse then -- show elipsis
        name = '...'
    else
        name = string.format('%s %s %s', self.bufnr, name, self.icon)
    end
    name = Buffer.apply_padding(name, self.options.padding)
    self.len = vim.fn.strchars(name)

    -- Setup for mouse clicks
    local line = string.format('%%%s@LualineSwitchBuffer@%s%%T', self.bufnr, name)

    -- Apply highlight
    local buf_hl_group = self:hl_buffer_state()
    line = buf_hl_group .. line

    -- Apply separators
    if self.options.self.section < 'lualine_x' and not self.first then
        local sep_before = self:separator_before()
        line = sep_before .. line
        self.len = self.len + vim.fn.strchars(sep_before)
    end
    return line
end

---Apply separator before
---@return string
function Buffer:separator_before()
    if
        (self.current or self.aftercurrent)
        or self.visible ~= self.prev_visible
        or (self.visible and (self.prev_modified or self.modified))
    then
        return '%S{' .. self.options.section_separators.left .. '}'
    else
        return self.options.component_separators.left
    end
end

---Returns name of current buffer after filtering special buffers
---@return string
function Buffer:name()
    if self.options.filetype_names[self.filetype] then
        return self.options.filetype_names[self.filetype]
    elseif self.buftype == 'help' then
        return 'help:' .. vim.fn.fnamemodify(self.file, ':t:r')
    elseif self.buftype == 'terminal' then
        local match = string.match(vim.split(self.file, ' ')[1], 'term:.*:(%a+)')
        return match ~= nil and match or vim.fn.fnamemodify(vim.env.SHELL, ':t')
    elseif vim.fn.isdirectory(self.file) == 1 then
        return vim.fn.fnamemodify(self.file, ':p:.')
    elseif self.file == '' then
        return '[No Name]'
    end
    return vim.fn.fnamemodify(self.file, ':t')
end

---Adds spaces to left and right
function Buffer.apply_padding(str, padding)
    local l_padding, r_padding = 1, 1
    if type(padding) == 'number' then
        l_padding, r_padding = padding, padding
    elseif type(padding) == 'table' then
        l_padding, r_padding = padding.left or 0, padding.right or 0
    end
    return string.rep(' ', l_padding) .. str .. string.rep(' ', r_padding)
end

return Buffer
