-- Package specs store build, configuration, and deferred-loading metadata in
-- `vim.pack.Spec.data`. Deferred packages are configured after their first
-- event, command, or key trigger

---@class PackSpecData
---@field build? string|fun() Post-install/update function, `:Ex`, or shell command
---@field cmd? string|string[] User command(s) that defer loading
---@field config? string|string[] Module name(s) loaded from `plugin-config`
---@field event? string|string[] Autocommand event(s) that defer loading
---@field keys? string[] Normal-mode mappings that defer loading
---@field pattern? string|string[] Autocommand pattern(s) used with `event`
---@field version? string|vim.VersionRange Revision passed to `vim.pack`

---@param source string Git URI or `owner/repository`
---@param data? string|PackSpecData Config module shorthand or package metadata
---@return vim.pack.Spec
local function plugin(source, data)
    local metadata
    if type(data) == 'string' then
        metadata = { config = data }
    elseif data then
        metadata = vim.tbl_extend('force', {}, data)
    end
    local version = metadata and metadata.version
    if metadata then
        metadata.version = nil
    end
    return {
        src = source:find('://', 1, true) and source or 'https://github.com/' .. source,
        version = version,
        data = metadata,
    }
end

-- Packages are flat: dependencies precede consumers, and extensions follow
-- their main package
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
    plugin('mason-org/mason.nvim', 'mason_config'),
    plugin('WhoIsSethDaniel/mason-tool-installer.nvim'),
    plugin('folke/lazydev.nvim'),
    plugin('neovim/nvim-lspconfig', 'lsp_config'),
    plugin('nvim-treesitter/nvim-treesitter', {
        version = 'main',
        build = ':TSUpdate',
        config = 'treesitter_config',
    }),
    plugin('nvim-treesitter/nvim-treesitter-textobjects', { version = 'main' }),
    plugin('m-demare/hlargs.nvim', 'hlargs_config'),

    -- Completion and snippets
    plugin('saghen/blink.lib'),
    plugin('onsails/lspkind.nvim'),
    plugin('L3MON4D3/LuaSnip', {
        event = 'InsertEnter',
        keys = { '<Leader>es', '<Leader>se' },
        config = 'luasnip_config',
    }),
    plugin('Saghen/blink.cmp', {
        build = function()
            require('blink.cmp').build():pwait()
        end,
        config = 'blink_cmp_config',
    }),
    plugin('saghen/blink.compat'),
    plugin('fang2hou/blink-copilot'),
    plugin('mgalliou/blink-cmp-tmux'),
    plugin('Kaiser-Yang/blink-cmp-git'),

    -- AI
    plugin('zbirenbaum/copilot.lua', {
        event = 'InsertEnter',
        config = 'copilot_config',
    }),
    plugin('nvim-lua/plenary.nvim'),
    plugin('olimorris/codecompanion.nvim', 'codecompanion_config'),
    plugin('ravitemer/codecompanion-history.nvim'),

    -- Fuzzy finding and file explorer
    plugin('3rd/image.nvim', 'image_config'),
    plugin('nvim-telescope/telescope.nvim', 'telescope_config'),
    plugin('nvim-telescope/telescope-fzf-native.nvim', { build = 'make' }),
    plugin('benfowler/telescope-luasnip.nvim'),
    plugin('debugloop/telescope-undo.nvim'),
    plugin('nvim-telescope/telescope-frecency.nvim'),
    plugin('nvim-telescope/telescope-z.nvim'),
    plugin('rafi/telescope-thesaurus.nvim'),
    plugin('nvim-telescope/telescope-ui-select.nvim'),
    plugin('AckslD/nvim-neoclip.lua', 'neoclip_config'),
    plugin('nvim-tree/nvim-web-devicons'),
    plugin('nvim-tree/nvim-tree.lua', 'nvimtree_config'),
    plugin('stevearc/aerial.nvim', 'aerial_config'),

    -- Runners and terminal
    plugin('akinsho/toggleterm.nvim', 'toggleterm_config'),
    plugin('nathom/tmux.nvim', 'tmux_config'),
    plugin('stevearc/overseer.nvim', 'overseer_config'),
    plugin('nvim-neotest/nvim-nio'),
    plugin('nvim-neotest/neotest', 'neotest_config'),
    plugin('nvim-neotest/neotest-python'),
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
    plugin('tpope/vim-fugitive', 'fugitive_config'),
    plugin('shumphrey/fugitive-gitlab.vim'),
    plugin('tommcdo/vim-fubitive'),
    plugin('tpope/vim-rhubarb'),
    plugin('lewis6991/gitsigns.nvim', 'gitsigns_config'),

    -- LaTeX and Markdown
    plugin('lervag/vimtex', 'vimtex_config'),
    plugin('Thiago4532/mdmath.nvim', 'mdmath_config'),
    plugin('MeanderingProgrammer/render-markdown.nvim', 'render_markdown_config'),

    -- SQL
    plugin('tpope/vim-dadbod', 'dadbod_config'),
    plugin('kristijanhusak/vim-dadbod-ui', {
        cmd = { 'DBUIToggle', 'DBUIFindBuffer' },
    }),
    plugin('kristijanhusak/vim-dadbod-completion', {
        event = 'FileType',
        pattern = 'sql',
    }),
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

-- Install and configure packages
local pack = require('pack')
pack.setup(packages)

-- Mappings
vim.keymap.set('n', '<Leader>lz', pack.open, {
    desc = 'Open package manager',
})
vim.keymap.set('n', '<Leader>bu', pack.sync, {
    desc = 'Sync packages',
})
vim.keymap.set('n', '<Leader>ul', pack.log, {
    desc = 'Show package update log',
})
