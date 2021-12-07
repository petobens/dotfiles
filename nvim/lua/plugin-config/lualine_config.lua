local function echo_buffers()
  return 'buffers'
end

require('lualine').setup({
    options = {
        theme = 'onedarkish',
        section_separators = { left = '', right = ''},
    },
    sections = {
        lualine_a = {
            {
                'mode',
                fmt = function(str)
                        return str:sub(1,1)
                    end
            }
        },
    },
    inactive_sections = {
        lualine_c = {'filename'},
        lualine_x = {
            {'encoding',  separator = ''},
            {'filetype', icons_enabled = false, separator = ''},
        },
        lualine_y = {'progress'},
        lualine_z = {'location'}
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
