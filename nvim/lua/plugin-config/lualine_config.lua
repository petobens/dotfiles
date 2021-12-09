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
            {spell_status},
        },
        lualine_b = {
            {'branch', separator = ''},
            -- FIXME: diff numbers different size?
            {
                'diff',
                colored = true,
                padding = {left = 0, right = 1},
                sources = gitsigns_diff_source,

            },
        },
        lualine_x = {{'filetype', colored = false}},
        lualine_y = {
            {'encoding', separator = ''},
            {'fileformat', padding = {left = 0, right = 2}},
        },
        lualine_z = {
            {'progress', separator = ''},
            {'location', icon = ''},
            {
                'diagnostics',
                sources= {'nvim_lsp'},
                colored = false,
                color = {fg = onedark_colors.black , bg = onedark_colors.orange},
                separator = {left = '', right = ''},
            },
        },
    },
    inactive_sections = {
        lualine_c = {'filename'},
        lualine_x = {{'filetype', colored = false}},
        lualine_y = {
            {'encoding', separator = ''},
            {'fileformat', padding = {left = 0, right = 2}},
        },
        lualine_z = {
            {'progress', separator = ''},
            {'location', icon = ''},
        },
  },
    tabline = {
        lualine_a = {
            {
                'buffers',
                show_filename_only = true,
                show_modified_status = true,
                mode = 2, -- buffer name + buffer index (bufnr)
                max_length = vim.o.columns * 1.1,
                buffers_color = {
                    active = 'lualine_a_insert',
                    inactive = 'lualine_a_inactive',
                },
            },
        },
        -- FIXME: not quite working
        -- lualine_z = {echo_buffers}
    },
})
