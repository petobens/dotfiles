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
    local stat = vim.uv.fs_stat(self.file)
    self.is_directory = stat and stat.type == 'directory'

    self.icon = ''
    if self.options.icons_enabled then
        local dev
        local devicons = require('nvim-web-devicons')

        if self.filetype == 'TelescopePrompt' then
            dev = devicons.get_icon('telescope')
        elseif self.filetype == 'fugitive' then
            dev = devicons.get_icon('git')
        elseif self.buftype == 'terminal' then
            dev = devicons.get_icon('zsh')
        elseif self.is_directory then
            dev = ''
        else
            dev = devicons.get_icon(vim.fs.basename(self.file), vim.fs.ext(self.file))
                or devicons.get_icon_by_filetype(self.filetype)
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
    elseif self.modified then
        hl_group = 'modified_unselected'
    elseif self.visible then
        hl_group = 'visible'
    else
        hl_group = 'hidden'
    end
    hl_group = string.format('lualine_%s_tabline', hl_group)
    return string.format('%%#%s#', hl_group)
end

-- A nil position renders a clickable ellipsis for a hidden buffer
function Buffer:render(position, omit_separator)
    local name = '...'
    if position then
        name = self.options.fmt and self.options.fmt(self.name) or self.name
        name = string.format(' %s%d:%s %s', position, self.bufnr, name, self.icon)
    end
    name = Buffer.apply_padding(name, self.options.padding)
    local width = vim.api.nvim_strwidth(name)
    local line = self:hl_buffer_state()
        .. string.format(
            '%%%d@v:lua.LualineBuffertab.switch_buf@%s%%T',
            self.bufnr,
            name:gsub('%%', '%%%%')
        )
    if self.options.self.section < 'x' and not (omit_separator or self.first) then
        local separator, separator_width = self:separator_before()
        line = separator .. line
        width = width + separator_width
    end
    return line, width
end

function Buffer:separator_before()
    if
        (self.current or self.aftercurrent)
        or (self.visible ~= self.prev_visible)
        or (self.visible and (self.prev_modified or self.modified))
        or (self.modified and not self.prev_visible)
    then
        local separator = self.options.section_separators.left
        return string.format('%%Z{%s}', separator), vim.api.nvim_strwidth(separator)
    else
        local separator = self.options.component_separators.left
        return separator, vim.api.nvim_strwidth(separator)
    end
end

function Buffer:get_name()
    local name
    if self.options.filetype_names[self.filetype] then
        name = self.options.filetype_names[self.filetype]
    elseif self.buftype == 'terminal' then
        local match = string.match(vim.split(self.file, ' ')[1], 'term:.*:(%a+)')
        name = match ~= nil and match or vim.fs.basename(vim.env.SHELL)
    elseif self.is_directory then
        name = vim.fs.relpath(vim.uv.cwd(), self.file) or self.file
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
