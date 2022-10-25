local leap = require('leap')

leap.setup({
    max_highlighted_traversal_targets = 20, -- show 20 matches when traversing
})
require('flit').setup({}) -- enhanced f,F,t and T motions (as in sneak)

-- Mappings (use default but don't map x)
leap.add_default_mappings()
leap.opts.special_keys.next_target = { '<A-n>' }
leap.opts.special_keys.prev_target = { '<A-p>' }
vim.keymap.del({ 'x', 'o' }, 'x')
vim.keymap.del({ 'x', 'o' }, 'X')
