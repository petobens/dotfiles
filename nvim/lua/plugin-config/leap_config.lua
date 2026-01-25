local leap = require('leap')

-- Helpers
local function make_leap_ft_opts(motion_opts)
    local mode = vim.api.nvim_get_mode().mode
    local safe_labels = mode:match('^[no]') and '' or nil

    return vim.tbl_deep_extend('keep', {
        inputlen = 1,
        inclusive = true,
        opts = {
            labels = '',
            safe_labels = safe_labels,
        },
    }, motion_opts or {})
end

-- Mappings
vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap-forward)', { desc = 'Leap forward' })
vim.keymap.set(
    { 'n', 'x', 'o' },
    'S',
    '<Plug>(leap-backward)',
    { desc = 'Leap backward' }
)
leap.opts.keys.next_target = { '<A-n>' }
leap.opts.keys.prev_target = { '<A-p>' }

-- Enhanced f,F,t and T motions (as in sneak)
local clever = require('leap.user').with_traversal_keys
local clever_f = clever('f', 'F')
local clever_t = clever('t', 'T')
for _, spec in ipairs({
    { key = 'f', args = { opts = clever_f } },
    { key = 'F', args = { backward = true, opts = clever_f } },
    { key = 't', args = { offset = -1, opts = clever_t } },
    { key = 'T', args = { backward = true, offset = 1, opts = clever_t } },
}) do
    vim.keymap.set({ 'n', 'x', 'o' }, spec.key, function()
        leap.leap(make_leap_ft_opts(spec.args))
    end, { desc = ('Leap %s'):format(spec.key) })
end
