local onedark_colors = require('onedarkpro').get_colors()

local function gitsigns_diff_source()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns then
        return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed
        }
    end
end

local function spell_status()
    local spell_lang = ''
    if vim.opt.spell:get() then
        local languages = vim.fn.toupper(vim.fn.substitute(vim.o.spelllang, ',', '/', 'g'))
        spell_lang = ' [' .. languages .. ']'
    end
    return spell_lang
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
    local mod_buffer = (vim.fn.getbufvar(bufnr, '&modified') ~= 0)
    local cur_buffer = vim.fn.bufnr('%')

    if cur_buffer == bufnr then
        if mod_buffer then
            hl_group = 'tabmod'
        else
            hl_group = 'tabsel'
        end
    else
        if mod_buffer then
            hl_group = 'tabmod_unsel'
        elseif vim.fn.index(buffers, bufnr) > -1 then
            hl_group = 'tab'
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
    local buf_hl_group = hl_buffer_state(self.bufnr)
    if self.ellipse then
        name = '...'
    else
        name = string.format('%s %s %s', self.bufnr, name, self.icon)
    end
    name = apply_padding(name, self.options.padding)
    self.len = vim.fn.strchars(name)

    local line = string.format('%%%s@LualineSwitchBuffer@%s%%T', self.bufnr, name)
    line = buf_hl_group .. line

    if not self.first then
        local sep_before = self:separator_before()
        line = sep_before .. line
        self.len = self.len + vim.fn.strchars(sep_before)
    end
    return line
end


require('lualine').setup({
    options = {
        theme = 'onedarkish',
        section_separators = {left = '', right = ''},
    },
    sections = {
        lualine_a = {
            {
                'mode',
                fmt = function(str)
                        return str:sub(1,1)
                    end
            },
            {
                spell_status,
                cond = conds.hide_winwidth_leq_80
            },
        },
        lualine_b = {
            {
                'branch',
                separator = '',
                cond = conds.hide_winwidth_leq_80
            },
            -- FIXME: diff numbers different size?
            {
                'diff',
                colored = true,
                padding = {left = 0, right = 1},
                sources = gitsigns_diff_source,
                cond = conds.hide_winwidth_leq_80,

            },
        },
        lualine_x = {
            {
                'filetype',
                colored = false,
                cond = conds.hide_winwidth_leq_60
            }
        },
        lualine_y = {
            {
                'encoding',
                separator = '',
                cond = conds.hide_winwidth_leq_60,
            },
            {
                'fileformat',
                padding = {left = 0, right = 2},
                cond = conds.hide_winwidth_leq_60,
            },
        },
        lualine_z = {
            {
                'progress',
                separator = '',
                cond = conds.hide_winwidth_leq_40
            },
            {
                function() return '%l' end,
                icon = '',
                separator = '',
                padding = {left = 1, right = 0},
                color = {gui = 'bold'},
                cond = conds.hide_winwidth_leq_40,
            },
            {
                function() return ':%v' end,
                padding = {left = 0, right = 1},
                cond = conds.hide_winwidth_leq_40,
            },
            {
                'diagnostics',
                sources = {'nvim_diagnostic'},
                colored = false,
                color = {fg = onedark_colors.black , bg = onedark_colors.orange},
               separator = {left = '', right = ''},
                cond = conds.hide_winwidth_leq_60,
            },
        },
    },
    inactive_sections = {
        lualine_c = {'filename'},
        lualine_x = {
            {
                'filetype',
                colored = false,
                cond = conds.hide_winwidth_leq_60,
            },
        },
        lualine_y = {
            {
                'encoding',
                separator = '',
                cond = conds.hide_winwidth_leq_60,
            },
            {
                'fileformat',
                padding = {left = 0, right = 2},
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
                'buffers',
                show_filename_only = true,
                show_modified_status = true,
                mode = 2, -- buffer name + buffer index (bufnr)
                max_length = vim.o.columns * 0.98 - vim.fn.strlen('buffers'),
                buffers_color = {
                    active = 'lualine_a_insert',
                    inactive = 'lualine_a_inactive',
                },
            },
        },
        lualine_z = {
            {
                function() return 'buffers' end,
                color = {gui = 'bold'},
            },
        }
    },
})
