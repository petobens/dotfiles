local u = require('utils')

 require('tabline').setup({
      enable = true,
      options = {
        max_bufferline_percent = nil,
        show_tabs_always = false,
        show_devicons = true,
        show_bufnr = true,
        show_filename_only = true
      }
})

u.keymap('n', '<C-n>', ':TablineBufferNext<CR>')
u.keymap('n', '<C-p>', ':TablineBufferPrevious<CR>')
