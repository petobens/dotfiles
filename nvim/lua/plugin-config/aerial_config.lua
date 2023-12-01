local u = require('utils')

require('aerial').setup({
    backends = {
        ['_'] = { 'treesitter', 'lsp', 'markdown', 'man' },
        tex = { 'lsp' },
        markdown = { 'markdown' },
    },
    layout = {
        width = 43,
        default_direction = 'left',
        placement = 'edge',
        preserve_equality = true,
    },
    close_on_select = true,
    highlight_on_hover = true,
    highlight_on_jump = 500,
    icons = {
        Collapsed = u.icons.fold_close,
        markdown = { Interface = '󰪥' },
    },
    get_highlight = function(_, is_icon, is_collapsed)
        if is_icon and is_collapsed then
            return 'Comment'
        end
    end,
    keymaps = {
        ['v'] = 'actions.jump_vsplit',
        ['s'] = 'actions.jump_split',
        ['zm'] = 'actions.tree_close_all',
        ['zr'] = 'actions.tree_open_all',
    },
    nav = {
        preview = true,
        max_height = 0.35,
        min_height = 0.35,
        max_width = 0.25,
        min_width = 0.25,
        keymaps = {
            ['<q>'] = 'actions.close',
            ['v'] = 'actions.jump_vsplit',
            ['s'] = 'actions.jump_split',
        },
    },
    treesitter = {
        experimental_selection_range = true,
    },
})

-- Helpers
local function telescope_filter(opts)
    opts = opts or {}
    opts.attach_mappings = function(_, map)
        map('i', '<CR>', _G.TelescopeConfig.custom_actions.open_aerial)
        return true
    end
    -- Switch to previous buffer since aerial telescope acts upon current buffer
    vim.cmd('wincmd p')
    require('telescope').extensions.aerial.aerial(opts)
end

-- Autocmds
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('aerial', { clear = true }),
    pattern = { 'aerial' },
    callback = function()
        vim.cmd('setlocal number relativenumber')
        vim.keymap.set('n', '<C-t>', telescope_filter, { buffer = true })
    end,
})

-- Mappings
vim.keymap.set('n', '<Leader>tb', '<Cmd>AerialToggle<CR>')
vim.keymap.set('n', '<Leader>an', '<Cmd>AerialNavToggle<CR>')
