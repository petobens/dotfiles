local leap = require('leap')

leap.setup({
    max_highlighted_traversal_targets = 20,
    safe_labels = { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';' },
    -- special_keys = {
    --     -- FIXME: Using special keys defintion gives errors with flit
    --     next_target = { '<enter>' },
    --     prev_target = { '<tab>' },
    -- },
})
require('flit').setup({}) -- enhanced f,F,t and T motions (as in sneak)

-- Mappings (use default but don't map x)
leap.add_default_mappings()
vim.keymap.del({ 'x', 'o' }, 'x')
vim.keymap.del({ 'x', 'o' }, 'X')
