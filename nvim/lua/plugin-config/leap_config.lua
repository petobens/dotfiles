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

-- FIXME: Hack to fix real cursor staying on original position when jumping
-- See: https://github.com/ggandor/leap.nvim/issues/70#issuecomment-1521177534
vim.api.nvim_create_autocmd('User', {
    pattern = 'LeapEnter',
    callback = function()
        vim.cmd.hi('Cursor', 'blend=100')
        vim.opt.guicursor:append({ 'a:Cursor/lCursor' })
    end,
})
vim.api.nvim_create_autocmd('User', {
    pattern = 'LeapLeave',
    callback = function()
        vim.cmd.hi('Cursor', 'blend=0')
        vim.opt.guicursor:remove({ 'a:Cursor/lCursor' })
    end,
})
