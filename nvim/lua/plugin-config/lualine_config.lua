local u = require('utils')
---@diagnostic disable-next-line: missing-parameter
local onedark_colors = require('onedarkpro.helpers').get_colors()
local overseer = require('overseer')

_G.LualineConfig = {}

-- Custom segments/components
local function gitsigns_diff_source()
    ---@diagnostic disable-next-line: undefined-field
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
        local languages =
            vim.fn.toupper(vim.fn.substitute(vim.o.spelllang, ',', '/', 'g'))
        spell_lang = ' [' .. languages .. ']'
    end
    return spell_lang
end

local function branch_with_remote()
    local branch_name = vim.fn.FugitiveHead()
    if branch_name == '' then
        return ''
    end
    local remote =
        vim.api.nvim_exec([[echo FugitiveConfigGet('remote.origin.url')]], true)
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

_G.LualineConfig.trailing_last = ''
local function trailing_whitespace()
    local space = vim.fn.search([[\s\+$]], 'nwc')
    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'n' then
        _G.LualineConfig.trailing_last = space ~= 0 and ' ' .. space or ''
    end
    return _G.LualineConfig.trailing_last
end

-- Custom extensions
local nvimtree_ext = {
    sections = {
        lualine_a = {
            function()
                return 'NvimTree'
            end,
        },
        lualine_b = {
            function()
                return vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
            end,
        },
    },
    filetypes = { 'NvimTree' },
}

local fugitive_ext = {
    sections = {
        lualine_a = {
            function()
                return 'fugitive'
            end,
        },
        lualine_b = {
            branch_with_remote,
        },
    },
    filetypes = { 'fugitive' },
}

-- Resize conditions
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
                diff_color = {
                    added = 'DiffAdd',
                    modified = 'DiffChange',
                    removed = 'DiffDelete',
                },
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
                only_show_attached = true,
                -- pyright doesn't send status messages so hide it
                -- https://github.com/WhoIsSethDaniel/lualine-lsp-progress.nvim/issues/5#issuecomment-1426838592
                hide = { 'pyright' },
                display_components = {
                    'lsp_client_name',
                    { 'message' },
                },
                message = {
                    initializing = '襤',
                    commenced = '屢',
                    completed = '',
                },
                component_separator = { left = '', right = '' },
                separators = {
                    lsp_client_name = { pre = '', post = '' },
                },
                cond = conds.hide_winwidth_leq_40,
            },
            {
                'aerial',
                depth = -1,
                colored = false,
                component_separator = { left = '', right = '' },
                cond = conds.hide_winwidth_leq_80,
            },
        },
        lualine_y = {
            {
                'filetype',
                colored = false,
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
                    error = ' ',
                    warn = ' ',
                    info = ' ',
                    hint = ' ',
                },
                separator = { left = '', right = '' },
                cond = conds.hide_winwidth_leq_60,
            },
            {
                trailing_whitespace,
                separator = { left = '', right = '' },
                component_separator = { left = '', right = '' },
                color = { fg = onedark_colors.black, bg = onedark_colors.orange },
                cond = conds.hide_winwidth_leq_60,
            },
            {
                'overseer',
                label = '',
                colored = false,
                color = {
                    fg = onedark_colors.black,
                    bg = onedark_colors.purple,
                },
                symbols = {
                    [overseer.STATUS.RUNNING] = '省',
                },
                status = { overseer.STATUS.RUNNING },
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
                path = 3,
                symbols = {
                    modified = '[+]',
                    readonly = ' ',
                    unnamed = '[No Name]',
                },
            },
        },
        lualine_y = {
            {
                'filetype',
                colored = false,
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
                max_length = function()
                    return vim.o.columns - vim.fn.strlen('buffers')
                end,
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
    extensions = {
        'aerial',
        'quickfix',
        fugitive_ext,
        nvimtree_ext,
    },
})

-- Buffertab mappings
for i = -1, 9 do
    local key = i == -1 and '$' or i
    u.keymap('n', '<Leader>' .. key, function()
        _G.LualineBuffertab.select_buf(i)
    end)
end
