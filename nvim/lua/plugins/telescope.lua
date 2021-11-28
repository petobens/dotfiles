local u = require('utils')

require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ['<esc>'] = 'close',
        ['<C-s>'] = 'file_split',
        ['<C-j>'] = 'move_selection_next',
        ['<C-k>'] = 'move_selection_previous',
      }
    }
  },
})

u.keymap('n', '<Leader>ls', ':Telescope find_files<CR>')
u.keymap('n', '<Leader>lu', ':Telescope find_files cwd=..<CR>')
u.keymap('n', '<Leader>sd', ':Telescope find_files cwd=', {silent = false})
u.keymap('n', '<Leader>ig', ':Telescope live_grep<CR>')
u.keymap('n', '<Leader>rd', ':Telescope oldfiles<CR>')
u.keymap('n', '<Leader>be', ':Telescope buffers<CR>')
u.keymap('n', '<Leader>gl', ':Telescope git_commits<CR>')
