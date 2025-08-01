local Buffer = require('lualine.utils.class'):extend()

function Buffer:init(opts)
    assert(opts.bufnr, 'Cannot create Buffer without bufnr')
    self.bufnr = opts.bufnr
    self.options = opts.options
    self:get_props()
    self:get_name()
end

-- Setup icons modified status and properties for buffer
function Buffer:get_props()
    self.file = vim.api.nvim_buf_get_name(self.bufnr)
    self.buftype = vim.bo[self.bufnr].buftype
    self.filetype = vim.bo[self.bufnr].filetype
    self.modified = vim.bo[self.bufnr].modified

    self.icon = ''
    if self.options.icons_enabled then
        local dev
        local _
        local get_icon = require('nvim-web-devicons').get_icon

        if self.filetype == 'TelescopePrompt' then
            dev, _ = get_icon('telescope')
        elseif self.filetype == 'fugitive' then
            dev, _ = get_icon('git')
        elseif self.buftype == 'terminal' then
            dev, _ = get_icon('zsh')
        elseif
            vim.uv.fs_stat(self.file)
            and vim.uv.fs_stat(self.file).type == 'directory'
        then
            dev = ''
        else
            local bufname = vim.api.nvim_buf_get_name(self.bufnr)
            local ext = bufname:match('%.([^.]+)$') or ''
            dev, _ = get_icon(self.file, ext)
        end
        if dev then
            self.icon = dev .. ' '
        end
    end
end

function Buffer:hl_buffer_state()
    local hl_group
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
    hl_group = string.format('lualine_%s_tabline', hl_group)
    return string.format('%%#%s#', hl_group)
end

function Buffer:render()
    local name = self.name
    if self.options.fmt then
        name = self.options.fmt(name or '')
    end

    if self.ellipse then -- show elipsis
        name = '...'
    else
        -- Add arbitrary string to replace by superscript position, we leave a
        -- space at the beginning and set padding to 0 for tighter fit
        -- FIXME: find a way of actually adding %s placeholder
        name = ' KQ' .. string.format('%s:%s %s', self.bufnr, name, self.icon)
    end
    name = Buffer.apply_padding(name, self.options.padding)
    self.len = vim.str_utfindex(name)

    -- Setup for mouse clicks
    local line = string.format('%%%s@LualineSwitchBuffer@%s%%T', self.bufnr, name)

    -- Apply highlight
    local buf_hl_group = self:hl_buffer_state()
    line = buf_hl_group .. line

    -- Apply separators
    if self.options.self.section < 'lualine_x' and not self.first then
        local sep_before = self:separator_before()
        line = sep_before .. line
        self.len = self.len + vim.str_utfindex(sep_before, 'utf-8')
    end
    return line
end

function Buffer:separator_before()
    if
        (self.current or self.aftercurrent)
        or (self.visible ~= self.prev_visible)
        or (self.visible and (self.prev_modified or self.modified))
        or (self.modified and not self.prev_visible)
    then
        return string.format('%%Z{%s}', self.options.section_separators.left)
    else
        return self.options.component_separators.left
    end
end

function Buffer:get_name()
    local name
    if self.options.filetype_names[self.filetype] then
        name = self.options.filetype_names[self.filetype]
    elseif self.buftype == 'help' then
        name = 'help:' .. (vim.fs.basename(self.file)):match('(.+)%.[^/]+$')
    elseif self.buftype == 'terminal' then
        local match = string.match(vim.split(self.file, ' ')[1], 'term:.*:(%a+)')
        name = match ~= nil and match or vim.fs.basename(vim.env.SHELL)
    elseif
        vim.uv.fs_stat(self.file) and vim.uv.fs_stat(self.file).type == 'directory'
    then
        name = vim.fn.fnamemodify(self.file, ':p:.')
    elseif self.file == '' then
        name = '[No Name]'
    else
        name = vim.fs.basename(self.file)
    end
    self.name = name
    return name
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
