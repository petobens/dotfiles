local u = require('utils')

require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ["<C-s>"] = "file_split"
      }
    }
  },
})

u.keymap('n', '<Leader>ls', ':Telescope find_files<CR>')
u.keymap('n', '<Leader>rd', ':Telescope oldfiles<CR>')
u.keymap('n', '<Leader>be', ':Telescope buffers<CR>')
