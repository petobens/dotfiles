-- Native package specification
local function plugin(source, data)
    data = type(data) == 'string' and { config = data } or data
    local version = data and data.version
    if data then
        data.version = nil
    end
    return {
        src = source:find('://', 1, true) and source or 'https://github.com/' .. source,
        version = version,
        data = data,
    }
end

-- Packages are flat and dependency-first because vim.pack does not resolve dependencies
local packages = {
    -- UI
    plugin('nvim-lualine/lualine.nvim', 'lualine_config'),

    -- Editing
    plugin('kylechui/nvim-surround', 'surround_config'),
    plugin('lukas-reineke/indent-blankline.nvim', 'indentlines_config'),
    plugin('https://codeberg.org/andyg/leap.nvim', 'leap_config'),
    plugin('andymass/vim-matchup', {
        event = 'BufReadPost',
        config = 'matchup_config',
    }),
    plugin('echasnovski/mini.align', 'mini_align_config'),

    -- Linting and formatting
    plugin('mfussenegger/nvim-lint', {
        config = { 'diagnostics_config', 'nvimlint_config' },
    }),
    plugin('stevearc/conform.nvim', 'conform_config'),

    -- LSP and Tree-sitter
    plugin('WhoIsSethDaniel/mason-tool-installer.nvim'),
    plugin('mason-org/mason.nvim', 'mason_config'),
    plugin('folke/lazydev.nvim'),
    plugin('neovim/nvim-lspconfig', 'lsp_config'),
    plugin('nvim-treesitter/nvim-treesitter-textobjects', { version = 'main' }),
    plugin('nvim-treesitter/nvim-treesitter', {
        version = 'main',
        build = ':TSUpdate',
        config = 'treesitter_config',
    }),
    plugin('m-demare/hlargs.nvim', 'hlargs_config'),

    -- Completion and snippets
    plugin('saghen/blink.lib'),
    plugin('saghen/blink.compat'),
    plugin('fang2hou/blink-copilot'),
    plugin('mgalliou/blink-cmp-tmux'),
    plugin('Kaiser-Yang/blink-cmp-git'),
    plugin('onsails/lspkind.nvim'),
    plugin('MunifTanjim/nui.nvim'),
    plugin('kndndrj/nvim-dbee', {
        build = function()
            require('dbee').install()
        end,
        event = 'FileType',
        keys = { '<Leader>db' },
        pattern = 'sql',
        config = 'dbee_config',
    }),
    plugin('MattiasMTS/cmp-dbee', {
        config = 'cmp_dbee_config',
        event = 'FileType',
        pattern = 'sql',
        version = 'ms/v2',
    }),
    plugin('Saghen/blink.cmp', {
        build = function()
            require('blink.cmp').build():pwait()
        end,
        config = 'blink_cmp_config',
    }),
    plugin('benfowler/telescope-luasnip.nvim'),
    plugin('L3MON4D3/LuaSnip', {
        event = 'InsertEnter',
        keys = { '<Leader>es', '<Leader>se' },
        config = 'luasnip_config',
    }),

    -- AI
    plugin('zbirenbaum/copilot.lua', {
        event = 'InsertEnter',
        config = 'copilot_config',
    }),
    plugin('nvim-lua/plenary.nvim'),
    plugin('ravitemer/codecompanion-history.nvim'),
    plugin('olimorris/codecompanion.nvim', 'codecompanion_config'),

    -- Fuzzy finding and file explorer
    plugin('3rd/image.nvim', 'image_config'),
    plugin('nvim-telescope/telescope-fzf-native.nvim', { build = 'make' }),
    plugin('debugloop/telescope-undo.nvim'),
    plugin('nvim-telescope/telescope-frecency.nvim'),
    plugin('nvim-telescope/telescope-z.nvim'),
    plugin('rafi/telescope-thesaurus.nvim'),
    plugin('nvim-telescope/telescope-ui-select.nvim'),
    plugin('nvim-telescope/telescope.nvim', 'telescope_config'),
    plugin('AckslD/nvim-neoclip.lua', 'neoclip_config'),
    plugin('nvim-tree/nvim-web-devicons'),
    plugin('nvim-tree/nvim-tree.lua', 'nvimtree_config'),
    plugin('stevearc/aerial.nvim', 'aerial_config'),

    -- Runners and terminal
    plugin('akinsho/toggleterm.nvim', 'toggleterm_config'),
    plugin('nathom/tmux.nvim', 'tmux_config'),
    plugin('stevearc/overseer.nvim', 'overseer_config'),
    plugin('nvim-neotest/neotest-python'),
    plugin('nvim-neotest/nvim-nio'),
    plugin('nvim-neotest/neotest', 'neotest_config'),
    plugin('michaelb/sniprun', {
        build = 'sh install.sh',
        config = 'sniprun_config',
    }),
    plugin('yorickpeterse/nvim-pqf', 'pqf_config'),

    -- Utilities
    plugin('jamessan/vim-gnupg'),
    plugin('HakonHarnes/img-clip.nvim', {
        keys = { '<Leader>pi' },
        config = 'img_clip_config',
    }),
    plugin('catgoose/nvim-colorizer.lua', {
        keys = { '<Leader>cz' },
        config = 'colorizer_config',
    }),
    plugin('lambdalisue/suda.vim', { cmd = { 'SudaWrite', 'SudaRead' } }),
    plugin('nyngwang/NeoZoom.lua', {
        keys = { '<Leader>zw' },
        config = 'neozoom_config',
    }),

    -- Git
    plugin('aymericbeaumet/vim-symlink'),
    plugin('shumphrey/fugitive-gitlab.vim'),
    plugin('tommcdo/vim-fubitive'),
    plugin('tpope/vim-rhubarb'),
    plugin('tpope/vim-fugitive', 'fugitive_config'),
    plugin('lewis6991/gitsigns.nvim', 'gitsigns_config'),

    -- LaTeX and Markdown
    plugin('lervag/vimtex', 'vimtex_config'),
    plugin('Thiago4532/mdmath.nvim', 'mdmath_config'),
    plugin('MeanderingProgrammer/render-markdown.nvim', 'render_markdown_config'),
}

-- Disable built-ins
for _, built_in in ipairs({
    'gzip',
    'matchit',
    'matchparen',
    'netrw',
    'netrwPlugin',
    'nvim_net_plugin',
    'nvim_zip_plugin',
    'tarPlugin',
    'tutor_mode_plugin',
}) do
    vim.g['loaded_' .. built_in] = 1
end

-- Actually install and configure packages
require('nvim-pack').setup(packages)

-- Mappings
vim.keymap.set('n', '<Leader>lz', vim.cmd.NvimPack, {
    desc = 'Open native package manager',
})
vim.keymap.set('n', '<Leader>bu', vim.cmd.NvimPackSync, {
    desc = 'Sync native packages',
})
vim.keymap.set('n', '<Leader>ul', function()
    vim.cmd.NvimPack('log')
end, { desc = 'Show native package update log' })
