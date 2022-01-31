local u = require('utils')
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
            {
                'diff',
                colored = true,
                padding = { left = 0, right = 1 },
                sources = gitsigns_diff_source,
                cond = conds.hide_winwidth_leq_80,
            },
        },
        lualine_c = {
            {
                'filename',
                file_status = true,
                path = 1,
                symbols = {
                    modified = '[+]',
                    readonly = ' ',
                    unnamed = '[No Name]',
                },
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
                symbols = {
                    error = ' ',
                    warn = ' ',
                    info = ' ',
                    hint = ' ',
                },
                separator = { left = '', right = '' },
                cond = conds.hide_winwidth_leq_60,
            },
        },
    },
    inactive_sections = {
        lualine_c = {
            {
                'filename',
                file_status = true,
                path = 1,
                symbols = {
                    modified = '[+]',
                    readonly = ' ',
                    unnamed = '[No Name]',
                },
            },
        },
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
                max_length = vim.o.columns - vim.fn.strlen('buffers'),
                padding = { left = 0, right = 0 },
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

-- Buffertab mappings
for i = 0, 9 do
    u.keymap('n', '<Leader>' .. i, function()
        _G.LualineBuffertab.select_buf(i)
    end)
end
u.keymap('n', '<Leader>$', function()
    _G.LualineBuffertab.select_buf(-1)
end)
