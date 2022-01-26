local onedark_colors = require('onedarkpro').get_colors()

local function gitsigns_diff_source()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns then
        return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
        }
    end
end

local function spell_status()
    local spell_lang = ''
    if vim.opt.spell:get() then
        local languages = vim.fn.toupper(
            vim.fn.substitute(vim.o.spelllang, ',', '/', 'g')
        )
        spell_lang = ' [' .. languages .. ']'
    end
    return spell_lang
end

local function branch_with_remote()
    local branch_name = vim.fn.FugitiveHead()
    local remote = vim.api.nvim_exec(
        [[echo fugitive#repo().config('remote.origin.url')]],
        true
    )
    local branch_icon = ''
    if remote:find('github') then
        branch_icon = ' '
    elseif remote:find('gitlab') then
        branch_icon = ' '
    elseif remote:find('bitbucket') then
        branch_icon = ' '
    end
    return branch_icon .. ' ' .. branch_name
end

local conds = {
    hide_winwidth_leq_80 = function()
        return vim.fn.winwidth(0) > 80
    end,
    hide_winwidth_leq_60 = function()
        return vim.fn.winwidth(0) > 60
    end,
    hide_winwidth_leq_40 = function()
        return vim.fn.winwidth(0) > 40
    end,
}

local function hl_buffer_state(bufnr)
    local hl_group = ''
    local buffers = vim.fn.tabpagebuflist(vim.fn.tabpagenr())
    local mod_buf = (vim.fn.getbufvar(bufnr, '&modified') ~= 0)
    local cur_buf = vim.fn.bufnr('%')

    if cur_buf == bufnr then
        if mod_buf then
            hl_group = 'tabmod'
        else
            hl_group = 'tabsel'
        end
    else
        if mod_buf then
            hl_group = 'tabmod_unsel'
        elseif vim.fn.index(buffers, bufnr) > -1 then
            hl_group = 'tabvis'
        else
            hl_group = 'tabhid'
        end
    end
    hl_group = 'lualine_' .. hl_group .. '_tabline'
    return '%#' .. hl_group .. '#'
end

-- Override tabline function
require('lualine.components.buffers.buffer').render = function(self)
    local apply_padding = require('lualine.components.buffers.buffer').apply_padding

    local name = self:name()
    if self.ellipse then
        name = '...'
    else
        name = string.format('%s %s %s', self.bufnr, name, self.icon)
    end
    name = apply_padding(name, self.options.padding)
    self.len = vim.fn.strchars(name)

    local line = string.format('%%%s@LualineSwitchBuffer@%s%%T', self.bufnr, name)
    local buf_hl_group = hl_buffer_state(self.bufnr)
    line = buf_hl_group .. line

    if not self.first then
        local sep_before = ''
        -- local sep_before = self.options.section_separators.left
        -- local sep_before ='%S{' .. self.options.section_separators.left .. '}'
        -- local sep_before ='%S{' .. self.options.component_separators.left .. '}'
        if self.current or self.aftercurrent then
            sep_before = '%S{' .. self.options.section_separators.left .. '}'
        else
            sep_before = self.options.component_separators.left
        end
        -- local sep_before = self:separator_before()
        line = sep_before .. line
        self.len = self.len + vim.fn.strchars(sep_before)
    end
    return line
end

require('lualine').setup({
    options = {
        theme = 'onedarkish',
        section_separators = { left = '', right = '' },
    },
    sections = {
        lualine_a = {
            {
                'mode',
                fmt = function(str)
                    return str:sub(1, 1)
                end,
            },
            {
                spell_status,
                cond = conds.hide_winwidth_leq_80,
            },
        },
        lualine_b = {
            {
                branch_with_remote,
                fmt = function(str)
                    return str:sub(1, 30)
                end,
                separator = '',
                cond = conds.hide_winwidth_leq_80,
            },
            -- FIXME: diff numbers different size?
            {
                'diff',
                colored = true,
                padding = { left = 0, right = 1 },
                sources = gitsigns_diff_source,
                cond = conds.hide_winwidth_leq_80,
            },
        },
        lualine_x = {
            {
                'lsp_progress',
                component_separator = { left = '', right = '' },
                display_components = {
                    'spinner',
                    'lsp_client_name',
                },
                separators = {
                    lsp_client_name = { pre = '', post = '' },
                },
                cond = conds.hide_winwidth_leq_40,
            },
            {
                'filetype',
                colored = false,
                cond = conds.hide_winwidth_leq_60,
            },
        },
        lualine_y = {
            {
                'fileformat',
                separator = '',
                cond = conds.hide_winwidth_leq_60,
            },
            {
                'encoding',
                padding = { left = 0, right = 1 },
                cond = conds.hide_winwidth_leq_60,
            },
        },
        lualine_z = {
            {
                'progress',
                separator = '',
                cond = conds.hide_winwidth_leq_40,
            },
            {
                function()
                    return '%l'
                end,
                icon = '',
                separator = '',
                padding = { left = 1, right = 0 },
                color = { gui = 'bold' },
                cond = conds.hide_winwidth_leq_40,
            },
            {
                function()
                    return ':%v'
                end,
                padding = { left = 0, right = 1 },
                cond = conds.hide_winwidth_leq_40,
            },
            {
                'diagnostics',
                sources = { 'nvim_diagnostic' },
                colored = false,
                color = { fg = onedark_colors.black, bg = onedark_colors.orange },
                symbols = { error = ' ', warn = ' ', info = ' ', hint = '' },
                separator = { left = '', right = '' },
                cond = conds.hide_winwidth_leq_60,
            },
        },
    },
    inactive_sections = {
        lualine_c = { 'filename' },
        lualine_x = {
            {
                'filetype',
                colored = false,
                cond = conds.hide_winwidth_leq_60,
            },
        },
        lualine_y = {
            {
                'fileformat',
                separator = '',
                cond = conds.hide_winwidth_leq_60,
            },
            {
                'encoding',
                padding = { left = 0, right = 1 },
                cond = conds.hide_winwidth_leq_60,
            },
        },
        lualine_z = {
            {
                'progress',
                separator = '',
                cond = conds.hide_winwidth_leq_40,
            },
            {
                'location',
                icon = '',
                cond = conds.hide_winwidth_leq_40,
            },
        },
    },
    tabline = {
        lualine_a = {
            {
                'buffertab',
                show_filename_only = true,
                max_length = vim.o.columns * 0.98 - vim.fn.strlen('buffers'),
            },
        },
        lualine_z = {
            {
                function()
                    return 'buffers'
                end,
                color = { gui = 'bold' },
            },
        },
    },
})
