-- FIXME:
-- Markdown error when pressing g (it tries to run gh)
-- Highlights similar to before
-- Also borders and style in general
-- Some word indicating the source Check that lsp works
-- Complete arguments in python functions

local blink_cmp = require('blink.cmp')
require('lazydev').setup()

blink_cmp.setup({
    appearance = {
        kind_icons = require('lspkind').presets.default,
    },
    completion = {
        list = {
            selection = {
                preselect = true,
                auto_insert = true,
            },
            max_items = 10,
        },
        documentation = { auto_show = true },
        ghost_text = { enabled = true },
    },
    keymap = {
        ['<C-p>'] = { 'select_prev' },
        ['<C-n>'] = { 'select_next', 'show' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<A-k>'] = { 'scroll_documentation_up', 'fallback' },
        ['<A-j>'] = { 'scroll_documentation_down', 'fallback' },
    },
    sources = {
        default = function()
            local sources = {
                'buffer',
                'copilot',
                'emoji',
                'git',
                'lazydev',
                'lsp',
                'path',
                'snippets',
                'tmux',
            }

            -- Disable some sources in strings
            local ok, node = pcall(vim.treesitter.get_node)
            if ok and node then
                if node:type() ~= 'string' then
                    table.insert(sources, 'snippets')
                end
            end

            return sources
        end,
        per_filetype = {
            sql = { 'dbee', 'buffer', 'luasnip', 'tmux' },
        },
        providers = {
            copilot = {
                name = 'copilot',
                module = 'blink-copilot',
                score_offset = 100,
                async = true,
            },
            dbee = {
                name = 'cmp-dbee',
                module = 'blink.compat.source',
            },
            emoji = {
                module = 'blink-emoji',
                name = 'Emoji',
            },
            git = {
                name = 'Git',
                module = 'blink-cmp-git',
                enabled = function()
                    return vim.tbl_contains({ 'gitcommit' }, vim.bo.filetype)
                end,
            },
            lazydev = {
                name = 'LazyDev',
                module = 'lazydev.integrations.blink',
            },
            tmux = {
                name = 'tmux',
                module = 'blink-cmp-tmux',
            },
        },
    },
    snippets = { preset = 'luasnip' },
    cmdline = { enabled = true },
})

vim.lsp.config(
    '*',
    { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) }
)
